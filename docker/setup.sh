set -e

if [ ! -f /nix/.installed ]; then
    echo "Installing Nix..."
    curl -L https://raw.githubusercontent.com/nspin/minimally-invasive-nix-installer/dist/install.sh -o install-nix.sh
    echo "ebad4f63eb3df7807e249cc3e3883f6d38e28303983f9892dde71f944c0a3558 install-nix.sh" | sha256sum -c -
    bash install-nix.sh
    rm install-nix.sh
    touch /nix/.installed
    echo "Done"
fi
