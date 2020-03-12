(import <nixpkgs> {
  config = {};
  overlays = [ (import ./overlay.nix) ];
}).arcan
