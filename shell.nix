{ pkgs ? (import <nixpkgs> { 
    config.allowUnfree = true;
}), ... }:
pkgs.mkShell {
  buildInputs = [
    pkgs.kubernetes-helm
    pkgs.vault-bin
    pkgs.kustomize
    pkgs.terraform
  ];
}

