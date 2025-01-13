{
  pkgs ? import <nixpkgs> { },
  version ? "",
  manifest01Hash ? "",
}:
let
  # inherit (pkgs) lib;
  manifest01 = pkgs.fetchurl {
    url = "https://github.com/kubernetes-sigs/cluster-api-operator/releases/download/${version}/operator-components.yaml";
    sha256 = "${manifest01Hash}";
  };
in
pkgs.runCommand "capi"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${manifest01} ./operator-components.yaml
    kustomize edit add resource *.yaml
    cp ${manifest01} $out/operator-components.yaml
    cp kustomization.yaml $out/
  ''
