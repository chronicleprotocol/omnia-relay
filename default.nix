let
  srcs = import ./nix/srcs.nix;
in

{ pkgs ? srcs.pkgs
, gofer ? srcs.gofer
}: with pkgs;

let
  ssb-server = lib.setPrio 8 srcs.ssb-server;
in {
  inherit ssb-server;
  inherit (srcs) omnia install-omnia stark-cli;
}
