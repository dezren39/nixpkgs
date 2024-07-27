{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, alsa-lib
, ffmpeg
, kdePackages
, kdsingleapplication
, pipewire
, taglib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fooyin";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "ludouzi";
    repo = "fooyin";
    rev = "v" + finalAttrs.version;
    hash = "sha256-X546vdHSfED2LBztPj+3eK86pjD97I8H+PfhzXV2R3E=";
  };

  buildInputs = [
    alsa-lib
    ffmpeg
    kdsingleapplication
    pipewire
    kdePackages.qcoro
    kdePackages.qtbase
    kdePackages.qtsvg
    taglib
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    kdePackages.qttools
    kdePackages.wrapQtAppsHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_TESTING" (finalAttrs.doCheck or false))
    # we need INSTALL_FHS to be true as the various artifacts are otherwise just dumped in the root
    # of $out and the fixupPhase cleans things up anyway
    (lib.cmakeBool "INSTALL_FHS" true)
  ];

  env.LANG = "C.UTF-8";

  meta = with lib; {
    description = "Customisable music player";
    mainProgram = "fooyin";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ peterhoeg ];
    platforms = platforms.all;
  };
})
