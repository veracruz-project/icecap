{ icecapSrc }:

{

  dlmalloc = icecapSrc.repo {
    repo = "rust-dlmalloc";
    rev = "f6759cfed44dc4135eaa43c8c26599357749af39"; # branch: icecap
  };

  libc = icecapSrc.repo {
    repo = "rust-libc";
    rev = "bcb2c71ab1377db89ca6bca3e234b8f9ea20c012"; # branch: icecap
  };

}
