{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "jumppad";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "jumppad-labs";
    repo = "jumppad";
    rev = version;
    hash = "sha256-RgUjefOWOIIRPtXOLBkXaJoSprmsMRzyUPjt/RLVFFc=";
  };
  vendorHash = "sha256-HyG6gPl3uyDR3GZqrFktnbKihIgIj/BZdntE4S0KD2M=";

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-X main.version=${version}"
  ];

  # Tests require a large variety of tools and resources to run including
  # Kubernetes, Docker, and GCC.
  doCheck = false;

  meta = with lib; {
    description = "Tool for building modern cloud native development environments";
    homepage = "https://jumppad.dev";
    license = licenses.mpl20;
    maintainers = with maintainers; [ cpcloud ];
    mainProgram = "jumppad";
  };
}
