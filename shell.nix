{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell rec {
  packages = with pkgs; [
    (ocamlPackages.wasm.overrideAttrs (oldAttrs: {
      version = "function-references";
      src = fetchFromGitHub {
        owner = "WebAssembly";
        repo = "function-references";
        rev = "3b0c813201b47414ce4326e2364265064e421a30";
        sha256 = "sha256-FR/gmcbWvu0Uw52+v7D4RiKHJkj5T3llrBkOVH/5nu4=";
      };
    }))
    (ocamlPackages.wasm.overrideAttrs (oldAttrs: {
      version = "threads";
      src = fetchFromGitHub {
        owner = "WebAssembly";
        repo = "threads";
        rev = "cc01bf0d17ba3fb1dc59fb7c5c725838aff18b50";
        sha256 = "sha256-rLFT/vyzSZZIBg2QMHH00Nxsk0Nivlah+N+x6BeFI4s=";
      };
      postPatch = ''
        cp interpreter/exec/numeric_error.ml interpreter/exec/numeric_error.mli
        sed -i 's/a-4-27-42-44-45/a-4-27-42-44-45-70/g' interpreter/Makefile
      '';
      postInstall = ''
        mkdir $out/bin
        cp -L interpreter/wasm $out/bin/wasm-threads
      '';
    }))
    (import ./wizard.nix {})
    jre
    wabt
    nodejs
    spidermonkey_102
  ];
}

