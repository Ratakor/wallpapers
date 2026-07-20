# pkgs.mergePaths { paths ? [], excludePatterns ? [], includePatterns ? [ "*" ] }
# rawPaths for paths that doesn't need filters
# extraWallpapers -> paths (multiple sources)
# exculdePatterns instead of excludeCategories
# src ? fetch github...., use xdg_pic wp for self.wp
# add wp's package.nix to nixos flake and pkg it from here which should avoid the need to fetch it unncessarily, also pname + version => name = "wallpapers"
{
  lib,
  stdenvNoCC,
  linkFarm,
  runCommandLocal,

  version ? "dirty",
  paths ? [ ./. ],
  excludedCategories ? [ ],
  extraWallpapers ? [ ],
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

  # TODO: handle collisions
  # flattenAttrs = attrs: builtins.foldl' (a: b: a // b) { } (builtins.attrValues attrs);
  # flattenAttrs =
  #   attrs:
  #   foldl' (
  #     acc: name:
  #     let
  #       value = attrs.${name};
  #     in
  #     if isAttrs value then acc // flattenAttrs value else acc // { ${name} = value; }
  #   ) { } (attrNames attrs);

  hasValidExtension = fileName: any (ext: hasSuffix ext "${fileName}") extensions;

  # filterPath =
  #   name: type:
  #   let
  #     baseName = baseNameOf name;
  #   in
  #   !hasPrefix "." baseName
  #   # handling excludedCategories here causes a rebuild of src
  #   # but it's probably better and more efficient
  #   && (
  #     (type == "directory" && !elem baseName excludedCategories)
  #     || (type == "regular" && hasValidExtension baseName)
  #   );

  fetchPath =
    path:
    filterAttrs (
      name: type:
      !hasPrefix "." name && (type == "directory" || (type == "regular" && hasValidExtension name))
    ) (readDir path);
  # src = ./.;

  # fetchPath = readDir;
  # src = cleanSourceWith {
  #   src = cleanSource ./.;
  #   filter = filterPath;
  # };

  # mkWallpapers =
  #   let
  #     internalFunc =
  #       dir:
  #       mapAttrs' (
  #         name: type:
  #         let
  #           path = "${dir}/${name}";
  #         in
  #         if type == "directory" then
  #           {
  #             inherit name;
  #             value = internalFunc path // {
  #               # outPath = path;
  #             };
  #           }
  #         else
  #           {
  #             name = head (match "^(.+)\\.[^.]+$" name);
  #             # inherit name;
  #             value = path;
  #           }
  #       ) (readDir dir);
  #   in
  #   dir:
  #   internalFunc (cleanSourceWith {
  #     src = cleanSource dir;
  #     filter = filterPath;
  #   });

  mkWallpapers =
    dir:
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
  # internalFunc (cleanSourceWith {
  #   src = cleanSource dir;
  #   filter = filterPath;
  # });

  # categories = attrNames (readDir src); # |> concat extraWallpapers;

  # wallpapers = genAttrs categories (
  #   category:
  #   (mapAttrs' (name: _value: {
  #     name = lib.head (builtins.match "^(.+)\\.[^.]+$" name);
  #     value = ./${category}/${name}; # mkDerivation nstead?
  #   }) (readDir ./${category}))
  #   // {
  #     outPath = ./${category};
  #     # TODO: pathType name == "directory"
  #     # extra = lib.genAttrs' (name: {
  #     #   name = lib.head (builtins.match "^(.+)\\.[^.]+$" name);
  #     #   value = ./${category}/${name}; # mkDerivation nstead?
  #     # }) extraWallpapers;
  #   }
  # );

  # wallpapers = mkWallpapers ./.;
  wallpapers = map mkWallpapers paths |> foldl' recursiveUpdate { };

  entries = wallpapers // {
    # all = flattenAttrs wallpapers;
  };

  linkCommands = mapAttrsToListRecursive (_attrPath: path: ''
    cp -- ${escapeShellArg "${path}"} ${escapeShellArg "${baseNameOf path}"}
  '') entries;

  # linkCommands = lib.mapAttrsToList (_name: path: ''
  #   cp -v -- ${lib.escapeShellArg "${path}"} ${lib.escapeShellArg "${baseNameOf path}"}
  # '') entries.all;
in
# linkFarm "wallpapers" (flattenAttrs wallpapers)
runCommandLocal "wallpapers"
  {
    # TODO: what is pos?
    # Get the position from the `entries` attrset if it exists.
    # This is the best we can do since the other attrs are either defined here, or curried values that
    # we cannot extract a position from
    # pos =
    #   if (isAttrs entries) && (entries != { }) then
    #     builtins.unsafeGetAttrPos (builtins.head (builtins.attrNames entries)) entries
    #   else
    #     null;
    passthru = {
      inherit entries;
    };
  }
  ''
    mkdir -p $out
    cd $out
    ${concatStrings linkCommands}
  ''
