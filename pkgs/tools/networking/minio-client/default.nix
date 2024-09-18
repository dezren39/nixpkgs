{ lib, buildGoModule, fetchFromGitHub, nixosTests }:

buildGoModule rec {
  pname = "minio-client";
  version = "2024-09-09T07-53-10Z";

  src = fetchFromGitHub {
    owner = "minio";
    repo = "mc";
    rev = "RELEASE.${version}";
    sha256 = "sha256-K0FuG7c8sD4ingJH/al7TBoTCHKGad7I2RYheTjqAR0=";
  };

  vendorHash = "sha256-KNnYxE3kt/eemnhsRf29SZX0Q+ECzdMFVgcmd7uCsyY=";

  subPackages = [ "." ];

  patchPhase = ''
    sed -i "s/Version.*/Version = \"${version}\"/g" cmd/build-constants.go
    sed -i "s/ReleaseTag.*/ReleaseTag = \"RELEASE.${version}\"/g" cmd/build-constants.go
    sed -i "s/CommitID.*/CommitID = \"${src.rev}\"/g" cmd/build-constants.go
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/mc --version | grep ${version} > /dev/null
  '';

  passthru.tests.minio = nixosTests.minio;

  meta = with lib; {
    homepage = "https://github.com/minio/mc";
    description = "Replacement for ls, cp, mkdir, diff and rsync commands for filesystems and object storage";
    maintainers = with maintainers; [ bachp ];
    mainProgram = "mc";
    license = licenses.asl20;
  };
}
