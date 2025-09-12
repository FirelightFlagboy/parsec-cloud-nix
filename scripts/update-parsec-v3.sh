set -eu -o pipefail


# Allow the user to overwrite `SCRIPTDIR` by exporting it beforehand.
SCRIPTDIR=${SCRIPTDIR:=$(dirname "$(realpath -s "$0")")}
# Allow the user to overwrite `ROOTDIR` by exporting it beforehand.
ROOTDIR=${ROOTDIR:=$(realpath -s "$SCRIPTDIR/..")}

OWNER=Scille
REPO=parsec-cloud

TAG=${1:?Missing release tag}
VERSION=${TAG#v} # Remove the leading 'v'

declare -a TMP_FILES
function cleanup {
    rm -rf ${TMP_FILES[@]}
}
trap "cleanup" EXIT

function fail {
    local lc="$BASH_COMMAND" previous_rc=$?

    echo "An error occurred in the update script."
    echo "The following command exited with $previous_rc:"
    echo "$lc"
}

trap "fail" ERR

if [ -z "${TMP_DIR:-}" ]; then
    echo "No TMP_DIR set, creating a temporary directory that will be removed on exit."
    TMP_DIR=$(mktemp -d)
    TMP_FILES+=("$TMP_DIR")
fi

mkdir -p $TMP_DIR

! [ -d $TMP_DIR/parsec-cloud ] && git clone https://github.com/$OWNER/$REPO.git --branch ${TAG} --depth 1 $TMP_DIR/parsec-cloud

COMMIT_REV=$(git -C $TMP_DIR/parsec-cloud rev-parse HEAD)

COMMIT_ARCHIVE_SHA256=$(nix-prefetch-url --unpack https://github.com/$OWNER/$REPO/archive/$COMMIT_REV.tar.gz)

PATCH_CMD="patch --strip=1 --input $ROOTDIR/packages/v3/patches/use-cdn-instead-of-vendored-xlsx.patch --dir $TMP_DIR/parsec-cloud"

# Check if patch is already applied by trying to revert it
if ! $PATCH_CMD --force --dry-run --reverse; then
    echo "Applying patch"
    $PATCH_CMD
else
    echo "Patch already applied"
fi

CLIENT_NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps $TMP_DIR/parsec-cloud/client/package-lock.json)
ELECTRON_NPM_DEPS_HASH=$(nix run nixpkgs#prefetch-npm-deps $TMP_DIR/parsec-cloud/client/electron/package-lock.json)

TMP_FILES+=("$ROOTDIR/flake.nix.tmp")
echo "Updating version & commit revision in flake file"
sed \
    -e "54{s/version = \".*\";/version = \"${VERSION}\";/;t ok; q 1;:ok}" \
    -e "57{s/commit_rev = \".*\";/commit_rev = \"${COMMIT_REV}\";/;t ok; q 1;:ok}" \
    -e "59{s/commit_sha256 = \".*\";/commit_sha256 = \"${COMMIT_ARCHIVE_SHA256}\";/;t ok; q 1;:ok}" \
    $ROOTDIR/flake.nix > $ROOTDIR/flake.nix.tmp

mv $ROOTDIR/flake.nix.tmp $ROOTDIR/flake.nix

echo "Updating Npm dependencies hash"
sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${CLIENT_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/native-build.nix

sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${ELECTRON_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/electron-app.nix

if [ "$(git status --porcelain | grep -e flake.nix -e packages/v3/native-build.nix -e packages/v3/electron-app.nix --count)" -ne 3 ]; then
    echo "Invalid number of file changes, a 'sed' command has failed"
    exit 1
fi
