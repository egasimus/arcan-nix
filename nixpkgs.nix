let
  rev = "19.09";
in builtins.fetchTarball {
  url    = "https://github.com/NixOS/nixpkgs-channels/archive/nixos-${rev}.tar.gz";
  sha256 = "1cm32fffgy98dplb6mjbbfayblhfnzl713hk26wdbfa3fkzsk0jx";
}
