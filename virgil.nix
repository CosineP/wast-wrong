{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "virgil";
  src = pkgs.fetchFromGitHub {
    owner = "titzer";
    repo = "virgil";
    rev = "b00b6660a695e8c75660798e9d6d28b99a57bb55";
    sha256 = "sha256-2iPDbFIeKUK6jaZU+4pJm/r/KdVNQlnK1aO+6xk1zGM=";
  };
  propagatedBuildInputs = with pkgs; [
    jre
  ];
  nativeBuildInputs = with pkgs; [
    which
  ];
  patchPhase = ''
    patchShebangs bin
  '';
  buildPhase = ''
    bin/dev/aeneas clean
    bin/dev/aeneas bootstrap
    bin/v3c -version
    # bin/.setup-v3c # need this now?
  '';
  installPhase = ''
    mkdir $out
    cp -r bin $out/
    cp -r lib $out/
    cp -r rt $out/
  '';
  fixupPhase = ''
    rm $out/bin/v3c
    ln -s $out/bin/current/x86-linux/Aeneas $out/bin/v3c
  '';
}

