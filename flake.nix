{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    tabi = {
      url = "github:welpo/tabi/main";
      flake = false;
    };
  };

  outputs = { self, nixpkgs-unstable, tabi, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs-unstable { inherit system; };
      preparePhase = ''
          rm -rf themes/tabi
          ln -s ${tabi} themes/tabi
      '';

    in {
      checks.${system}.default = pkgs.runCommand "zola-check" { } ''
        set -euo pipefail
        ${pkgs.zola}/bin/zola --root ${self}/src check
        mkdir $out
      '';
      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        name = "fabianhauser.ch-${version}";
        version = "2022";
        buildInputs = [ pkgs.zola ];
        src = ./src;
        installPhase = ''
          ${preparePhase}
          zola --root . build --output-dir $out
        '';
      };
      apps.${system}.default = let
        zola = pkgs.writeShellScriptBin "zola" ''
          cd src
          ${preparePhase}
          ${pkgs.zola}/bin/zola --root . ''${@}
        '';
      in {
        type = "app";
        program = "${zola}/bin/zola";
      };
    };
}
