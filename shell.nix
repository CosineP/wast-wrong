{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell rec {
  packages = with pkgs; [
    wasmtime
    ocamlPackages.wasm
    (import ./wizard.nix {})
    jre
    wabt
    nodejs
  ];
}

