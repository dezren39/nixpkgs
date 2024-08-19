{ lib, rustPlatform, fetchCrate, stdenv, darwin }:

rustPlatform.buildRustPackage rec {
  pname = "runiq";
  version = "2.0.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-qcgPuJOpK2fCsHAgzoIKF7upb9B3ySIZkpu9xf4JnCc=";
  };

  cargoHash = "sha256-WSMV0GNKNckN9uSPN647iDloGkNtaKcrZbeyglUappc=";

  buildInputs = lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ];

  doCheck = false; # jen / bson don't build yet with Rust 1.80.0, needed for the tests

  meta = with lib; {
    description = "Efficient way to filter duplicate lines from input, à la uniq";
    mainProgram = "runiq";
    homepage = "https://github.com/whitfin/runiq";
    license = licenses.mit;
    maintainers = with maintainers; [ figsoda ];
  };
}
