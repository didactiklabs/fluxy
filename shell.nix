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
    pkgs.kubernetes-helm
    pkgs.vault-bin
    pkgs.kustomize
    pkgs.terraform
    pkgs.velero
    pkgs.vault-medusa
  ];
  packages = [
    (pkgs.writeShellScriptBin "buildKubeProm" ''
      #!/bin/bash
      rm -rf gitops/apps/monitoring/upstream
      mkdir -p gitops/apps/monitoring/upstream
      cp -r $(nix-build nix/kube-prometheus.nix)/* gitops/apps/monitoring/upstream
    '')
  ];
}
