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
  ];
}
