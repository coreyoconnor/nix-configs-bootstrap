{cabal, shelly}:
cabal.mkDerivation (self: {
  pname = "nix-configs-bootstrap";
  version = "0.1.0.0";
  src = ../nix-configs-bootstrap;
  isLibrary = false;
  isExecutable = true;
  buildDepends = [ shelly ];
})
