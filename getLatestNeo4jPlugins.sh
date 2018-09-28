
cd /tmp/

PROJECT=knowbi/knowbi-pentaho-pdi-neo4j-output
VERSION=$( curl --silent "https://api.github.com/repos/$PROJECT/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' )

ZIP=https://github.com/knowbi/knowbi-pentaho-pdi-neo4j-output/releases/download/$VERSION/Neo4JOutput-${VERSION}.zip

curl --silent $ZIP -L -O

rm -f Neo4jOutput-latest.zip
mv Neo4JOutput-${VERSION}.zip Neo4jOutput-latest.zip
