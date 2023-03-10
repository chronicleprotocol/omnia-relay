{ stdenv, lib, makeWrapper, shellcheck, glibcLocales, coreutils, gettext, jq, omnia, ssb-server, oracle-suite, tor }:
stdenv.mkDerivation rec {
  name = "install-relay-${version}";
  version = lib.fileContents ../version;
  src = ./.;

  passthru.runtimeDeps = [ coreutils gettext jq ];
  nativeBuildInputs = [ makeWrapper shellcheck ];

  buildPhase = "true";
  installPhase = let
    path = lib.makeBinPath passthru.runtimeDeps;
    locales = lib.optionalString (glibcLocales != null) ''--set LOCALE_ARCHIVE "${glibcLocales}"/lib/locale/locale-archive'';
  in ''
    mkdir -p $out/{bin,share}
    cp -t $out/bin install-relay
    cp -t $out/share *.service *.json *.ini ${omnia}/config/*.json

    wrapProgram "$out/bin/install-relay" \
      --prefix PATH : "${path}" \
      --set SHARE_PATH "$out/share" \
      --set OMNIA_PATH "${omnia}/bin/omnia" \
      --set SPIRE_PATH "${oracle-suite}/bin/spire" \
      --set SPLITTER_PATH "${oracle-suite}/bin/rpc-splitter" \
      --set SSB_PATH "${ssb-server}/bin/ssb-server" \
      --set TORPROXY_PATH "${tor}/bin/tor" \
      ${locales}
  '';

  doCheck = true;
  checkPhase = ''
    shellcheck -x install-relay
  '';

  meta = {
    description = "Installer script for Omnia Relay service";
    homepage = "https://github.com/makerdao/oracles-v2";
    license = lib.licenses.gpl3;
    inherit version;
  };
}
