with import <nixpkgs> {};
let

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
      rev = "master";
      sha256 = "09zl07aa946f8rha6sn72b19np5sfxamjq4asv897h2y7my67i79";
    };
    nativeBuildInputs = with pkgs; [ git ];
    # fetchgit strips all refs, creating a fetchgit branch
    # but cmake needs to check out the ref called 'master':
    installPhase = ''
      git tag master
      cp -r . $out/
      cd $out
    '';
  };

  arcan = derive {
    name = "arcan";
    src = ./arcan;
    patches = [ ./nosuid.patch ];
    # add vendored libuvc
    postUnpack = ''
      mkdir -p ./arcan/external/git/libuvc
      pushd ./arcan/external/git/
      shopt -s dotglob nullglob  # bashism: * now also matches dotfiles
      cp -r ${libuvc-src}/* libuvc/
      git checkout master
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
    cmakeFlags = concat [
      # cmake won't be able to find these paths on its own:
      "-DDRM_INCLUDE_DIR=${pkgs.libdrm.dev}/include/libdrm"
      "-DGBM_INCLUDE_DIR=${pkgs.libGL.dev}/include"
      "-DLIBUSB_1_INCLUDE_DIRS=${pkgs.libusb1}/lib"
      "-DLIBUSB_1_LIBRARIES=${pkgs.libusb1.dev}/include"
      "-DWAYLANDPROTOCOLS_PATH=${pkgs.wayland-protocols}/share/wayland-protocols"

      # enable features:
      "-DVIDEO_PLATFORM=egl-dri"
      "-DSHMIF_TUI_ACCEL=ON"
      "-DENABLE_LWA=ON"
      "-DVERBOSE=ON"
      "-DNO_BUILTIN_OPENHMD=ON"
      "-DHYBRID_SDL=On"
      "-DHYBRID_HEADLESS=On"
      "-DFSRV_DECODE_UVC=Off"

      # optional
      #"--debug-output"
      #"--trace"

      "../src"
    ];
  };
in arcan
