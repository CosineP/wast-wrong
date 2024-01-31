{ pkgs ? import <nixpkgs> {} }:

(pkgs.buildFHSUserEnv {
  name = "wizard-fhs";
  targetPkgs = pkgs: [ pkgs.coreutils ];
}).env

