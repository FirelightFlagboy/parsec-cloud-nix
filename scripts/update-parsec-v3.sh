set -eu -o pipefail

# Allow the user to overwrite `SCRIPTDIR` by exporting it beforehand.
SCRIPTDIR=${SCRIPTDIR:=$(dirname "$(realpath -s "$0")")}
# Allow the user to overwrite `ROOTDIR` by exporting it beforehand.
ROOTDIR=${ROOTDIR:=$(realpath -s "$SCRIPTDIR/..")}
UPDATE_MODE=${1:-stable}

nix run nixpkgs#nix-update -- --flake --version="$UPDATE_MODE" parsec-cloud.v3.src
URL=$(nix eval .#parsec-cloud.v3.src.src.url --raw)

function fail {
    local lc="$BASH_COMMAND" previous_rc=$?

    echo "An error occurred in the update script."
    echo "The following command exited with $previous_rc:"
    echo "$lc"
}

trap "fail" ERR

nix run nixpkgs#nix-update -- --flake --no-src --url="$URL" parsec-cloud.v3.client
nix run nixpkgs#nix-update -- --flake --no-src --url="$URL" parsec-cloud.v3.cli
