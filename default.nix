(import (import ./nixpkgs.nix) {
  config = {};
  overlays = [ (import ./overlay.nix) ];
}).arcan
