{ buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "firectl";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "firecracker-microvm";
    repo = pname;
    rev = "b6c180cde765f6f4d0d3d9de148f0cba3f9e3f8b";
    sha256 = "0a81aviqw2dx36jv93i888x8q2jahj4w0nf1pyhf7mw4r5cn4x0v";
  };

  vendorSha256 = "sha256-6nTmUDfToQ19ezn4OZwXkCVGBIF7LazTZqbzfNcVvMY=";
}
