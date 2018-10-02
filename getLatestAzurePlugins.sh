
cd /tmp

PROJECT=mattcasters/kettle-azure-event-hubs
FILE_BASE=kettle-azure-event-hubs

VERSION=$( curl --silent "https://api.github.com/repos/$PROJECT/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )
ZIP=https://github.com/${PROJECT}/releases/download/$VERSION/${FILE_BASE}-${VERSION}.zip

curl --silent $ZIP -L -O

rm -f ${FILE_BASE}-latest.zip
mv ${FILE_BASE}-${VERSION}.zip ${FILE_BASE}-latest.zip
