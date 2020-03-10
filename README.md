# Porting [Arcan](https://arcan-fe.com/about/) to NixOS

This is Arcan, ported for NixOS.
Project structure is based on [this Reddit post by /u/tomberek](https://old.reddit.com/r/NixOS/comments/8tkllx/standard_project_structure/).
To build:

```
git submodule init
nix-build
# ...wait for 16M nixpkgs tarball to download from GitHub...
./start-prio
```

- **TODO**: Submit to nixpkgs
- **TODO**: Build manpages
- **TODO**: Add launcher scripts to build
- **TODO**: Fix missing include for vrbridge
- **TODO**: Add package.nix and PR to nixpkgs
- **TODO**: Add option.nix and PR to NixOS
- **TODO**: Add release.nix and spec.nix
