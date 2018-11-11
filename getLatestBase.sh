
set -ex

cd /tmp

PROJECT=$1
FILE_BASE=$2

VERSION=$( curl --silent "https://api.github.com/repos/$PROJECT/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
ZIP=https://github.com/${PROJECT}/releases/download/$VERSION/${FILE_BASE}-${VERSION}.zip

echo $PROJECT version $VERSION

curl --silent $ZIP -L -O

rm -f ${FILE_BASE}-latest.zip
mv ${FILE_BASE}-${VERSION}.zip ${FILE_BASE}-latest.zip

