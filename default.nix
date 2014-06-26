let pkgs = import ./nix_configs/nixpkgs {};
in pkgs.haskellPackages.callPackage ./bootstrap.nix {}
