{
  pkgs ? import <nixpkgs> { },
}:
let
  # inherit (pkgs) lib;
  sources = import ../npins;
  manifest01 = sources.ingress-nginx;
in
pkgs.runCommand "ingress-nginx"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${manifest01}/deploy/static/provider/baremetal/deploy.yaml ./deploy.yaml
    kustomize edit add resource *.yaml
    cp ${manifest01}/deploy/static/provider/baremetal/deploy.yaml $out/deploy.yaml
    cp kustomization.yaml $out/
  ''
