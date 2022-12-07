let srcs = import ../nix/default.nix;

in { pkgs ? srcs.pkgs, makerpkgs ? srcs.makerpkgs, nodepkgs ? srcs.nodepkgs }@args:

let
  oracles = import ./.. args;
  median = import ./lib/median args;
  dapptools = import srcs.dapptools;
  seth = dapptools.seth;
in pkgs.mkShell rec {
  name = "oracle-test-shell";
  buildInputs = with pkgs;
    [
      procps
      curl
      jq
      mitmproxy
      go-ethereum
      makerpkgs.dappPkgsVersions.latest.dapp
      nodepkgs.tap-xunit
      median
      oracles.omnia
      oracles.install-relay
    ] ++ oracles.omnia.buildInputs;

  RESULTS_DIR = "${toString ./.}/test-results";
  SMOKE_TEST = toString ./smoke/test;

  shellHook = ''
    _xunit() {
      local name="$1"
      local tap="$2"
      mkdir -p "$RESULTS_DIR/$name"
      tap-xunit < "$tap" \
        > "$RESULTS_DIR/$name/results.xml"
      cp "$tap" "$RESULTS_DIR/$name/"
    }

    xunit() {
      local name="$1"
      local tests=("''${@:2}")
      if [[ $tests ]]; then
        for test in "''${tests[@]}"; do
          _xunit "$name-''${test%.*}" "$test"
        done
      else
        local output="$(mktemp tap-XXXXXXXX).tap"
        tee "$output"
        _xunit "$name" "$output"
      fi
    }

    _runTest() {
      local ecode=0
      "''${@:2}"
      ecode=$?
      xunit "$1" logs/*.tap || true
      return $ecode
    }

    testSmoke() { _runTest smoke sh -c 'mkdir -p logs && "$1" | tee logs/smoke.tap' _ "$SMOKE_TEST"; }
  '';
}
