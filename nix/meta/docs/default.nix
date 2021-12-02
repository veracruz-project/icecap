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
          <h1>IceCap</h1>
            <h3>source</h3>
              <a href="https://gitlab.com/arm-research/security/icecap/icecap/">https://gitlab.com/arm-research/security/icecap/icecap/</a>
            <!--
            <h3>high-level documentation</h3>
              <a href="https://gitlab.com/arm-research/security/icecap/icecap/-/tree/main/docs">https://gitlab.com/arm-research/security/icecap/icecap/-/tree/main/docs</a>
            -->
            <h3>rustdoc</h3>
              <ul>
                ${lib.concatMapStrings (adHoc: ''
                  <li>
                    ${adHoc.adHocPath}:
                    <a href="./rustdoc/${adHoc.adHocPath}/target/cfg_if/index.html">target</a>
                    <a href="./rustdoc/${adHoc.adHocPath}/build/syn/index.html">build</a>
                  </li>
                '') meta.adHocBuildTests.allList}
              </ul>
        </div>
      </body>
    </html>
  '';
}
