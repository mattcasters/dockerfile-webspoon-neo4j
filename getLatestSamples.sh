
FILE_BASE=kettle-plugin-examples
rm -rf ${FILE_BASE}

git clone git@github.com:neo4j-examples/kettle-plugin-examples.git 2> kettle-plugin-examples-git.log

if [ -f ${FILE_BASE}.zip ]
then
  rm -f ${FILE_BASE}.zip
fi

if [ -d ~/software/samples ]
then
  ( cd ~/software/ && zip -q -r - samples ) > ${FILE_BASE}.zip
  echo Added Kettle samples
fi

zip -q -u -r ${FILE_BASE}.zip kettle-plugin-examples -x *.git*
echo Added kettle-plugin-examples github project

