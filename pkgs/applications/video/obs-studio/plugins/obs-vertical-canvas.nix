{ lib
, stdenv
, fetchFromGitHub
, cmake
, curl
, obs-studio
, qtbase
}:

stdenv.mkDerivation rec {
  pname = "obs-vertical-canvas";
  version = "1.4.5";

  src = fetchFromGitHub {
    owner = "Aitum";
    repo = "obs-vertical-canvas";
    rev = version;
    sha256 = "sha256-4BmTp/PrR01H9IrKNX9ZpK4kLaiNG/G9rTMf9dsoV0s=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ curl obs-studio qtbase ];

  cmakeFlags = [
    "-DBUILD_OUT_OF_TREE=On"
  ];

  dontWrapQtApps = true;

  postInstall = ''
    rm -rf $out/data
    rm -rf $out/obs-plugins
  '';

  meta = with lib; {
    description = "Plugin for OBS Studio to add vertical canvas";
    homepage = "https://github.com/Aitum/obs-vertical-canvas";
    maintainers = with maintainers; [ flexiondotorg ];
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
