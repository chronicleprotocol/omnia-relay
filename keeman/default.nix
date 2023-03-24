{ pkgs }: with pkgs;
stdenv.mkDerivation rec {
  pname = "keeman";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    autoPatchelfHook
  ];
  installPhase = ''
    set -e
    mkdir -p $out/bin
    cp $src/keeman $out/bin/
    chmod +x $out/bin/*
    find $out/bin -type f | while read -r x; do
      wrapProgram "$x"
    done
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/keeman --version
  '';
}
