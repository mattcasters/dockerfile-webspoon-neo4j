
# set -ex

BASE_FILE=~/software/pdi-ce-8.1.0.0-365.zip
REMIX_VERSION=8.1.0.4
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

# get the latest samples
#
cp getLatestSamples.sh $TMP
cd $TMP
./getLatestSamples.sh
unzip -q kettle-plugin-examples.zip -d $FOLDER
cd - > /dev/null

# Latest Azure plugins
#
./getLatestAzurePlugins.sh
unzip -q $TMP/kettle-azure-event-hubs-latest.zip -d $FOLDER/plugins

# Latest Data Set plugins
#
./getLatestDataSetPlugin.sh
unzip -q $TMP/pentaho-pdi-dataset-latest.zip -d $FOLDER/plugins

# Latest Kettle debug plugin
#
./getLatestKettleDebugPlugin.sh
unzip -q $TMP/kettle-debug-plugin-latest.zip -d $FOLDER/plugins

# Latest Neo4j plugins
#
./getLatestNeo4jPlugins.sh
unzip -q $TMP/Neo4jOutput-latest.zip -d $FOLDER/plugins


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

