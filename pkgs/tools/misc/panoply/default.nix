{ lib, stdenvNoCC, fetchurl, makeWrapper, jre } :

stdenvNoCC.mkDerivation rec {
  pname = "panoply";
  version = "5.4.3";

  src = fetchurl {
    url = "https://www.giss.nasa.gov/tools/panoply/download/PanoplyJ-${version}.tgz";
    sha256 = "sha256-xey1Og0TEMgCc9Me/np7BGnUNYTz98gMFzLm2IcQHtw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    jarbase=$out/share/panoply
    mkdir -p $out/bin $jarbase/jars

    sed -i "s:^SCRIPTDIR.*:SCRIPTDIR=$jarbase:" panoply.sh

    cp panoply.sh $out/bin/panoply
    cp -r jars $jarbase

    wrapProgram "$out/bin/panoply" --prefix PATH : "${jre}/bin"

    runHook postHook
  '';

  meta = with lib; {
    description = "netCDF, HDF and GRIB Data Viewer";
    homepage = "https://www.giss.nasa.gov/tools/panoply";
    platforms = platforms.linux;
    maintainers = [ maintainers.markuskowa ];
    license = licenses.unfree;  # Package does not state a license
    mainProgram = "panoply";
  };
}
