{ lib, stdenv, fetchFromGitHub, cmake, python3 }:

stdenv.mkDerivation (finalAttrs: {
  pname = "spirv-cross";
  version = "1.3.290.0";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-Cross";
    rev = "vulkan-sdk-${finalAttrs.version}";
    hash = "sha256-h5My9PbPq1l03xpXQQFolNy7G1RhExtTH6qPg7vVF/8=";
  };

  nativeBuildInputs = [ cmake python3 ];

  postFixup = ''
    substituteInPlace $out/lib/pkgconfig/*.pc \
      --replace '=''${prefix}//' '=/'
  '';

  meta = with lib; {
    description = "Tool designed for parsing and converting SPIR-V to other shader languages";
    homepage = "https://github.com/KhronosGroup/SPIRV-Cross";
    changelog = "https://github.com/KhronosGroup/SPIRV-Cross/releases/tag/${finalAttrs.version}";
    platforms = platforms.all;
    license = licenses.asl20;
    maintainers = with maintainers; [ Flakebi ];
    mainProgram = "spirv-cross";
  };
})
