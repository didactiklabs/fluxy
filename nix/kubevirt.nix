{
  pkgs ? import <nixpkgs> { },
  version ? "",
  kubevirtOperatorHash ? "",
  kubevirtCrHash ? "",
}:
let
  # inherit (pkgs) lib;
  kubevirtOperator = pkgs.fetchurl {
    url = "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-operator.yaml";
    sha256 = "${kubevirtOperatorHash}";
  };
  kubevirtCr = pkgs.fetchurl {
    url = "https://github.com/kubevirt/kubevirt/releases/download/${version}/kubevirt-cr.yaml";
    sha256 = "${kubevirtCrHash}";
  };
in
# Generate the new GrafanaDashboard YAML for each ConfigMap
pkgs.runCommand "kubevirt"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${kubevirtOperator} kubevirt-operator.yaml
    cp ${kubevirtCr} kubevirt-cr.yaml
    kustomize edit add resource *.yaml
    cp ${kubevirtOperator} $out/kubevirt-operator.yaml
    cp ${kubevirtCr} $out/kubevirt-cr.yaml
    cp kustomization.yaml $out/
  ''
