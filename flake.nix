{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    naersk = {
      url = github:nmattia/naersk;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = github:nix-community/fenix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, naersk, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        toolchain = with fenix.packages.${system};
          combine [
            minimal.rustc
            minimal.cargo
            targets.x86_64-unknown-linux-musl.latest.rust-std
          ];
        naersk-lib = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };
      in
      {
        defaultPackage = self.packages.${system}.nix-autobahn;

        packages.nix-autobahn = naersk-lib.buildPackage {
          src = ./.;
          nativeBuildInputs = with pkgs; [ pkgsStatic.stdenv.cc ];
          CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
          CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
        };

        defaultApp = self.apps.${system}.nix-autobahn;

        apps = {
          nix-autobahn = {
            type = "app";
            program = "${self.packages.${system}.nix-autobahn}/bin/nix-autobahn";
          };
        };
      }
    );
}
