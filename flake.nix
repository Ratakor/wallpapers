{
  outputs =
    { self, ... }:
    let
      date = builtins.concatStringsSep "-" (builtins.match "(.{4})(.{2})(.{2}).*" self.lastModifiedDate);
      version = "0-unstable-${date}";
    in
    {
      overlays.default = _final: pkgs: {
        wallpapers = pkgs.callPackage ./package.nix { inherit version; };
      };
    };
}
