{ lib, pkgs, meta }:

rec {
  html = pkgs.dev.runCommand "html" {} ''
    mkdir -p $out
    cp ${index} $out/index.html

    rustdoc_root=$out/rustdoc
    mkdir -p $rustdoc_root
    ${lib.concatMapStrings (adHoc: ''
      x=$rustdoc_root/${adHoc.adHocPath}
      mkdir -p $(dirname $x)
      ln -s ${adHoc}/doc $x
    '') meta.adHocBuildTests.allList}
  '';

  index = pkgs.dev.writeText "index.html" ''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <title>IceCap</title>
      </head>
      <body>
        <div>
          <ul>
            ${lib.concatMapStrings (adHoc: ''
              ${lib.concatMapStrings (kind: ''
                <li>
                  <a href="./rustdoc/${adHoc.adHocPath}/${kind}/cfg_if/index.html">
                    ${adHoc.adHocPath}/${kind}
                  </a>
                </li>
              '') [ "target" "build" ]}
            '') meta.adHocBuildTests.allList}
          </ul>
        </div>
      </body>
    </html>
  '';
}
