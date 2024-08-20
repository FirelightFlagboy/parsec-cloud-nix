set -eu


# Allow the user to overwrite `SCRIPTDIR` by exporting it beforehand.
SCRIPTDIR=${SCRIPTDIR:=$(dirname "$(realpath -s "$0")")}
# Allow the user to overwrite `ROOTDIR` by exporting it beforehand.
ROOTDIR=${ROOTDIR:=$(realpath -s "$SCRIPTDIR/..")}

OWNER=Scille
REPO=parsec-cloud

TAG=${1:?Missing release tag}
VERSION=${TAG#v} # Remove the leading 'v'

if [ -z "$TMP_DIR" ]; then
    echo "No TMP_DIR set, creating a temporary directory that will be removed on exit."
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT
fi

mkdir -p $TMP_DIR
cd $TMP_DIR

! [ -d $TMP_DIR/parsec-cloud ] && git clone https://github.com/$OWNER/$REPO.git --branch ${TAG} --depth 1

COMMIT_REV=$(git -C parsec-cloud rev-parse HEAD)

COMMIT_ARCHIVE_SHA256=$(nix-prefetch-url --unpack https://github.com/$OWNER/$REPO/archive/$COMMIT_REV.tar.gz)
CLIENT_NPM_DEPS_HASH=$(prefetch-npm-deps $TMP_DIR/parsec-cloud/client/package-lock.json)
ELECTRON_NPM_DEPS_HASH=$(prefetch-npm-deps $TMP_DIR/parsec-cloud/client/electron/package-lock.json)

sed -i \
    -e "68s/version = \".*\";/version = \"${VERSION}\";/" \
    -e "71s/commit_rev = \".*\";/commit_rev = \"${COMMIT_REV}\";/" \
    -e "73s/commit_sha256 = \".*\";/commit_sha256 = \"${COMMIT_ARCHIVE_SHA256}\";/" \
    $ROOTDIR/flake.nix

sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${CLIENT_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/native-build.nix

sed -i \
    -e "s;npmDepsHash = \".*\";npmDepsHash = \"${ELECTRON_NPM_DEPS_HASH}\";" \
    $ROOTDIR/packages/v3/electron-app.nix
