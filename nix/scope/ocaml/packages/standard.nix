{ lib, buildPlatform, hostPlatform
, fetchurl, fetchFromGitHub
, pkgconfig
, buildDunePackage, buildJanePackage, buildTopkgPackage
, buildPackagesOCaml
}:

self: with self; {

  # Jane Street

  sexplib0 = buildJanePackage {
    pname = "sexplib0";
    sha256 = "13xdd0pvypxqn0ldwdgikmlinrp3yfh8ixknv1xrpxbx3np4qp0g";
  };

  parsexp = buildJanePackage {
    pname = "parsexp";
    sha256 = "1974i9s2c2n03iffxrm6ncwbd2gg6j6avz5jsxfd35scc2zxcd4l";
    propagatedBuildInputsOCaml = [ sexplib0 base ];
  };

  ppx_enumerate = buildJanePackage {
    pname = "ppx_enumerate";
    sha256 = "08zfpq6bdm5lh7xj9k72iz9f2ihv3aznl3nypw3x78vz1chj8dqa";
    propagatedBuildInputsOCaml = [ ppxlib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ocaml-compiler-libs = buildJanePackage {
    pname = "ocaml-compiler-libs";
    version = "0.11.0";
    sha256 = "03jds7bszh8wwpfwxb3dg0gyr1j1872wxwx1xqhry5ir0i84bg0s";
  };

  sexplib = buildJanePackage {
    pname = "sexplib";
    sha256 = "0780klc5nnv0ij6aklzra517cfnfkjdlp8ylwjrqwr8dl9rvxza2";
    propagatedBuildInputsOCaml = [ num parsexp ];
  };

  result = buildDunePackage rec {
    pname = "result";
    version = "1.3";
    src = fetchFromGitHub {
      owner = "janestreet";
      repo = pname;
      rev = "${version}";
      sha256 = "081ayblszn9pj2rqcif40x6cz2zda48vi45gy49rc2qfc4gszry3";
    };
  };

  base = buildJanePackage {
    pname = "base";
    sha256 = "0v2iz38vd6d0khnc1hj7az4r088jjpbsjrmric34x7sj4dnmrlj1";
    propagatedBuildInputsOCaml = [ sexplib0 ];
    postPatch = ''
      sed -i 's|\''${null}|/dev/null|' src/dune
    '';
  };

  stdio = buildJanePackage {
    pname = "stdio";
    sha256 = "1pn8jjcb79n6crpw7dkp68s4lz2mw103lwmfslil66f05jsxhjhg";
    propagatedBuildInputsOCaml = [ base ];
  };

  configurator = buildJanePackage {
    pname = "configurator";
    version = "0.11.0";
    sha256 = "0h686630cscav7pil8c3w0gbh6rj4b41dvbnwmicmlkc746q5bfk";
    propagatedBuildInputsOCaml = [ stdio ];
  };

  jane-street-headers = buildJanePackage {
    pname = "jane-street-headers";
    sha256 = "0qa4llf812rjqa8nb63snmy8d8ny91p3anwhb50afb7vjaby8m34";
  };

  splittable_random = buildJanePackage {
    pname = "splittable_random";
    sha256 = "1wpyz7807cgj8b50gdx4rw6f1zsznp4ni5lzjbnqdwa66na6ynr4";
    propagatedBuildInputsOCaml = [ base ppx_assert ppx_bench ppx_inline_test ppx_sexp_message ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_assert ppx_bench ppx_inline_test ppx_sexp_message ];
  };

  base_bigstring = buildJanePackage {
    pname = "base_bigstring";
    sha256 = "0rbgyg511847fbnxad40prz2dyp4da6sffzyzl88j18cxqxbh1by";
    propagatedBuildInputsOCaml = [ base ppx_jane ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_jane ];
  };

  core_kernel = buildJanePackage {
    pname = "core_kernel";
    sha256 = "1fxl5aadsnfhlfdg423i231i28i7msvzny7s24q3cy0h2v7r5n00";
    propagatedBuildInputsOCaml = [ configurator jane-street-headers sexplib splittable_random base_bigstring ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_jane ];
  };

  spawn = buildJanePackage {
    pname = "spawn";
    version = "0.13.0";
    sha256 = "1w003k1kw1lmyiqlk58gkxx8rac7dchiqlz6ah7aj7bh49b36ppf";
  };

  core = buildJanePackage {
    pname = "core";
    version = "0.12.1";
    sha256 = "1xlbz6lmxssf34365c1b0wrgnjwgbc4gw48zsirxp57wlklfb5jw";
    propagatedBuildInputsOCaml = [ core_kernel spawn ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_jane ];
  };

  ppx_jane = buildJanePackage {
    pname = "ppx_jane";
    sha256 = "1a2602isqzsh640q20qbmarx0sc316mlsqc3i25ysv2kdyhh0kyw";
    propagatedBuildInputsOCaml = [
      ppxlib base_quickcheck
      ppx_assert ppx_base ppx_bench ppx_bin_prot ppx_expect ppx_fail ppx_here
      ppx_let ppx_optcomp ppx_optional ppx_pipebang ppx_sexp_message
      ppx_sexp_value ppx_typerep_conv ppx_stable ppx_module_timer
    ];
  };

  ppx_stable = buildJanePackage {
    pname = "ppx_stable";
    sha256 = "15zvf66wlkvz0yd4bkvndkpq74dj20jv1qkljp9n52hh7d0f9ykh";
    propagatedBuildInputsOCaml = [ ppxlib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_module_timer = buildJanePackage {
    pname = "ppx_module_timer";
    sha256 = "0yziakm7f4c894na76k1z4bp7azy82xc33mh36fj761w1j9zy3wm";
    propagatedBuildInputsOCaml = [ ppxlib ppx_base time_now ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_base time_now ];
  };

  time_now = buildJanePackage {
    pname = "time_now";
    sha256 = "169mgsb3rja4j1j9nj5xa7bbkd21p9kfpskqz0wjf9x2fpxqsniq";
    propagatedBuildInputsOCaml = [ ppx_base jst-config jane-street-headers ppx_optcomp ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_base ppx_optcomp ];
  };

  jst-config = buildJanePackage {
    pname = "jst-config";
    sha256 = "0yxcz13vda1mdh9ah7qqxwfxpcqang5sgdssd8721rszbwqqaw93";
    propagatedBuildInputsOCaml = [ ppx_assert dune ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_assert dune ];
  };

  ppx_assert = buildJanePackage {
    pname = "ppx_assert";
    sha256 = "0as6mzr6ki2a9d4k6132p9dskn0qssla1s7j5rkzp75bfikd0ip8";
    propagatedBuildInputsOCaml = [ ppxlib ppx_here ppx_compare ppx_sexp_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_compare ppx_sexp_conv ];
  };

  ppx_here = buildJanePackage {
    pname = "ppx_here";
    sha256 = "07qbchwif1i9ii8z7v1bib57d3mjv0b27i8iixw78i83wnsycmdx";
    propagatedBuildInputsOCaml = [ base ppxlib ];
  };

  ppx_sexp_message = buildJanePackage {
    pname = "ppx_sexp_message";
    sha256 = "0yskd6v48jc6wa0nhg685kylh1n9qb6b7d1wglr9wnhl9sw990mc";
    propagatedBuildInputsOCaml = [ ppx_here ppx_sexp_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  typerep = buildJanePackage {
    pname = "typerep";
    sha256 = "1psl6gsk06a62szh60y5sc1s92xpmrl1wpw3rhha09v884b7arbc";
    propagatedBuildInputsOCaml = [ base ];
  };

  ppx_typerep_conv = buildJanePackage {
    pname = "ppx_typerep_conv";
    sha256 = "09vik6qma1id44k8nz87y48l9wbjhqhap1ar1hpfdfkjai1hrzzq";
    propagatedBuildInputsOCaml = [ ppxlib ppx_deriving typerep ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_compare = buildJanePackage {
    pname = "ppx_compare";
    sha256 = "0n1ax4k2smhps9hc2v58lc06a0fgimwvbi1aj4x78vwh5j492bys";
    propagatedBuildInputsOCaml = [ base ppxlib ppx_deriving ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ base ppxlib ppx_deriving ];
  };

  ppx_sexp_conv = buildJanePackage {
    pname = "ppx_sexp_conv";
    sha256 = "0idzp1kzds0gnilschzs9ydi54if8y5xpn6ajn710vkipq26qcld";
    propagatedBuildInputsOCaml = [ sexplib0 ppxlib ppx_deriving ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_base = buildJanePackage {
    pname = "ppx_base";
    sha256 = "0vd96rp2l084iamkwmvizzhl9625cagjb6gzzbir06czii5mlq2p";
    propagatedBuildInputsOCaml = [ ppxlib ppx_compare ppx_enumerate ppx_hash ppx_js_style ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_compare ppx_enumerate ppx_hash ppx_js_style ];
  };

  ppx_hash = buildJanePackage {
    pname = "ppx_hash";
    sha256 = "1dfsfvhiyp1mnf24mr93svpdn432kla0y7x631lssacxxp2sadbg";
    propagatedBuildInputsOCaml = [ ppx_compare ppx_sexp_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_compare ppx_sexp_conv ];
  };

  ppx_js_style = buildJanePackage {
    pname = "ppx_js_style";
    sha256 = "1lz931m3qdv3yzqy6dnb8fq1d99r61w0n7cwf3b9fl9rhk0pggwh";
    propagatedBuildInputsOCaml = [ ppxlib octavius ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_bench = buildJanePackage {
    pname = "ppx_bench";
    sha256 = "1ib81irawxzq091bmpi50z0kmpx6z2drg14k2xcgmwbb1d4063xn";
    propagatedBuildInputsOCaml = [ ppxlib ppx_inline_test ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_bin_prot = buildJanePackage {
    pname = "ppx_bin_prot";
    # sha256 = "0q3skd4fdsbf8qvniv9jjabg95icfbpb0ydva4xpirinmnaavp25";
    version = "0.11.1";
    sha256 = "1h60i75bzvhna1axyn662gyrzhh441l79vl142d235i5x31dmnkz";
    propagatedBuildInputsOCaml = [ bin_prot ppxlib ppx_here ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ bin_prot ppxlib ppx_here ];
  };

  fieldslib = buildJanePackage {
    pname = "fieldslib";
    sha256 = "0dlgr7cimqmjlcymk3bdcyzqzvdy12q5lqa844nqix0k2ymhyphf";
    propagatedBuildInputsOCaml = [ ppxlib ];
  };

  ppx_fields_conv = buildJanePackage {
    pname = "ppx_fields_conv";
    sha256 = "0flrdyxdfcqcmdrbipxdjq0s3djdgs7z5pvjdycsvs6czbixz70v";
    propagatedBuildInputsOCaml = [ fieldslib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  variantslib = buildJanePackage {
    pname = "variantslib";
    sha256 = "1cclb5magk63gyqmkci8abhs05g2pyhyr60a2c1bvmig0faqcnsf";
    propagatedBuildInputsOCaml = [ base ppxlib ];
  };

  ppx_variants_conv = buildJanePackage {
    pname = "ppx_variants_conv";
    sha256 = "05j9bgra8xq6fcp12ch3z9vjrk139p2wrcjjcs4h52n5hhc8vzbz";
    propagatedBuildInputsOCaml = [ ppxlib ppx_deriving variantslib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_deriving variantslib ];
  };

  ppx_custom_printf = buildJanePackage {
    pname = "ppx_custom_printf";
    sha256 = "1z3dc8k0r34vkhg1mvw3c82fpjhlwq2cgyyqfrjlsmzn9wapgj97";
    propagatedBuildInputsOCaml = [ ppx_sexp_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_inline_test = buildJanePackage {
    pname = "ppx_inline_test";
    sha256 = "0nyz411zim94pzbxm2l2v2l9jishcxwvxhh142792g2s18r4vn50";
    propagatedBuildInputsOCaml = [ ppxlib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  bin_prot = buildJanePackage {
    pname = "bin_prot";
    sha256 = "0hh6s7g9s004z35hsr8z6nw5phlcvcd6g2q3bj4f0s1s0anlsswm";
    propagatedBuildInputsOCaml = [ ppx_compare ppx_custom_printf ppx_fields_conv ppx_variants_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_compare ppx_custom_printf ppx_fields_conv ppx_variants_conv ];
  };

  ppx_expect = buildJanePackage {
    pname = "ppx_expect";
    sha256 = "1wawsbjfkri4sw52n8xqrzihxc3xfpdicv3ahz83a1rsn4lb8j5q";
    propagatedBuildInputsOCaml = [ fieldslib ppx_compare ppx_inline_test ppx_sexp_conv ppx_assert ppx_custom_printf ppx_fields_conv ppx_here ppx_variants_conv re ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ fieldslib ppx_compare ppx_inline_test ppx_sexp_conv ppx_assert ppx_custom_printf ppx_fields_conv ppx_here ppx_variants_conv re ];
  };

  ppx_fail = buildJanePackage {
    pname = "ppx_fail";
    sha256 = "0krsv6z9gi0ifxmw5ss6gwn108qhywyhbs41an10x9d5zpgf4l1n";
    propagatedBuildInputsOCaml = [ ppxlib ppx_here ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ppx_here ];
  };

  ppx_let = buildJanePackage {
    pname = "ppx_let";
    sha256 = "146dmyzkbmafa3giz69gpxccvdihg19cvk4xsg8krbbmlkvdda22";
    propagatedBuildInputsOCaml = [ base ppxlib ];
  };

  ppx_optcomp = buildJanePackage {
    pname = "ppx_optcomp";
    sha256 = "0bdbx01kz0174g1szdhv3mcfqxqqf2frxq7hk13xaf6fsz04kwmj";
    propagatedBuildInputsOCaml = [ ppxlib ];
  };

  ppx_optional = buildJanePackage {
    pname = "ppx_optional";
    sha256 = "07i0iipbd5xw2bc604qkwlcxmhncfpm3xmrr6svyj2ij86pyssh8";
    propagatedBuildInputsOCaml = [ ppxlib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_pipebang = buildJanePackage {
    pname = "ppx_pipebang";
    sha256 = "1p4pdpl8h2bblbhpn5nk17ri4rxpz0aih0gffg3cl1186irkj0xj";
    propagatedBuildInputsOCaml = [ ppxlib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  ppx_sexp_value = buildJanePackage {
    pname = "ppx_sexp_value";
    sha256 = "1mg81834a6dx1x7x9zb9wc58438cabjjw08yhkx6i386hxfy891p";
    propagatedBuildInputsOCaml = [ ppx_here ppx_sexp_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppxlib ];
  };

  base_quickcheck = buildJanePackage {
    pname = "base_quickcheck";
    sha256 = "1la6qgq1zwmfyq1hqy6i337w435ym5yqgx2ygk86qip6nws0s6r3";
    propagatedBuildInputsOCaml = [ base splittable_random ppx_base ppx_let ppx_fields_conv ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_base ppx_fields_conv ppx_let ppx_sexp_message ];
  };

  # Other

  ppxlib = buildDunePackage rec {
    pname = "ppxlib";
    version = "0.6.0";
    src = fetchFromGitHub {
      owner = "ocaml-ppx";
      repo = pname;
      rev = version;
      sha256 = "0my9x7sxb329h0lzshppdaawiyfbaw6g5f41yiy7bhl071rnlvbv";
    };
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [
      ocaml-compiler-libs ocaml-migrate-parsetree ppx_derivers stdio base
    ];
    propagatedBuildInputsOCaml = [
      ocaml-compiler-libs ocaml-migrate-parsetree ppx_derivers stdio base
    ];
  };

  ocaml-migrate-parsetree = buildDunePackage rec {
    pname = "ocaml-migrate-parsetree";
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "ocaml-ppx";
      repo = pname;
      rev = "v${version}";
      sha256 = "16kas19iwm4afijv3yxd250s08absabmdcb4yj57wc8r4fmzv5dm";
    };
    propagatedBuildInputsOCaml = [ result ppx_derivers ];
  };

  re = buildDunePackage rec {
    pname = "re";
    version = "1.9.0";
    src = fetchurl {
      url = "https://github.com/ocaml/ocaml-re/archive/${version}.tar.gz";
      sha256 = "1hbpszfsglwz7ns4xxdwlrs3hxf6xvgmwsqx23pil38f4yxhh92a";
    };
    # buildInputs = [ ounit ];
  };

  ppx_derivers = buildDunePackage rec {
    pname = "ppx_derivers";
    version = "1.2.1";
    src = fetchFromGitHub {
      owner = "diml";
      repo = pname;
      rev = version;
      sha256 = "0yqvqw58hbx1a61wcpbnl9j30n495k23qmyy2xwczqs63mn2nkpn";
    };
  };

  octavius = buildDunePackage {
    pname = "octavius";
    version = "1.2.1";
    src = fetchurl {
      url = https://github.com/ocaml-doc/octavius/archive/v1.2.1.tar.gz;
      sha256 = "1zp1rjjwv880qswjm1jljlkq801k1pn89cs3y5qyvybdva7f0z2j";
    };
  };

  ppx_deriving = buildDunePackage rec {
    pname = "ppx_deriving";
    version = "HEAD";
    src = fetchFromGitHub {
      owner = "ocaml-ppx";
      repo = "ppx_deriving";
      rev = "f1857c2231280b1cb7fd682d57255a64319bb717";
      sha256 = "0hjcws966ysmklpyv81wjqsqzz413h9yqwbiam1l255ch246g9q0";
    };
    nativeBuildInputs = with buildPackagesOCaml; [ ppxfind cppo ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [
      ocaml-migrate-parsetree ppx_tools findlib
    ];
    propagatedBuildInputsOCaml = [
      ocaml-migrate-parsetree ppx_tools findlib
      ppx_derivers result
    ];
  };

  ppxfind = buildDunePackage rec {
    pname = "ppxfind";
    version = "1.2";
    src = fetchFromGitHub {
      owner = "diml";
      repo = pname;
      rev = version;
      sha256 = "1lzkrrywh2x5xpwdlxk5j0ywvqqpw8y1j3wr749qk0hg7wfp212j";
    };
    propagatedBuildInputsOCaml = [ ocaml-migrate-parsetree findlib ];
    # byte ld path doesn't include stdlib
    passthru.noCross = true;
  };

  dune = buildDunePackage rec {
    pname = "dune";
    # version = "1.9.2";
    # src = fetchurl {
    #   url = "https://github.com/ocaml/dune/releases/download/${version}/dune-${version}.tbz";
    #   sha256 = "0l27d13wh3i1450kgxnhr6r977sgby1dqwsfc8cqd9mqic1mr9f2";
    # };
    # postPatch = ''
    #   sed -i 's,threads.posix,,' src/dune
    # '';
    version = "HEAD";
    src = fetchFromGitHub {
      owner = "ocaml";
      repo = pname;
      rev = "d328f334e3f55287b1c374715b664b9766b21673";
      sha256 = "1awm36icgl080fdp004vcsx26bmlax6jvv3p2qmrsb83w55xvvmj";
    };
    propagatedNativeBuildInputsOCaml = lib.optionals (buildPlatform != hostPlatform) [ buildPackagesOCaml.dune ];
  };

  cppo = buildDunePackage rec {
    pname = "cppo";
    version = "1.6.5";
    src = fetchFromGitHub {
      owner = "mjambon";
      repo = pname;
      rev = "v${version}";
      sha256 = "03c0amszy28shinvz61hm340jz446zz5763a1pdqlza36kwcj0p0";
    };
  };

  easy-format = buildDunePackage rec {
    pname = "easy-format";
    version = "1.3.1";
    src = fetchFromGitHub {
      owner = "ocaml-community";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-ExOWeJpIztPI55uExrZSScOqqXQ9e3F8cBqtEiJj1kk=";
    };
  };

  biniou = buildDunePackage rec {
    pname = "biniou";
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "ocaml-community";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-izWUNQMli2uD7DAhDTXCFz/Z9qWVOsDlj2IJ7Dx/V1Y=";
    };
    propagatedBuildInputsOCaml = [ easy-format ];
  };

  yojson = buildDunePackage rec {
    pname = "yojson";
    version = "1.7.0";
    src = fetchFromGitHub {
      owner = "ocaml-community";
      repo = pname;
      rev = version;
      sha256 = "sha256-VvbBwQ9/SKhVupBL0x8lSDqIhIH2MLfdDXCutxDXzH4=";
    };
    nativeBuildInputs = with buildPackagesOCaml; [ cppo ];
    propagatedBuildInputsOCaml = [ easy-format biniou ];
  };

  hex = buildDunePackage rec {
    pname = "hex";
    version = "1.4.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "ocaml-hex";
      rev = "v${version}";
      sha256 = "sha256-GNhMTJbxew4MfQJ5hJwLAlOPFn7DSqLYnx54zlaEFjE=";
    };
    propagatedBuildInputsOCaml = [ cstruct bigarray-compat ];
  };

  # Mirage

  ipaddr = buildDunePackage rec {
    pname = "ipaddr";
    version = "4.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "ocaml-ipaddr";
      rev = "v${version}";
      sha256 = "1ywhabdji7hqrmr07dcxlsxf5zndagrdxx378csi5bv3c5n9547z";
    };
    propagatedBuildInputsOCaml = [ macaddr sexplib0 domain-name ];
  };

  macaddr = buildDunePackage rec {
    pname = "macaddr";
    version = "4.0.0";
    inherit (ipaddr) src;
    propagatedBuildInputsOCaml = [ sexplib0 ];
  };

  macaddr-cstruct = buildDunePackage rec {
    pname = "macaddr-cstruct";
    version = "4.0.0";
    inherit (ipaddr) src;
    propagatedBuildInputsOCaml = [ macaddr cstruct ];
  };

  cstruct = buildDunePackage rec {
    pname = "cstruct";
    version = "5.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "ocaml-${pname}";
      rev = "v${version}";
      sha256 = "1naky2dqaz1080dkcdkkk6bg8yl48ijvq9zis1pv5vr159di8yy8";
    };
    propagatedBuildInputsOCaml = [ bigarray-compat ];
  };

  mmap = buildDunePackage rec {
    pname = "mmap";
    version = "1.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "${pname}";
      rev = "v${version}";
      sha256 = "1jaismy5d1bhbbanysmr2k79px0yv6ya265dri3949nha1l23i60";
    };
  };

  lwt_ppx = buildDunePackage rec {
    pname = "lwt_ppx";
    inherit (lwt) version src;
    propagatedBuildInputsOCaml = [ lwt ppx_tools_versioned ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_tools_versioned ];
  };

  lwt = buildDunePackage rec {
    pname = "lwt";
    version = "4.2.0";
    src = fetchFromGitHub {
      owner = "ocsigen";
      repo = "${pname}";
      rev = "${version}";
      sha256 = "1lryb90y4887n99a4rw6d7r5338lxnsgqqx54a0936rx718pkmsw";
    };
    nativeBuildInputs = with buildPackagesOCaml; [ cppo ];
    propagatedBuildInputsOCaml = [ seq result mmap ];
    # HACK
    postPatch = lib.optionalString (hostPlatform.config == "aarch64-none-elf") ''
      sed -i s,IOV_MAX,1024, src/unix/unix_c/unix_iov_max.c
    '';
  };

  lwt-dllist = buildDunePackage rec {
    pname = "lwt-dllist";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "${pname}";
      rev = "v${version}";
      sha256 = "1ps97ja4q43jpsrwn1wv0yd9d8x4k175hxn31qcj6sgml0hgh17h";
    };
    propagatedBuildInputsOCaml = [ lwt ];
  };

  stdlib-shims = buildDunePackage rec {
    pname = "stdlib-shims";
    version = "0.1.0";
    src = fetchFromGitHub {
      owner = "ocaml";
      repo = pname;
      rev = version;
      sha256 = "007dwywsr5285z0np6a9nr0h8iqmyzfrlx6s5xaqcwj69zabsrjm";
    };
  };

  cmdliner = buildTopkgPackage rec {
    pname = "cmdliner";
    version = "1.0.3";
    src = fetchurl {
      url = "http://erratique.ch/software/${pname}/releases/${pname}-${version}.tbz";
      sha256 = "0g3w4hvc1cx9x2yp5aqn6m2rl8lf9x1dn754hfq8m1sc1102lxna";
    };
  };

  logs = buildTopkgPackage rec {
    pname = "logs";
    version = "0.6.3";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "0hx4x8m7aisgrkkn36pl8c40w6v300dn2qrc3nkxhqqdyh1l5ib5";
    };
    nativeBuildInputsOCaml = with buildPackagesOCaml; [ findlib ];
    propagatedBuildInputsOCaml = [ fmt lwt ];
    buildFlags = [
      "--with-js_of_ocaml" "false"
      "--with-fmt" "true"
      "--with-lwt" "true"
      "--with-cmdliner" "false"
      # "--with-base-threads" "false"
    ];
  };

  fmt = buildTopkgPackage rec {
    pname = "fmt";
    version = "0.8.6";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "1iydbidly831x0skkfqhgqv26hnaq4dcx546yikh6nlb5n0ivi20";
    };
    nativeBuildInputsOCaml = with buildPackagesOCaml; [ findlib ];
    propagatedBuildInputsOCaml = [ seq stdlib-shims ];
    buildFlags = [
      "--with-base-unix" "false"
      "--with-cmdliner" "false"
    ];
  };

  astring = buildTopkgPackage rec {
    pname = "astring";
    version = "0.8.3";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "00y2isx8fmbwc1ivfbgyg4xb9s07clfzkd0jmrp4ir7wihnq3zgw";
    };
  };

  fpath = buildTopkgPackage rec {
    pname = "fpath";
    version = "0.7.2";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "184kqij7dg57abyx662rlvkgddazfff89574rih3c4i3wiahyzxq";
    };
    propagatedBuildInputsOCaml = [ astring result ];
  };

  rresult = buildTopkgPackage rec {
    pname = "rresult";
    version = "0.6.0";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "1lfzacvnp9im9fa5d30wsn36rwgbpsqgk0vd258avanilsvwjmx8";
    };
    propagatedBuildInputsOCaml = [ result ];
  };

  bos = buildTopkgPackage rec {
    pname = "bos";
    version = "0.2.0";
    src = fetchFromGitHub {
      owner = "dbuenzli";
      repo = pname;
      rev = "v${version}";
      sha256 = "1g9h25wbh26fba5zi12i37mif7riikcmss4ajlmy2gazcyb3pfvl";
    };
    propagatedBuildInputsOCaml = [ rresult astring fpath fmt logs ];
  };

  ptime = buildTopkgPackage rec {
    pname = "ptime";
    version = "0.8.5";
    src = fetchurl {
      url = "http://erratique.ch/software/${pname}/releases/${pname}-${version}.tbz";
      sha256 = "1fxq57xy1ajzfdnvv5zfm7ap2nf49znw5f9gbi4kb9vds942ij27";
    };
    propagatedBuildInputsOCaml = [ result ];
    buildFlags = [
      "--with-js_of_ocaml" "false"
    ];
  };

  functoria = buildDunePackage rec {
    pname = "functoria";
    version = "2.2.3";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = version;
      sha256 = "1n5hs0idlj1rrm5k7v3ax4ygs7hszbpb15hnbs4xqdxn21p6qywz";
    };
    propagatedBuildInputsOCaml = [
      cmdliner rresult astring fmt ocamlgraph logs bos fpath ptime
    ];
    # because of ocamlgraph
    passthru.noCross = true;
  };

  functoria-runtime = buildDunePackage rec {
    pname = "functoria-runtime";
    inherit (functoria) version src;
    propagatedBuildInputsOCaml = [
      fmt cmdliner
    ];
  };

  duration = buildDunePackage rec {
    pname = "duration";
    version = "0.1.2";
    src = fetchFromGitHub {
      owner = "hannesm";
      repo = pname;
      rev = version;
      sha256 = "1hhw74wcwff2dzsxfvzr8d1f2nsmzybvqlkci5pm4im6kv2ykfpn";
    };
  };

  mirage-types = buildDunePackage rec {
    pname = "mirage-types";
    inherit (mirage) version src;
    propagatedBuildInputsOCaml = [
      mirage-device
      mirage-time
      mirage-clock
      mirage-random
      mirage-flow
      mirage-console
      mirage-protocols
      mirage-stack
      mirage-block
      mirage-net
      mirage-fs
      mirage-kv
      mirage-channel
    ];
  };

  mirage-runtime = buildDunePackage rec {
    pname = "mirage-runtime";
    inherit (mirage) version src;
    propagatedBuildInputsOCaml = [
      ipaddr functoria-runtime fmt logs
    ];
  };

  mirage = buildDunePackage rec {
    pname = "mirage";
    version = "3.5.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "mirage";
      rev = "v${version}";
      sha256 = "0iqsng2aaglnh8dd1mihr9bdj12wib9qgpxf9dkbk8i35qzbnh61";
    };
    patches = [
      ./patches/mirage-cross.patch
    ];
    propagatedBuildInputsOCaml = [
      ipaddr functoria bos astring logs mirage-runtime
    ];
    # because of ocamlgraph
    passthru.noCross = true;
  };

  bigarray-compat = buildDunePackage rec {
    pname = "bigarray-compat";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "06j1dwlpisxshdd0nab4n4x266gg1s1n8na16lpgw3fvcznwnimz";
    };
  };

  io-page = buildDunePackage rec {
    pname = "io-page";
    version = "2.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "io-page";
      rev = "v${version}";
      sha256 = "0dwd4g97fr4xgb4zpfzp1zxgmnvwx0dpccqbi307hgd8m1wy2v9b";
    };
    propagatedBuildInputsOCaml = [ cstruct bigarray-compat ];
  };

  io-page-unix = buildDunePackage rec {
    pname = "io-page-unix";
    inherit (io-page) version src;
    propagatedBuildInputsOCaml = [ io-page cstruct ];
    propagatedNativeBuildInputsOCaml = [ configurator ];
  };

  mirage-unix = buildDunePackage rec {
    pname = "mirage-unix";
    version = "3.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = version;
      sha256 = "17pc400sy3cxm6rkc7ywc13xan1ijsavalidlwvd5ivvcc5g9fqn";
    };
    propagatedBuildInputsOCaml = [ lwt logs io-page-unix ];
  };

  parse-argv = buildDunePackage rec {
    pname = "parse-argv";
    version = "0.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "16n18zik6vkfnhv8jaigr90fwp1ykg23p61aqchym0jil4i4yq01";
    };
    propagatedBuildInputsOCaml = [ astring ];
  };

  mirage-bootvar-unix = buildDunePackage rec {
    pname = "mirage-bootvar-unix";
    version = "0.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = version;
      sha256 = "1vi13q0z5ffv5hf4q5lfvkia6j2s5520px0s2x4dbjgd52icizrz";
    };
    propagatedBuildInputsOCaml = [ lwt parse-argv ];
  };

  # # #

  mirage-device = buildDunePackage rec {
    pname = "mirage-device";
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1dmj443db4ywc54ga2h6f3mnwfx7fpk8klh9l37iibq7k104qnrg";
    };
    propagatedBuildInputsOCaml = [ fmt ];
  };

  mirage-time = buildDunePackage rec {
    pname = "mirage-time";
    version = "1.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "06pnmrdlr3y9ph48lal7y31hnr2bhryclcvm79kvbhc8ikh971gx";
    };
    propagatedBuildInputsOCaml = [ mirage-device ];
  };

  mirage-clock = buildDunePackage rec {
    pname = "mirage-clock";
    version = "2.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "0cv8b7p1ca108nlva6pz6wjin9x1b7s44k7wnca0a3r03lw9dxy2";
    };
    propagatedBuildInputsOCaml = [ mirage-device ];
  };

  mirage-clock-lwt = buildDunePackage rec {
    pname = "mirage-clock-lwt";
    inherit (mirage-clock) version src;
    propagatedBuildInputsOCaml = [ lwt mirage-clock ];
  };

  mirage-clock-unix = buildDunePackage rec {
    pname = "mirage-clock-unix";
    inherit (mirage-clock) version src;
    propagatedBuildInputsOCaml = [ lwt mirage-clock mirage-clock-lwt dune ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ dune ];
  };

  mirage-clock-freestanding = buildDunePackage rec {
    pname = "mirage-clock-freestanding";
    inherit (mirage-clock) version src;
    propagatedBuildInputsOCaml = [ mirage-clock mirage-clock-lwt lwt ];
  };

  mirage-random = buildDunePackage rec {
    pname = "mirage-random";
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1xnw13n13z1n3d5r7sg5ym7i3ghj2s3sfq3rynd55siir8fj6dl4";
    };
    propagatedBuildInputsOCaml = [ cstruct ];
  };

  # mirage-random-stdlib = buildDunePackage rec {
  #   pname = "mirage-random-stdlib";
  #   version = "0.0.1";
  #   src = fetchFromGitHub {
  #     owner = "mirage";
  #     repo = pname;
  #     rev = version;
  #     sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  #   };
  #   propagatedBuildInputsOCaml = [
  #     lwt
  #     mirage-random
  #     mirage-entropy
  #   ];
  # };

  mirage-flow = buildDunePackage rec {
    pname = "mirage-flow";
    version = "1.6.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "03lr96nis4mx4ywdcjlnx7hj08kxxzi7d40fsyn9f6309ppirgqj";
    };
    propagatedBuildInputsOCaml = [ fmt ];
  };

  mirage-console = buildDunePackage rec {
    pname = "mirage-console";
    version = "2.4.2";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "090sq96nppi7f2akj8jf1rk4xdacj6zsgahchx9f0x620ndmzhvb";
    };
    propagatedBuildInputsOCaml = [ mirage-device mirage-flow ];
  };

  mirage-protocols = buildDunePackage rec {
    pname = "mirage-protocols";
    version = "3.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1bv6srcrgpfxzyvqm25w66xyiaxhqv20pdqwp2x39ili8cqgq12f";
    };
    propagatedBuildInputsOCaml = [ fmt mirage-device mirage-flow mirage-net duration ];
  };

  mirage-protocols-lwt = buildDunePackage rec {
    pname = "mirage-protocols-lwt";
    inherit (mirage-protocols) version src;
    propagatedBuildInputsOCaml = [ mirage-protocols ipaddr macaddr lwt cstruct ];
  };

  mirage-stack = buildDunePackage rec {
    pname = "mirage-stack";
    version = "1.4.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "0m1n6wsq0hqfbnlxv1b17alxlj8skww4x0zcj0k5qs811gznymdd";
    };
    propagatedBuildInputsOCaml = [ fmt mirage-device mirage-protocols ];
  };

  mirage-block = buildDunePackage rec {
    pname = "mirage-block";
    version = "1.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1h4zw6ap9yjg9hdknbhjlfszsvx13xgvswkjz6n0s4336cgvva50";
    };
    propagatedBuildInputsOCaml = [ mirage-device ];
  };

  mirage-net = buildDunePackage rec {
    pname = "mirage-net";
    version = "2.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "03yng7kh93lpgymv0gsf16m9a3z3vy0a65n1hw1435kaxi02qvjl";
    };
    propagatedBuildInputsOCaml = [ fmt mirage-device ];
  };

  mirage-fs = buildDunePackage rec {
    pname = "mirage-fs";
    version = "2.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "11cdhjrxk0mlpdgzb4hzqsyvsh2vcbhgd997iicbgzyigzwzz2gf";
    };
    propagatedBuildInputsOCaml = [ fmt mirage-device ];
  };

  mirage-kv = buildDunePackage rec {
    pname = "mirage-kv";
    version = "2.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "0b68yd8m085cqv2h76qsfz0xz6xl6ng7l7k2pbnxgi2qcd8zd0wc";
    };
    propagatedBuildInputsOCaml = [ fmt mirage-device ];
  };

  mirage-channel = buildDunePackage rec {
    pname = "mirage-channel";
    version = "3.2.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1h4fmidf6100gfcr3cxn441fq5hanmp6cqly4vsjpb74pqxl7hn8";
    };
    propagatedBuildInputsOCaml = [ mirage-flow ];
  };

  # # #

  ocplib-endian = buildDunePackage rec {
    pname = "ocplib-endian";
    version = "HEAD";
    src = fetchFromGitHub {
      owner = "dune-universe";
      repo = pname;
      rev = "dad1c2ac3c367e7eae33d7d4b805f53dcdb97919";
      sha256 = "1s4sbpyy1qbi6x0fhiqb1c37s2viz0i64zy3cx4wxzsz9q4zi5pr";
    };
    nativeBuildInputs = with buildPackagesOCaml; [ cppo ];
    propagatedBuildInputsOCaml = [ bigarray-compat ];
    patches = [
      ./patches/ocplib-endian.patch
    ];
  };

  ppx_tools_versioned = buildDunePackage rec {
    pname = "ppx_tools_versioned";
    version = "5.2.1";
    src = fetchFromGitHub {
      owner = "let-def";
      repo = pname;
      rev = version;
      sha256 = "1nwbcwh902h8948n877gba97fh7n3fr3kl2xama331nsrrp3lrkd";
    };
    propagatedBuildInputsOCaml = [ ocaml-migrate-parsetree ];
  };

  cstruct-sexp = buildDunePackage rec {
    pname = "cstruct-sexp";
    inherit (cstruct) version src;
    propagatedBuildInputsOCaml = [ sexplib cstruct ];
  };

  cstruct-unix = buildDunePackage rec {
    pname = "cstruct-unix";
    inherit (cstruct) version src;
    propagatedBuildInputsOCaml = [ cstruct ];
  };

  cstruct-lwt = buildDunePackage rec {
    pname = "cstruct-lwt";
    inherit (cstruct) version src;
    propagatedBuildInputsOCaml = [ cstruct lwt ];
  };

  ppx_cstruct = buildDunePackage rec {
    pname = "ppx_cstruct";
    inherit (cstruct) version src;
    propagatedBuildInputsOCaml = [ cstruct ppx_tools_versioned sexplib ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_tools_versioned ];
  };

  mirage-profile = buildDunePackage rec {
    pname = "mirage-profile";
    version = "0.8.2";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "mirage-profile";
      rev = "v${version}";
      sha256 = "1disv0kvpz0f2qnaqa0z1hrcvkfxpgh1j2hxp6nzqwi1q8q2aynj";
    };
    propagatedBuildInputsOCaml = [ cstruct ocplib-endian lwt ppx_cstruct ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_cstruct ];
  };

  mirage-logs = buildDunePackage rec {
    pname = "mirage-logs";
    version = "1.0.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "mirage-logs";
      rev = "v${version}";
      sha256 = "0rjdjxc9q70wjb5ki93rxzia2yhfj2ggzxq0w92yh72dnj4px2gp";
    };
    propagatedBuildInputsOCaml = [ logs ptime mirage-clock mirage-profile lwt ];
  };

  # # #

  mirage-types-lwt = buildDunePackage rec {
    pname = "mirage-types-lwt";
    inherit (mirage) version src;
    propagatedBuildInputsOCaml = [
      lwt
      cstruct
      ipaddr
      mirage-types
      mirage-clock-lwt
      mirage-time-lwt
      mirage-random
      mirage-flow-lwt
      mirage-protocols-lwt
      mirage-stack-lwt
      mirage-console-lwt
      mirage-block-lwt
      mirage-net-lwt
      mirage-fs-lwt
      mirage-kv-lwt
      mirage-channel-lwt
    ];
  };

  mirage-time-lwt = buildDunePackage rec {
    pname = "mirage-time-lwt";
    inherit (mirage-time) version src;
    propagatedBuildInputsOCaml = [ mirage-time lwt ];
  };

  mirage-flow-lwt = buildDunePackage rec {
    pname = "mirage-flow-lwt";
    inherit (mirage-flow) version src;
    propagatedBuildInputsOCaml = [ fmt lwt logs cstruct mirage-clock mirage-flow ];
  };

  mirage-stack-lwt = buildDunePackage rec {
    pname = "mirage-stack-lwt";
    inherit (mirage-stack) version src;
    propagatedBuildInputsOCaml = [ mirage-stack ipaddr lwt cstruct ];
  };

  mirage-console-lwt = buildDunePackage rec {
    pname = "mirage-console-lwt";
    inherit (mirage-console) version src;
    propagatedBuildInputsOCaml = [ mirage-console lwt cstruct ];
  };

  mirage-block-lwt = buildDunePackage rec {
    pname = "mirage-block-lwt";
    inherit (mirage-block) version src;
    propagatedBuildInputsOCaml = [ cstruct io-page lwt logs mirage-block ];
  };

  mirage-net-lwt = buildDunePackage rec {
    pname = "mirage-net-lwt";
    inherit (mirage-net) version src;
    propagatedBuildInputsOCaml = [ mirage-net lwt macaddr cstruct ];
  };

  mirage-fs-lwt = buildDunePackage rec {
    pname = "mirage-fs-lwt";
    inherit (mirage-fs) version src;
    propagatedBuildInputsOCaml = [ mirage-fs mirage-kv-lwt lwt cstruct cstruct-lwt ];
  };

  mirage-kv-lwt = buildDunePackage rec {
    pname = "mirage-kv-lwt";
    inherit (mirage-kv) version src;
    propagatedBuildInputsOCaml = [ mirage-kv lwt cstruct ];
  };

  mirage-channel-lwt = buildDunePackage rec {
    pname = "mirage-channel-lwt";
    inherit (mirage-channel) version src;
    propagatedBuildInputsOCaml = [ mirage-flow-lwt mirage-channel io-page lwt cstruct logs ];
  };

  # Xen

  shared-memory-ring = buildDunePackage rec {
    pname = "shared-memory-ring";
    version = "3.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1ja3pxrq8xzp0qbn0f5w8x40ms1kgjirxj7wda2ar5bs97biyc2p";
    };
    propagatedBuildInputsOCaml = [ cstruct mirage-profile ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_cstruct ];
  };

  shared-memory-ring-lwt = buildDunePackage rec {
    pname = "shared-memory-ring-lwt";
    inherit (shared-memory-ring) version src;
    propagatedBuildInputsOCaml = [ cstruct mirage-profile shared-memory-ring lwt lwt-dllist ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_cstruct ];
  };

  xenstore = buildDunePackage rec {
    pname = "xenstore";
    version = "2.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "ocaml-${pname}";
      rev = "${version}";
      sha256 = "13ib2i2rr6iznbz5ika8gga1caxf1iva6cxgpjapinv3mn33x0as";
    };
    propagatedBuildInputsOCaml = [ cstruct lwt ppx_cstruct ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_cstruct ];
  };

  xen-evtchn = buildDunePackage rec {
    pname = "xen-evtchn";
    version = "2.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "ocaml-evtchn";
      rev = "v${version}";
      sha256 = "01cq04xx26axv1bqmipd7qsy48fplpbf7vdjablfvf3d5h1mdjzp";
    };
    propagatedBuildInputsOCaml = [ lwt lwt-dllist cmdliner ];
  };

  mirage-xen = buildDunePackage rec {
    pname = "mirage-xen";
    version = "3.4.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "mirage-xen";
      rev = "v${version}";
      sha256 = "0hxnvpfzv4wgisnismsaqn51a8zf7h600jh4q08pp25pcg8df92m";
    };
    nativeBuildInputs = [
      pkgconfig
    ];
    buildInputs = [
      mirage-xen-ocaml
      mirage-xen-posix
      mirage-xen-minios
      minios-xen
    ];
    nativeBuildInputsOCaml = with buildPackagesOCaml; [
      dune
    ];
    propagatedBuildInputsOCaml = [
      cstruct
      lwt
      shared-memory-ring-lwt
      xenstore
      xen-evtchn
      lwt-dllist
      mirage-profile
      mirage-xen-ocaml
      io-page-xen
      mirage-xen-minios
      logs
      fmt
    ];
    postPatch = ''
      sed -i "s,../pkgconfig/mirage-xen.pc,pkgconfig/mirage-xen.pc," bindings/dune
    '';
    postInstall = ''
      mv $out/lib/mirage-xen/pkgconfig $out/lib/pkgconfig
    '';
    passthru.noCross = true; # by dep
  };

  io-page-xen = buildDunePackage rec {
    pname = "io-page-xen";
    inherit (io-page) version src;
    nativeBuildInputs = [
      pkgconfig
    ];
    buildInputs = [
      minios-xen mirage-xen-minios mirage-xen-ocaml mirage-xen-posix
    ];
    nativeBuildInputsOCaml = with buildPackagesOCaml; [ dune ];
    buildInputsOCaml = [ dune ];
    propagatedBuildInputsOCaml = [
      io-page
      cstruct
      mirage-xen-ocaml
    ];
    passthru.noCross = true; # by dep
  };

  mirage-bootvar-xen = buildDunePackage rec {
    pname = "mirage-bootvar-xen";
    version = "0.5.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "1bwk8r3cpdxwlhkham8srpsdv7mm1smpsxiawh9g5bsgvc8s9jch";
    };
    propagatedBuildInputsOCaml = [ mirage-xen lwt astring parse-argv ];
  };

  domain-name = buildDunePackage rec {
    pname = "domain-name";
    version = "0.3.0";
    src = fetchFromGitHub {
      owner = "hannesm";
      repo = "domain-name";
      rev = "v${version}";
      sha256 = "06l82k27wa446k0sd799i73rrqwwmqfm542blkx6bbm2xpxaz2cm";
    };
    propagatedBuildInputsOCaml = [
      fmt
      astring
    ];
  };

  ethernet = buildDunePackage rec {
    pname = "ethernet";
    version = "2.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = pname;
      rev = "v${version}";
      sha256 = "0fdgw8lmk8ffmy7vyqvfyj7b06cyfgd2an406jj4jq2kacngizyp";
    };
    propagatedBuildInputsOCaml = [ rresult cstruct ppx_cstruct mirage-net-lwt mirage-protocols-lwt macaddr mirage-profile fmt lwt logs ];
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ ppx_cstruct ];
  };

  arp = buildDunePackage rec {
    pname = "arp";
    version = "2.1.0";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "arp";
      rev = "v${version}";
      sha256 = "1qaxbi8rsajcn8y4q8fqc4k2lwwz57syvn9fppy5aizhaxx8nj8q";
    };
    propagatedBuildInputsOCaml = [
      cstruct
      ipaddr
      macaddr
      logs
    ];
  };

  arp-mirage = buildDunePackage rec {
    pname = "arp-mirage";
    inherit (arp) version src;
    propagatedBuildInputsOCaml = [
      mirage-time-lwt
      mirage-protocols-lwt
      lwt
      duration
      arp
      mirage-profile
      logs
      cstruct
    ];
  };

  randomconv = buildDunePackage rec {
    pname = "randomconv";
    version = "0.1.2";
    src = fetchFromGitHub {
      owner = "hannesm";
      repo = pname;
      rev = version;
      sha256 = "03x6njqx4n3xiiq8fzb775brhsqw733l7v4waqb016dmfc5pzav8";
    };
    propagatedBuildInputsOCaml = [ cstruct ];
  };

  psq = buildDunePackage rec {
    pname = "psq";
    version = "0.2.0";
    src = fetchFromGitHub {
      owner = "pqwy";
      repo = pname;
      rev = "v${version}";
      sha256 = "1cvib0z9ndh83mz9v2xymx8nzvhb9w1yvccp4nx3p8zqsgcnn7d8";
    };
    propagatedBuildInputsOCaml = [ seq ];
  };

  lru = buildDunePackage rec {
    pname = "lru";
    version = "0.3.0";
    src = fetchFromGitHub {
      owner = "pqwy";
      repo = pname;
      rev = "v${version}";
      sha256 = "1d14dyrph28pz0c11jv1pad69vr94f436rh5jk56vy99m07m2302";
    };
    propagatedBuildInputsOCaml = [ psq ];
  };

  tcpip = buildDunePackage rec {
    pname = "tcpip";
    version = "3.7.8";
    src = fetchFromGitHub {
      owner = "mirage";
      repo = "mirage-tcpip";
      rev = "v${version}";
      sha256 = "1x9ii8dxm6z846l539xf9p5biraafj34pgivhrrhq4jxqajxp2yc";
    };
    propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [
      dune
      ppx_cstruct
    ];
    propagatedBuildInputsOCaml = [
      dune
      rresult
      cstruct
      cstruct-lwt
      mirage-net-lwt
      mirage-clock
      mirage-random
      mirage-clock-lwt
      mirage-stack-lwt
      mirage-protocols
      mirage-protocols-lwt
      mirage-time-lwt
      ipaddr
      macaddr
      macaddr-cstruct
      mirage-profile
      fmt
      lwt
      lwt-dllist
      logs
      duration
      randomconv
      ethernet
      lru
    ];
  };

}
