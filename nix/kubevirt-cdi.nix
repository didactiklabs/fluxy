{
  pkgs ? import <nixpkgs> { },
  kubevirtCdiOperatorHash ? "",
  kubevirtCdiCrHash ? "",
  version ? "",
}:
let
  # inherit (pkgs) lib;
  kubevirtCdiOperator = pkgs.fetchurl {
    url = "https://github.com/kubevirt/containerized-data-importer/releases/download/${version}/cdi-operator.yaml";
    sha256 = "${kubevirtCdiOperatorHash}";
  };
  kubevirtCdiCr = pkgs.fetchurl {
    url = "https://github.com/kubevirt/containerized-data-importer/releases/download/${version}/cdi-cr.yaml";
    sha256 = "${kubevirtCdiCrHash}";
  };
in
# Generate the new GrafanaDashboard YAML for each ConfigMap
pkgs.runCommand "cdi"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${kubevirtCdiOperator} cdi-operator.yaml
    cp ${kubevirtCdiCr} cdi-cr.yaml
    kustomize edit add resource *.yaml
    cp ${kubevirtCdiOperator} $out/cdi-operator.yaml
    cp ${kubevirtCdiCr} $out/cdi-cr.yaml
    cp kustomization.yaml $out/
  ''
