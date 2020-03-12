# Porting [Arcan](https://arcan-fe.com/about/) to NixOS

This is Arcan, ported for NixOS.

## Project structure

Based on [this Reddit post by /u/tomberek](https://old.reddit.com/r/NixOS/comments/8tkllx/standard_project_structure/).

## Quick start

To run `prio`:

```
git submodule init
nix-build -A prio
./result/prio
```

Replace with `durden`, `safespaces`, or `awb` accordingly.

## Making my own Arcan appl

To be continued

## Roadmap

- [x] Properly configure vendored `libuvc`
- [ ] Enable building of manpages (requires ruby)
- [ ] Make components such as VR, OCR, etc. optional
- [x] Add launcher scripts to build
- [ ] Fix missing include breaking `vrbridge` build
- [ ] Add release.nix and spec.nix (for local Hydra? research this)
- [ ] Submit to `nixpkgs`
- [ ] Make sure any mutable files are located in `/var` (`safespaces/ipc/control`!)
