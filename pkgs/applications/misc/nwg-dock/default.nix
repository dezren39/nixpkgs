{ lib
, buildGoModule
, fetchFromGitHub
, pkg-config
, gtk3
, gtk-layer-shell
}:

buildGoModule rec {
  pname = "nwg-dock";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "nwg-piotr";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-qmzCjbWmrDJBB2gnhR5hc0sYD3V0i/SKTavfMA2iLyc=";
  };

  vendorHash = "sha256-paRcBQwg2uGouMRX5XF++OyN8Y0JyucXLN0G5O0j3qA=";

  ldflags = [ "-s" "-w" ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk3 gtk-layer-shell ];

  meta = with lib; {
    description = "GTK3-based dock for sway";
    homepage = "https://github.com/nwg-piotr/nwg-dock";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ dit7ya ];
    mainProgram = "nwg-dock";
  };
}
