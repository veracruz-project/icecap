set -eu

arch="$(uname -m)"
version=dlp5yb3c19
script_name="install-${arch}-linux.sh"
url="https://github.com/nspin/minimally-invasive-nix-installer/raw/dist-${version}/dist/${script_name}"

case "$arch" in
    x86_64)
        sha256=051153e5e106744ced7be1d80e176d7e225aba3ed9340a36242777d88c809ff7
        ;;
    aarch64)
        sha256=af9eebd54eb2a2eb552e774e2698d33f8e9e5dfde112153f0066e8e87278f9cf
        ;;
    *)
        echo >&2 "unsupported architecture: '$arch'"
        exit 1
        ;;
esac

curl -L "$url" -o "$script_name"
echo "$sha256 $script_name" | sha256sum -c -
bash "$script_name"
rm "$script_name"
