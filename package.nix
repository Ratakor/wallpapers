{
  lib,
  stdenvNoCC,
  version ? "dirty",
  excludedCategories ? [ ],
  extraWallpapers ? [ ],
}:
let
  inherit (builtins) elem readDir attrNames;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.sources) cleanSource;
  inherit (lib.strings) hasPrefix concatMapStringsSep;
  inherit (lib.trivial) concat;

  categories =
    readDir ./.
    |> filterAttrs (
      name: type: type == "directory" && !(hasPrefix "." name) && !(elem name excludedCategories)
    )
    |> attrNames
    |> concat extraWallpapers;
in
stdenvNoCC.mkDerivation {
  pname = "wallpapers";
  inherit version;

  # we could filter categories here but it's annoying
  src = cleanSource ./.;

  installPhase = ''
    mkdir -p $out
  ''
  + concatMapStringsSep "\n" (
    category: "find '${category}' -maxdepth 1 -type f ! -name 'README.md' -exec cp -t $out/ {} \\;"
  ) categories;
}
