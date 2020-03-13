{ lib, newScope, stdenv, pkgs }: let

  # nicer aliases
  derive = stdenv.mkDerivation;
  concat = builtins.concatStringsSep " ";

  # vendored libuvc: don't build, just make sources available
  libuvc-src = derive {
    name = "libuvc-src";
    # using fetchgit instead fetchFromGitHub because
    # the .git directory is needed by arcan's cmake scripts
    src = pkgs.fetchgit {
      leaveDotGit = true;
      url = "https://github.com/letoram/libuvc.git";
      rev = "v0.0.6";
      sha256 = "1jdmiinsd91nnli5hgcn9c6ifj0s6ngbyjwm0z6fim4f8krnh0sf";
    };
    nativeBuildInputs = with pkgs; [ git ];
    # fetchgit strips all refs, leaving just a fetchgit branch
    # but cmake needs to check out the ref called 'master':
    installPhase = ''
      git tag master
      cp -r . $out/
      cd $out
    '';
  };

  # cmake flags pointing to locations of arcan headers
  arcanIncludeDirs = arcan: [
    "-DARCAN_SHMIF_INCLUDE_DIR=${arcan}/include/arcan/shmif"
    "-DARCAN_TUI_INCLUDE_DIR=${arcan}/include/arcan"
  ];

  # cmake flags pointing to locations of libusb1 headers and binaries
  libusbDirs = libusb1: [
    "-DLIBUSB_1_INCLUDE_DIRS=${libusb1.dev}/include/libusb-1.0"
    "-DLIBUSB_1_LIBRARIES=${libusb1}/lib/libusb-1.0.so"
  ];

in lib.makeScope newScope (self: with self; let

  arcanAppl = name: src: root: callPackage ({ pkgs }: derive {
    name = name;
    src = src;
    nativeBuildInputs = with pkgs; [ envsubst ];
    buildInputs = [ arcan ];
    installPhase = ''
      mkdir -p $out/${name} $out/bin
      cp -rT ${root} $out/${name}
      Arcan=${arcan} Appls=$out Appl=${name} envsubst \
        < ${./scripts/arcan_wrapper} \
        > $out/bin/arcan.${name}
      chmod +x $out/bin/arcan.${name}
    '';
  }) {};

in {

  # arcan core:

  arcan = callPackage ({ pkgs }: derive {
    name = "arcan";
    src = ./arcan;
    patches = [ ./nosuid.patch ]; # nix refuses to build suid binaries
    postUnpack = '' # add vendored libuvc
      mkdir -p ./arcan/external/git/libuvc
      pushd ./arcan/external/git/
      shopt -s dotglob nullglob  # bashism: * now also matches dotfiles
      cp -r ${libuvc-src}/* libuvc/
      shopt -u dotglob nullglob  # phases are stateful
      popd
    '';
    nativeBuildInputs = with pkgs; [ cmake gcc git ];
    buildInputs = with pkgs; [
      apr
      espeak-classic
      file
      ffmpeg-full
      freetype
      harfbuzzFull
      leptonica
      libGL
      libdrm
      libjpeg
      libusb1
      libvncserver
      libxkbcommon
      luajit
      lzma
      mesa
      openal
      SDL2
      sqlite
      tesseract
      vlc
      wayland
      wayland-protocols
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilwm
    ];
    PKG_CONFIG_PATH = concat [ # make wayland protocols available
      "${pkgs.wayland-protocols}/share/pkgconfig"
      "${pkgs.libusb1.dev}/lib/pkgconfig"
    ];
    CFLAGS = concat [ # don't warn on read()/write() without a format
      "-Wno-format"   # (Arcan code uses them on SHMIFs)
      "-Wno-format-security"
    ];
    cmakeFlags = concat (
      # cmake won't be able to find these paths on its own:
      (libusbDirs pkgs.libusb) ++ [
      "-DDRM_INCLUDE_DIR=${pkgs.libdrm.dev}/include/libdrm"
      "-DGBM_INCLUDE_DIR=${pkgs.libGL.dev}/include"
      "-DWAYLANDPROTOCOLS_PATH=${pkgs.wayland-protocols}/share/wayland-protocols"
      # enable features:
      "-DVIDEO_PLATFORM=egl-dri"
      "-DSHMIF_TUI_ACCEL=ON"
      "-DENABLE_LWA=ON"
      "-DNO_BUILTIN_OPENHMD=ON"
      "-DHYBRID_SDL=On"
      "-DHYBRID_HEADLESS=On"
      "-DFSRV_DECODE_UVC=Off"
      # optional
      "-DVERBOSE=ON"
      #"--debug-output"
      #"--trace"
      "../src"
    ]);
  }) {};

  # arcan utilities:

  acfgfs = callPackage ({ pkgs }: derive {
    name = "acfgfs";
    src = ./arcan;
    nativeBuildInputs = with pkgs; [ cmake gcc git ];
    buildInputs = [ arcan ] ++ (with pkgs; [ fuse3 ]);
    cmakeFlags = concat ((arcanIncludeDirs arcan) ++ [ "../src/tools/acfgfs" ]);
  }) {};

  aclip = callPackage ({ pkgs }: derive {
    name = "aclip";
    src = ./arcan;
    nativeBuildInputs = with pkgs; [ cmake gcc git pkg-config ];
    buildInputs = [ arcan ];
    PKG_CONFIG_PATH = concat [ "${arcan}/lib/pkgconfig" ];
    cmakeFlags = concat ((arcanIncludeDirs arcan) ++ [ "../src/tools/aclip" ]);
  }) {};

  aloadimage = callPackage ({ pkgs }: derive {
    name = "aloadimage";
    src = ./arcan;
    nativeBuildInputs = with pkgs; [ cmake gcc git ];
    buildInputs = [ arcan ];
    cmakeFlags = concat ((arcanIncludeDirs arcan) ++ [ "../src/tools/aloadimage" ]);
  }) {};

  shmmon = callPackage ({ pkgs }: derive {
    name = "shmmon";
    src = ./arcan;
    nativeBuildInputs = with pkgs; [ cmake gcc git ];
    buildInputs = [ arcan ];
    cmakeFlags = concat ((arcanIncludeDirs arcan) ++ [ "../src/tools/shmmon" ]);
  }) {};

  # TODO: provide <hidapi/hidapi.h> include path
  #vrbridge = callPackage ({ pkgs }: derive {
    #name = "vrbridge";
    #src = ./arcan;
    #nativeBuildInputs = with pkgs; [ cmake gcc git pkg-config ];
    #buildInputs = [ arcan ] ++ (with pkgs; [ libusb1 ]);
    #cmakeFlags = concat (
      #(arcanIncludeDirs arcan) ++
      #(libusbDirs pkgs.libusb1) ++
      #[ "../src/tools/vrbridge" ]
    #);
  #}) {};

  # arcan appls

  prio = arcanAppl "prio" ./prio "*";
  durden = arcanAppl "durden" ./durden "durden";
  safespaces = arcanAppl "safespaces" ./safespaces "safespaces";
  awb = arcanAppl "awb" ./awb "*";

})
