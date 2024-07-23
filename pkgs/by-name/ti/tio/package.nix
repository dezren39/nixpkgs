{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  glib,
  inih,
  lua,
  bash-completion,
  darwin,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tio";
  version = "3.5";

  src = fetchFromGitHub {
    owner = "tio";
    repo = "tio";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3d3TYHSERIQdw+Iw6qCydGpWRpWrhZwb4SnwV1nVtIk=";
  };

  strictDeps = true;

  buildInputs = [
    inih
    lua
    glib
  ] ++ lib.optionals (stdenv.hostPlatform.isDarwin) [ darwin.apple_sdk.frameworks.IOKit ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    bash-completion
  ];

  meta = with lib; {
    description = "Serial console TTY";
    homepage = "https://tio.github.io/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ yana ];
    mainProgram = "tio";
    platforms = platforms.unix;
  };
})
