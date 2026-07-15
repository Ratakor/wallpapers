{
  inputs.nixpkgs.url = "nixpkgs";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = f: builtins.mapAttrs (_system: pkgs: f pkgs) nixpkgs.legacyPackages;

      date = builtins.concatStringsSep "-" (builtins.match "(.{4})(.{2})(.{2}).*" self.lastModifiedDate);
      version = "0-unstable-${date}";
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.callPackage ./package.nix { inherit version; };
      });
    };
}
