
set -ex

BASE_FILE=~/software/pdi-ce-8.1.0.0-365.zip
REMIX_VERSION=8.1.0.4-REMIX
REMIX_FILE=kettle-neo4j-remix-$REMIX_VERSION.zip
SOFT_DIR=~/software
TMP=/tmp
FOLDER=$TMP/data-integration

echo Remix version : $REMIX_VERSION

if [ -d /tmp/data-integration ]
then
  rm -rf /tmp/data-integration
fi

# Unzip the BASE_FILE
#
unzip -q $BASE_FILE -d /tmp/

# Patch the kettle jars
#
cp $SOFT_DIR/latest-patches/kettle-core-8.1.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-core-8.1.0.0-365.jar
cp $SOFT_DIR/latest-patches/kettle-dbdialog-8.1.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-dbdialog-8.1.0.0-365.jar
cp $SOFT_DIR/latest-patches/kettle-engine-8.1.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-engine-8.1.0.0-365.jar
cp $SOFT_DIR/latest-patches/kettle-ui-swt-8.1.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-ui-swt-8.1.0.0-365.jar

cp getLatestSamples.sh $TMP
cp getLatestBase.sh $TMP

# get the latest samples
#
cd $TMP
./getLatestSamples.sh
unzip -q -o kettle-plugin-examples.zip -d $FOLDER
cd - > /dev/null

# Latest Azure plugins
#
./getLatestBase.sh mattcasters/kettle-azure-event-hubs kettle-azure-event-hubs
unzip -q -o $TMP/kettle-azure-event-hubs-latest.zip -d $FOLDER/plugins

# Latest Data Set plugins
#
./getLatestBase.sh mattcasters/pentaho-pdi-dataset pentaho-pdi-dataset
unzip -q -o $TMP/pentaho-pdi-dataset-latest.zip -d $FOLDER/plugins

# Latest Kettle debug plugin
#
./getLatestBase.sh mattcasters/kettle-debug-plugin kettle-debug-plugin
unzip -q -o $TMP/kettle-debug-plugin-latest.zip -d $FOLDER/plugins

# Latest Neo4j plugins
#
./getLatestBase.sh knowbi/knowbi-pentaho-pdi-neo4j-output Neo4JOutput
unzip -q -o $TMP/Neo4JOutput-latest.zip -d $FOLDER/plugins

# Latest Kettle Neo4j Logging plugin
#
./getLatestBase.sh mattcasters/kettle-neo4j-logging kettle-neo4j-logging
unzip -q -o $TMP/kettle-neo4j-logging-latest.zip -d $FOLDER/plugins

# Latest needful things & install Maitre
#
./getLatestBase.sh mattcasters/kettle-needful-things kettle-needful-things
unzip -q -o $TMP/kettle-needful-things-latest.zip -d $FOLDER/plugins
cp $FOLDER/plugins/kettle-needful-things/Maitre.bat $FOLDER
cp $FOLDER/plugins/kettle-needful-things/maitre.sh $FOLDER
cp $FOLDER/plugins/kettle-needful-things/kettle-needful-things-*.jar $FOLDER/lib
cp $FOLDER/plugins/kettle-needful-things/lib/picocli-*.jar $FOLDER/lib

# The Environment plugin
#
./getLatestBase.sh mattcasters/kettle-environment kettle-environment
unzip -q -o $TMP/kettle-environment-latest.zip -d $FOLDER/plugins

# Now zip it back up...
#
cd $TMP
if [ -f "$REMIX_FILE" ]
then
  rm -f "$REMIX_FILE"
fi

zip -q -r "$REMIX_FILE" data-integration

s3cmd put "$REMIX_FILE" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_FILE" --acl-public

cd -

