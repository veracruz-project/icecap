{ lib, pkgs, rustAggregate }:

let
  uniqueOn = with lib; f: foldl' (acc: e: if elem (f e) (map f acc) then acc else acc ++ [ e ]) [];

  htmlWithConfig = { docArgs, worldFilter }: rec {

    html = pkgs.dev.linkFarm "html" [
      { name = "rustdoc"; path = rustdocHtml; }
      { name = "sel4-manual.pdf"; path = "${pkgs.dev.icecap.sel4-manual}/manual.pdf"; }
    ];

    rustdocAttrs = worldFilter (lib.mapAttrs (_: lib.mapAttrs (_: v: v docArgs)) rustAggregate.allAttrs);

    rustdocList = uniqueOn (x: x.worldPath) (lib.concatMap lib.attrValues (lib.attrValues rustdocAttrs));

    rustdocHtml = pkgs.dev.runCommand "html" {} ''
      mkdir -p $out
      cp ${rustdocIndex} $out/index.html

      worlds=$out/worlds
      mkdir -p $worlds
      ${lib.concatMapStrings (world: ''
        x=$worlds/${world.worldPath}
        mkdir -p $(dirname $x)
        ln -s ${world}/doc $x
      '') rustdocList}
    '';

    rustdocIndex = pkgs.dev.writeText "index.html" ''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>IceCap rustdoc</title>
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.0.0/github-markdown.min.css" integrity="sha512-nxv6uny69e6SeGW/aOEW0iC2+ruQMKvFDbjav6sVu1dr89ioo5wBm3F0IbBGsNyAt6nuBR/x2HUSx0a7wLEegA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
          <style>
            .markdown-body {
              box-sizing: border-box;
              min-width: 200px;
              max-width: 980px;
              margin: 0 auto;
              padding: 45px;
            }
            @media (max-width: 767px) {
              .markdown-body {
                padding: 15px;
              }
            }
          </style>
        </head>
        <body>
          <div class="markdown-body">
            <h1>IceCap rustdoc</h1>
            <p>
              Start here:
              <a href="https://arm-research.gitlab.io/security/icecap/html/rustdoc/worlds/aarch64-icecap/virt/host/icecap_core/index.html">
                icecap-core
              </a>
            </p>
            <p>
              All targets:
              <ul>
                ${lib.concatMapStrings (world: ''
                  <li>
                    <a href="./worlds/${world.worldPath}/host/index.html">${world.worldPath}</a>
                    (<a href="./worlds/${world.worldPath}/build/quote/index.html">build-dependencies</a>)
                  </li>
                '') rustdocList}
              </ul>
            </p>
          </div>
        </body>
      </html>
    '';
  };

in rec {
  complete = htmlWithConfig {
    docArgs = {
      doc = true;
      docDeps = true;
      docAll = true;
    };
    worldFilter = lib.id;
  };
  external = htmlWithConfig {
    docArgs = {
      doc = true;
      docDeps = true;
    };
    worldFilter = worlds: {
      seL4.rpi4 = worlds.seL4.rpi4;
      linux.musl = worlds.linux.musl;
    };
  };
}
