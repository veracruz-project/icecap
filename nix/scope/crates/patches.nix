{ icecapSrc }:

let
  mk = { repo, rev, cacheTag, dotGitSha256 }: rec {
    src = icecapSrc.repo {
      inherit repo rev;
    };
    inherit cacheTag dotGitSha256;
    dep = {
      git = src.hack.url;
      rev = src.hack.rev;
    };
  };

in
{

  dlmalloc = mk {
    repo = "rust-dlmalloc";
    rev = "f6759cfed44dc4135eaa43c8c26599357749af39"; # branch: icecap
    cacheTag = "rust-dlmalloc-e8402a3cfb2bf152";
    dotGitSha256 = "sha256-0K4E9XqmQV4J0UaHEarLf4pOHvOhg6vxTlZeleRTlBo=";
  };

  libc = mk {
    repo = "rust-libc";
    rev = "bcb2c71ab1377db89ca6bca3e234b8f9ea20c012"; # branch: icecap
    cacheTag = "rust-libc-TODO";
    dotGitSha256 = "sha256-za7Yge2pulv7UXKZUNTZF3i5044pDaDGoPfb06lJ2jo=";
  };

}
