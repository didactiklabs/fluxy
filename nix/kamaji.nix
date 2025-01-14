{
  pkgs ? import <nixpkgs> { },
}:
let
  # inherit (pkgs) lib;
  sources = import ../npins;
  manifest01 = sources.kamaji;
in
pkgs.runCommand "kamaji"
  {
    nativeBuildInputs = [
      pkgs.kustomize
    ];
  }
  ''
    set -e
    mkdir -p $out/
    kustomize init
    cp ${manifest01}/charts/kamaji/crds/kamaji.clastix.io_datastores.yaml ./
    cp ${manifest01}/charts/kamaji/crds/kamaji.clastix.io_tenantcontrolplanes.yaml ./
    kustomize edit add resource *.yaml
    cp ${manifest01}/charts/kamaji/crds/kamaji.clastix.io_datastores.yaml $out/
    cp ${manifest01}/charts/kamaji/crds/kamaji.clastix.io_tenantcontrolplanes.yaml $out/
    cp kustomization.yaml $out/
  ''
