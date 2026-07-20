{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,

  extensions ? [
    ".jpg"
    ".jpeg"
    ".png"
    ".webp"
  ],
}:
let
  inherit (builtins)
    any
    attrNames
    elem
    foldl'
    head
    isAttrs
    match
    readDir
    ;
  inherit (lib.attrsets)
    concatMapAttrs
    filterAttrs
    genAttrs
    mapAttrs'
    mapAttrsToListRecursive
    recursiveUpdate
    ;
  inherit (lib.sources) cleanSource cleanSourceWith;
  inherit (lib.strings)
    concatMapStringsSep
    concatStrings
    escapeShellArg
    hasPrefix
    hasSuffix
    ;
  inherit (lib.trivial) concat;
in
rec {
  hasValidExtension = fileName: any (ext: hasSuffix ext fileName) extensions;

  fetchPath =
    path:
    filterAttrs (
      name: type:
      !hasPrefix "." name && (type == "directory" || (type == "regular" && hasValidExtension name))
    ) (readDir path);

  mkWallpapers =
    dirArg:
    let
      dir = toString dirArg;
    in
    concatMapAttrs (
      name: type:
      let
        path = "${dir}/${name}";
      in
      if type == "directory" then
        mkWallpapers path
      else
        {
          # ${head (match "^(.+)\\.[^.]+$" name)} = path;
          ${name} = path;
        }
    ) (fetchPath dir);
}
