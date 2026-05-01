{
  lib,
  stdenvNoCC,
  version ? "dirty",
  categories ? [ ], # leave empty for all
  extensions ? [ ], # leave empty for all, available: jpeg jpg png webp
}:
let
  allCategories = lib.filterAttrs (name: type: type == "directory" && !(lib.hasPrefix "." name)) (
    builtins.readDir ./.
  );

  selectedCategories = if categories == [ ] then builtins.attrNames allCategories else categories;

  invalidCategories = builtins.filter (
    category: !(builtins.hasAttr category allCategories)
  ) selectedCategories;

  extFilter =
    if extensions == [ ] then
      ""
    else
      "\\( ${lib.concatMapStringsSep " -o " (ext: "-name '*.${ext}'") extensions} \\)";
in
if invalidCategories != [ ] then
  throw "Invalid categories: ${lib.concatStringsSep ", " invalidCategories}"
else
  stdenvNoCC.mkDerivation {
    pname = "wallpapers";
    inherit version;

    # we could filter categories here
    src = lib.cleanSource ./.;

    installPhase = ''
      mkdir -p $out
    ''
    + lib.concatMapStringsSep "\n" (
      category:
      "find '${category}' -maxdepth 1 -type f ${extFilter} ! -name 'README.md' -exec cp -t $out/ {} \\;"
    ) selectedCategories;
  }
