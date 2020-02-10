
# set -ex

# https://github.com/HiromuHota/pdi-git-plugin/releases/download/1.0.0/pdi-git-plugin-1.0.0-jar-with-dependencies.zip
# https://github.com/HiromuHota/pdi-git-plugin/releases/download/nightly/pdi-git-plugin-1.0.2-SNAPSHOT-jar-with-dependencies.zip
# https://github.com/HiromuHota/pdi-git-plugin/releases/download/nightly/pdi-git-plugin-1.1.0-SNAPSHOT-jar-with-dependencies.zip
# https://github.com/HiromuHota/pdi-git-plugin/releases/download/nightly/pdi-git-plugin-1.1.0-SNAPSHOT-jar-with-dependencies.zip
# https://github.com/HiromuHota/pdi-git-plugin/releases/download/1.1.0/pdi-git-plugin-1.1.0-jar-with-dependencies.zip

cd /tmp

PROJECT=HiromuHota/pdi-git-plugin
FILE_BASE=pdi-git-plugin

ZIP="https://github.com/HiromuHota/pdi-git-plugin/releases/download/1.1.0/pdi-git-plugin-1.1.0-jar-with-dependencies.zip"
FILE=pdi-git-plugin-1.1.0-jar-with-dependencies.zip

echo $PROJECT version 1.1.0

curl --silent $ZIP -L -O

rm -f ${FILE_BASE}-latest.zip
mv ${FILE} ${FILE_BASE}-latest.zip

