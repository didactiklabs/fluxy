{
  pkgs ? import <nixpkgs> { },
  version ? "",
  certManagerHash ? "",
}:
let
  # inherit (pkgs) lib;
  certManager = pkgs.fetchurl {
    url = "https://github.com/cert-manager/cert-manager/releases/download/${version}/cert-manager.yaml";
    sha256 = "${certManagerHash}";
  };
in
pkgs.runCommand "cert-manager"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${certManager} cert-manager.yaml
    kustomize edit add resource *.yaml
    cp ${certManager} $out/cert-manager.yaml
    cp kustomization.yaml $out/
  ''
