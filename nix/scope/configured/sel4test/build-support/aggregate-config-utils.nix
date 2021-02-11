{ lib, runCommand }:

{

  collect = drvs: with lib;
    let
      g = concatMap f;
      f = { outPath, propagatedBuildInputs ? [], ... }: [ outPath ] ++ g propagatedBuildInputs;
      all = unique (g drvs);
    in
      runCommand "cache.txt" {} ''
        (${concatMapStrings (drv: ''
          find ${drv} -path '*/sel4-config/*.txt' -exec cat {} \;
        '') all}) \
          | sort | uniq > $out
      '';

  extract = cmakeCache: with lib;
    runCommand "cache.txt" {} ''
      sed -n '/^\(\([A-Z][a-z]\|CAm\)[^:]*\):\([^=]*\)=\(.*\)$/p' ${cmakeCache} \
        | grep -v '_.*_DIR:STATIC' \
        | sort | uniq > $out
    '';

}
