
set -x

FILE_BASE=kettle-plugin-examples
rm -rf ${FILE_BASE}

git clone git@github.com:neo4j-examples/kettle-plugin-examples.git

rm -f ${FILE_BASE}.zip
zip -r ${FILE_BASE}.zip kettle-plugin-examples -x *.git*

