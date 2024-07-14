{ pkgs }:

with pkgs;

let
  openjfx11 = callPackage ../development/compilers/openjdk/openjfx/11 { };
  openjfx15 = callPackage ../development/compilers/openjdk/openjfx/15 { };
  openjfx17 = callPackage ../development/compilers/openjdk/openjfx/17 { };
  openjfx19 = callPackage ../development/compilers/openjdk/openjfx/19 { };
  openjfx20 = callPackage ../development/compilers/openjdk/openjfx/20 { };
  openjfx21 = callPackage ../development/compilers/openjdk/openjfx/21 { };
  openjfx22 = callPackage ../development/compilers/openjdk/openjfx/22 { };

in {
  inherit openjfx11 openjfx17 openjfx19 openjfx20 openjfx21 openjfx22;

  compiler = let
    mkOpenjdk = path-linux: path-darwin: args:
      if stdenv.isLinux
      then mkOpenjdkLinuxOnly path-linux args
      else let
        openjdk = callPackage path-darwin {};
      in openjdk // { headless = openjdk; };

    mkOpenjdkLinuxOnly = path-linux: args: let
      openjdk = callPackage path-linux (args);
    in assert stdenv.isLinux; openjdk // {
      headless = openjdk.override { headless = true; };
    };

  in rec {
    corretto11 = callPackage ../development/compilers/corretto/11.nix { };
    corretto17 = callPackage ../development/compilers/corretto/17.nix { };
    corretto19 = callPackage ../development/compilers/corretto/19.nix { };
    corretto21 = callPackage ../development/compilers/corretto/21.nix { };

    openjdk8-bootstrap = temurin-bin.jdk-8;

    openjdk11-bootstrap = temurin-bin.jdk-11;

    openjdk17-bootstrap = temurin-bin.jdk-17;

    openjdk8 = mkOpenjdk
      ../development/compilers/openjdk/8.nix
      ../development/compilers/zulu/8.nix
      { };

    openjdk11 = mkOpenjdk
      ../development/compilers/openjdk/11.nix
      ../development/compilers/zulu/11.nix
      { openjfx = openjfx11; };

    openjdk17 = mkOpenjdk
      ../development/compilers/openjdk/17.nix
      ../development/compilers/zulu/17.nix
      {
        inherit openjdk17-bootstrap;
        openjfx = openjfx17;
      };

    openjdk18 = mkOpenjdk
      ../development/compilers/openjdk/18.nix
      ../development/compilers/zulu/18.nix
      {
        openjdk18-bootstrap = temurin-bin.jdk-18;
        openjfx = openjfx17;
      };

    openjdk19 = mkOpenjdk
      ../development/compilers/openjdk/19.nix
      ../development/compilers/zulu/19.nix
      {
        openjdk19-bootstrap = temurin-bin.jdk-19;
        openjfx = openjfx19;
      };

    openjdk20 = mkOpenjdk
      ../development/compilers/openjdk/20.nix
      ../development/compilers/zulu/20.nix
      {
        openjdk20-bootstrap = temurin-bin.jdk-20;
        openjfx = openjfx20;
      };

    openjdk21 = mkOpenjdk
      ../development/compilers/openjdk/21.nix
      ../development/compilers/zulu/21.nix
      {
        openjdk21-bootstrap = temurin-bin.jdk-21;
        openjfx = openjfx21;
      };

    openjdk22 = mkOpenjdk
      ../development/compilers/openjdk/22.nix
      ../development/compilers/zulu/22.nix
      {
        openjdk22-bootstrap = temurin-bin.jdk-22;
        openjfx = openjfx22;
      };

    temurin-bin = recurseIntoAttrs (callPackage (
      if stdenv.isLinux
      then ../development/compilers/temurin-bin/jdk-linux.nix
      else ../development/compilers/temurin-bin/jdk-darwin.nix
    ) {});

    semeru-bin = recurseIntoAttrs (callPackage (
      if stdenv.isLinux
      then ../development/compilers/semeru-bin/jdk-linux.nix
      else ../development/compilers/semeru-bin/jdk-darwin.nix
    ) {});
  };
}
// lib.optionalAttrs config.allowAliases {
  jogl_2_4_0 = throw "'jogl_2_4_0' is renamed to/replaced by 'jogl'";
  mavenfod = throw "'mavenfod' is renamed to/replaced by 'maven.buildMavenPackage'";
}
