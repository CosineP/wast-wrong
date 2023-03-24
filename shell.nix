{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell rec {
  packages = with pkgs; [
    wasmtime
    (ocamlPackages.wasm.overrideAttrs (oldAttrs: {
      version = "function-references";
      src = fetchFromGitHub {
        owner = "WebAssembly";
        repo = "function-references";
        rev = "3b0c813201b47414ce4326e2364265064e421a30";
        sha256 = "sha256-FR/gmcbWvu0Uw52+v7D4RiKHJkj5T3llrBkOVH/5nu4=";
      };
    }))
    (import ./wizard.nix {})
    jre
    wabt
    nodejs
    spidermonkey_102
  ];
}

