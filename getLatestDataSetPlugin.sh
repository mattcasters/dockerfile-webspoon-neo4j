
cd /tmp

PROJECT=mattcasters/pentaho-pdi-dataset
FILE_BASE=pentaho-pdi-dataset

VERSION=$( curl --silent "https://api.github.com/repos/$PROJECT/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
ZIP=https://github.com/${PROJECT}/releases/download/$VERSION/${FILE_BASE}-${VERSION}.zip

curl --silent $ZIP -L -O

rm -f ${FILE_BASE}-latest.zip
mv ${FILE_BASE}-${VERSION}.zip ${FILE_BASE}-latest.zip
