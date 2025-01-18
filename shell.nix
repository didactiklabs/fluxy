{
  pkgs ? (
    import <nixpkgs> {
      config.allowUnfree = true;
    }
  ),
  ...
}:
pkgs.mkShell {
  buildInputs = [
    pkgs.kustomize
  ];
  packages = [
    (pkgs.writeShellScriptBin "buildKubeProm" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/monitoring/upstream
      mkdir -p gitops/apps/monitoring/upstream
      cp -r --no-preserve=mode $(nix-build nix/kube-prometheus.nix)/* gitops/apps/monitoring/upstream/
    '')
    (pkgs.writeShellScriptBin "buildKubevirt" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/kubevirt/upstream
      mkdir -p gitops/apps/kubevirt/upstream
      kubevirtoperatorhash=$(nix-prefetch-url https://github.com/kubevirt/kubevirt/releases/download/$1/kubevirt-operator.yaml)
      kubevirtcrhash=$(nix-prefetch-url https://github.com/kubevirt/kubevirt/releases/download/$1/kubevirt-cr.yaml)
      cp -r --no-preserve=mode $(nix-build nix/kubevirt.nix --argstr kubevirtOperatorHash "$kubevirtoperatorhash" --argstr kubevirtCrHash "$kubevirtcrhash" --argstr version $1)/* gitops/apps/kubevirt/upstream/
    '')
    (pkgs.writeShellScriptBin "buildCdi" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/cdi/upstream
      mkdir -p gitops/apps/cdi/upstream
      kubevirtcdioperatorhash=$(nix-prefetch-url https://github.com/kubevirt/containerized-data-importer/releases/download/$1/cdi-operator.yaml)
      kubevirtcdicrhash=$(nix-prefetch-url https://github.com/kubevirt/containerized-data-importer/releases/download/$1/cdi-cr.yaml)
      cp -r --no-preserve=mode $(nix-build nix/kubevirt-cdi.nix --argstr kubevirtCdiOperatorHash "$kubevirtcdioperatorhash" --argstr kubevirtCdiCrHash "$kubevirtcdicrhash" --argstr version $1)/* gitops/apps/cdi/upstream/
    '')
    (pkgs.writeShellScriptBin "buildCertManager" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/cert-manager/upstream
      mkdir -p gitops/apps/cert-manager/upstream
      certmanagerhash=$(nix-prefetch-url https://github.com/cert-manager/cert-manager/releases/download/$1/cert-manager.yaml)
      cp -r --no-preserve=mode $(nix-build nix/cert-manager.nix --argstr certManagerHash "$certmanagerhash" --argstr version $1)/* gitops/apps/cert-manager/upstream/
    '')
    (pkgs.writeShellScriptBin "buildCapi" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/cluster-api/upstream
      mkdir -p gitops/apps/cluster-api/upstream
      capihash=$(nix-prefetch-url https://github.com/kubernetes-sigs/cluster-api-operator/releases/download/$1/operator-components.yaml)
      cp -r --no-preserve=mode $(nix-build nix/capi.nix --argstr manifest01Hash "$capihash" --argstr version $1)/* gitops/apps/cluster-api/upstream/
    '')
    (pkgs.writeShellScriptBin "buildCnpg" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/cnpg/upstream
      mkdir -p gitops/apps/cnpg/upstream
      strippedVersion=$(echo "$1" | sed 's/^v//')
      cnpghash=$(nix-prefetch-url https://github.com/cloudnative-pg/cloudnative-pg/releases/download/$1/cnpg-$strippedVersion.yaml)
      cp -r --no-preserve=mode $(nix-build nix/cnpg.nix --argstr manifest01Hash "$cnpghash" --argstr version $1)/* gitops/apps/cnpg/upstream/
    '')
    (pkgs.writeShellScriptBin "buildIngressContour" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/ingress-controller/upstream
      mkdir -p gitops/apps/ingress-controller/upstream
      cp -r --no-preserve=mode $(nix-build nix/ingress-contour.nix)/* gitops/apps/ingress-controller/upstream/
    '')
    (pkgs.writeShellScriptBin "buildGatewayApi" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/istio-gateway-api/upstream
      mkdir -p gitops/apps/istio-gateway-api/upstream
      hash=$(nix-prefetch-url https://github.com/kubernetes-sigs/gateway-api/releases/download/$1/experimental-install.yaml)
      cp -r --no-preserve=mode $(nix-build nix/gatewayapi.nix --argstr manifest01Hash "$hash" --argstr version $1)/* gitops/apps/istio-gateway-api/upstream/
    '')
    (pkgs.writeShellScriptBin "buildKamaji" ''
      #!/bin/bash
      set -e
      rm -rf gitops/apps/kamaji/upstream
      mkdir -p gitops/apps/kamaji/upstream
      cp -r --no-preserve=mode $(nix-build nix/kamaji.nix)/* gitops/apps/kamaji/upstream/
    '')
  ];
}
