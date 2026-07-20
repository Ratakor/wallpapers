{
  lib,
  config,
  stdenv,
  stdenvNoCC,
  jq,
  lndir,
  runtimeShell,
  shellcheck-minimal,
}:
let
  inherit (lib)
    optionalAttrs
    optionalString
    hasPrefix
    warn
    map
    isList
    foldl'
    ;
in
lib.extendMkDerivation {
  constructDrv = stdenvNoCC.mkDerivation;

  excludeDrvArgNames = [
    "paths"
    "excludePatterns"
    "includePatterns"
    "postBuild"
  ];

  extendDrvArgs =
    finalAttrs:
    args@{
      name ?
        assert
          (finalAttrs ? pname && finalAttrs ? version)
          || throw "mergePaths requires either a `name` OR `pname` and `version`";
        "${finalAttrs.pname}-${finalAttrs.version}",
      paths,
      excludePatterns ? [ ],
      includePatterns ? [ ".*" ],
      postBuild ? "",
      preferLocalBuild ? true,
      allowSubstitutes ? false,
      ...
    }:
    let
      mapPaths =
        f:
        map (
          path:
          if path == null then
            null
          else if isList path then
            mapPaths f path
          else
            f path
        );
    in
    {
      enableParallelBuilding = true;
      inherit name allowSubstitutes preferLocalBuild;
      passAsFile = [
        "buildCommand"
        "paths"
      ];
      paths = mapPaths (path: "${path}") paths;
      buildCommand = ''
        mkdir -p $out
        if [ -n "''${pathsPath:-}" ] && [ -f "$pathsPath" ]; then
          mapfile -d " " -t paths < "$pathsPath"
        fi
        for i in "''${paths[@]}"; do
          ${optionalString (!failOnMissing) "if test -d $i; then "}${lndir}/bin/lndir -silent $i $out${
            optionalString (!failOnMissing) "; fi"
          }
        done
        ${postBuild}
      '';
    }
    // {
      ${if !args ? meta then "pos" else null} =
        if args ? pname then
          builtins.unsafeGetAttrPos "pname" args
        else
          builtins.unsafeGetAttrPos "name" args;
    };
}
