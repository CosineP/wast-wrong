{ pkgs ? import <nixpkgs> {} }:

# linux ones segfault on me, so i'm requiring java and using that one
pkgs.stdenv.mkDerivation {
  name = "wizard";
  src = pkgs.fetchFromGitHub {
    owner = "titzer";
    repo = "wizard-engine";
    rev = "51642d0a14f558a2ea6947b0510874e855c45d86";
    sha256 = "sha256-R2J26Bc8u/T84mTVtn6ASTkumc2Lw1X8IEWcXOADczA=";
  };
  patchPhase = ''
    patchShebangs build.sh
  '';
  buildInputs = [ (import ./virgil.nix {}) pkgs.which ];
  propagatedBuildInputs = [ pkgs.jre ];
  installPhase = ''
    mkdir -p $out/bin
    cp -r bin $out/
    ln -s $out/bin/wizeng.jvm $out/bin/wizeng
  '';
}
