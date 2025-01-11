{
  pkgs ? import <nixpkgs> { },
}:
let
  inherit (pkgs) lib;
  sources = import ../npins;
  kubePrometheusSrc = sources.kube-prometheus;
  kubevirtMonitoringSrc = sources.kubevirt-monitoring;
  inherit (sources) grafana-operator;
  prometheusSvcName = builtins.readFile (
    pkgs.runCommand "get-prometheus-service-name" { } ''
      ${pkgs.yq-go}/bin/yq eval '.metadata.name' ${kubePrometheusSrc}/manifests/prometheus-service.yaml | tr -d '\n' > $out
    ''
  );
  prometheusNamespace = builtins.readFile (
    pkgs.runCommand "get-prometheus-service-name" { } ''
      ${pkgs.yq-go}/bin/yq eval '.metadata.namespace' ${kubePrometheusSrc}/manifests/prometheus-service.yaml | tr -d '\n' > $out
    ''
  );
  generateGrafana = ''
    apiVersion: grafana.integreatly.org/v1beta1
    kind: Grafana
    metadata:
      name: grafana
      labels:
        dashboards: 'grafana'
    spec:
      config:
        log:
          mode: 'console'
        auth:
          disable_login_form: 'false'
  '';
  generateServiceMonitorPatch = ''
    - op: replace
      path: /spec/selector/matchLabels
      value: {"app": "grafana"}
  '';
  generateGrafanaNetpolPatch = ''
    - op: replace
      path: /spec/podSelector/matchLabels
      value: {"app": "grafana"}
    - op: add
      path: /spec/ingress/-
      value:
        from:
          - podSelector:
              matchLabels:
                app.kubernetes.io/name: grafana-operator
        ports:
          - protocol: TCP
            port: 3000
    - op: add
      path: /spec/ingress/-
      value:
        from:
          - podSelector:
              matchLabels:
                app: grafana
        ports:
          - protocol: TCP
            port: 9090
  '';
  generateGrafanaPromNetpolPatch = ''
    - op: add
      path: /spec/ingress/-
      value:
        from:
          - podSelector:
              matchLabels:
                app: grafana
        ports:
          - protocol: TCP
            port: 9090
    - op: add
      path: /spec/ingress/-
      value:
        from:
          - podSelector:
              matchLabels:
                app.kubernetes.io/name: grafana-operator
        ports:
          - protocol: TCP
            port: 9090
  '';
  generatePrometheusDatasource = ''
    apiVersion: grafana.integreatly.org/v1beta1
    kind: GrafanaDatasource
    metadata:
      name: kube-prometheus
    spec:
      instanceSelector:
        matchLabels:
          dashboards: 'grafana'
      resyncPeriod: 1m
      datasource:
        name: prometheus
        type: prometheus
        access: proxy
        url: 'http://${prometheusSvcName}.${prometheusNamespace}.svc:9090'
        isDefault: true
        jsonData:
          'tlsSkipVerify': true
          'timeInterval': '5s'
  '';
  # The function to generate the GrafanaDashboard YAML from the configMap name
  generateGrafanaDashboard = configMapName: ''
    apiVersion: grafana.integreatly.org/v1beta1
    kind: GrafanaDashboard
    metadata:
      name: grafanadashboard-from-configmap-${configMapName}
    spec:
      folder: "Kube-Prometheus"
      instanceSelector:
        matchLabels:
          dashboards: "grafana"
      resyncPeriod: 1m
      configMapRef:
        name: ${configMapName}
        key: ${lib.strings.replaceStrings [ "grafana-dashboard-" ] [ "" ] configMapName}.json
    ---
  '';
  # Use yq to extract ConfigMap names from the input YAML
  parsedConfigMapNames =
    configMap:
    builtins.fromJSON (
      builtins.readFile (
        pkgs.runCommand "parse-yaml"
          {
            nativeBuildInputs = [
              pkgs.yq-go
              pkgs.jq
            ];
          }
          ''
            yq eval -o=json '.items[].metadata.name' ${configMap} | jq -s . > $out
          ''
      )
    );
  # Generate a list of GrafanaDashboard YAMLs by mapping over the ConfigMap names
  kubePromDashboards = lib.concatMapStringsSep "\n" (configMapName: ''
    ${generateGrafanaDashboard configMapName}
  '') (parsedConfigMapNames "${kubePrometheusSrc}/manifests/grafana-dashboardDefinitions.yaml");
  kubevirtDashboard = generateGrafanaDashboard "grafana-dashboard-kubevirt-control-plane";
in
# Generate the new GrafanaDashboard YAML for each ConfigMap
pkgs.runCommand "kustomize-kube-prometheus"
  {
    nativeBuildInputs = [
      pkgs.kustomize
      pkgs.kubectl
      pkgs.yq-go
      pkgs.nix
    ];
    src = kubePrometheusSrc;
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init

    ### KUBEVIRT DASHBOARD ###
    mkdir -p custom-dashboards
    JSON_DIR=${kubevirtMonitoringSrc}/dashboards/grafana
    for json_file in "$JSON_DIR"/*.json; do
      # Extract the filename without the extension to use as the ConfigMap name
      configmap_name=$(basename "$json_file" .json)
      # Create the ConfigMap using kubectl
      kubectl -n monitoring create configmap "grafana-dashboard-$configmap_name" --from-file=$configmap_name.json=$json_file --dry-run=client -o yaml > custom-dashboards/grafana-cm-dashboards-$configmap_name.yaml
    done
    echo "${kubevirtDashboard}" > custom-dashboards/kubevirt-dashboard.yaml
    cd custom-dashboards
    kustomize init
    kustomize edit add resource *.yaml
    cd ../
    kustomize edit add resource custom-dashboards
    cp -r custom-dashboards $out/

    ### GRAFANA OPERATOR
    mkdir -p grafana-operator
    cp -r ${grafana-operator}/deploy/kustomize/* ./grafana-operator/
    chmod -R +w grafana-operator
    kustomize edit add resource grafana-operator/overlays/cluster_scoped
    yq -i '.namespace = "monitoring"' grafana-operator/overlays/cluster_scoped/kustomization.yaml
    cp -r ./grafana-operator/ $out/

    ### KUBE-PROMETHEUS
    mkdir -p kube-prometheus/
    mkdir -p kube-prometheus/crds/
    cp $src/manifests/setup/*.yaml kube-prometheus/crds/
    shopt -s extglob
    cp $src/manifests/!(grafana-config|grafana-dashboardDatasources|grafana-dashboardSources|grafana-deployment|grafana-service|grafana-serviceAccount).yaml ./kube-prometheus
    cd kube-prometheus
    kustomize init
    kustomize edit add resource *.yaml
    cd ../
    kustomize edit add resource kube-prometheus
    cp -r kube-prometheus $out/

    ### ADD KUBE-PROMETHEUS DASHBOARD TO GRAFANA OPERATOR
    echo "${kubePromDashboards}" > kubeprom-dashboards.yaml
    kustomize edit add resource kubeprom-dashboards.yaml
    cp kubeprom-dashboards.yaml $out/

    ### ADD KUBE-PROMETHEUS AS DATASOURCE FOR GRAFANA OPERATOR
    echo "${generatePrometheusDatasource}" > kubeprom-datasource.yaml
    kustomize edit add resource kubeprom-datasource.yaml
    cp kubeprom-datasource.yaml $out/

    ### ADD GRAFANA instance
    echo "${generateGrafana}" > kubeprom-grafana.yaml
    kustomize edit add resource kubeprom-grafana.yaml
    cp kubeprom-grafana.yaml $out/

    ### GRAFANA NETPOL PATCH
    echo "${generateGrafanaNetpolPatch}" > kubeprom-grafana-netpol-patch.yaml
    echo "${generateGrafanaPromNetpolPatch}" > kubeprom-grafana-prom-netpol-patch.yaml
    echo "${generateServiceMonitorPatch}" > kubeprom-service-monitor-patch.yaml
    cp kubeprom-grafana-netpol-patch.yaml $out/
    cp kubeprom-grafana-prom-netpol-patch.yaml $out/
    cp kubeprom-service-monitor-patch.yaml $out/
    cat <<EOF >> kustomization.yaml
    patches:
      - path: kubeprom-grafana-netpol-patch.yaml
        target:
          kind: NetworkPolicy
          name: grafana
      - path: kubeprom-grafana-prom-netpol-patch.yaml
        target:
          kind: NetworkPolicy
          name: prometheus-k8s
      - path: kubeprom-service-monitor-patch.yaml
        target:
          kind: ServiceMonitor
          name: grafana
    EOF

    ###
    cp kustomization.yaml $out/
  ''
