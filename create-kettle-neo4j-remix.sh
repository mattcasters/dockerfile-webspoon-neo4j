#!/bin/bash

# set -ex

DEFAULT_DIST_DIR=/home/kettle/software
DEFAULT_PDI_REL=8.2.0.3
PDI_REL=$DEFAULT_PDI_REL
DEFAULT_REMIX_VERSION=$DEFAULT_PDI_REL
DEFAULT_BASE_REMIX_FILENAME="kettle-neo4j-remix"
DEFAULT_S3_BUCKET="s3://kettle-neo4j"
S3_BUCKET=$DEFAULT_S3_BUCKET
REMIX_VERSION=$DEFAULT_REMIX_VERSION
BASE_REMIX_FILENAME=$DEFAULT_BASE_REMIX_FILENAME
TMP_DIR_BASE=/tmp
TMP_DIR=$TMP_DIR_BASE/data-integration
PLUGINS_TO_DELETE_LIST="kettle-openerp-plugin kettle-shapefilereader-plugin kettle-version-checker kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin"

# Check if PDI_DIST_DIR env variable is set
if [ "$PDI_DIST_DIR" == "" ]; then
   echo "PDI_HOME environment variable is not set. Set to default"
   PDI_DIST_DIR=DEFAULT_SOFT_DIR
fi

# Build parameters' loop to be passed to PDI runner
for i in "$@"
do
    if [ "${i:0:7}" == "pdiRel:" ]; then
        PDI_REL=${i:7}
        REMIX_VERSION=$PDI_REL
    elif [ "${i:0:18}" == "remixFileBasename:" ]; then
        BASE_REMIX_FILENAME=${i:18}
    elif [ "${i:0:13}" == "s3BucketName:" ]; then
        S3_BUCKET="s3://"${i:13}
    fi

    COUNT=$(expr $COUNT + 1)
done
if [ "$PDI_REL" == "" ]; then
    echo "PDI_REL not given. Going with default settings!"
    REMIX_VERSION=$PDI_REL"-REMIX"
fi

REMIX_FILE=$BASE_REMIX_FILENAME"-"$REMIX_VERSION".zip"
BASE_PDI_ARCHIVE=$PDI_DIST_DIR"/pdi-ce-"$PDI_REL".zip"

if [ ! -f $BASE_PDI_ARCHIVE ]; then
  echo "Cannot find base PDI distro in -> $BASE_PDI_ARCHIVE"
  exit -1
fi

echo
echo "REMIX_FILE: $REMIX_FILE"
echo "BASE_PDI_ARCHIVE: $BASE_PDI_ARCHIVE"
echo "S3_BUCKET: $S3_BUCKET"
echo
echo --- Remix build start ---
echo Remix version : $REMIX_VERSION

if [ -d $TMP_DIR ]
then
  echo "Removing removing old version of $TMP_DIR"
  rm -rf $TMP_DIR
fi

# Unzip the BASE_FILE
#
echo Extracting base archive ${BASE_PDI_ARCHIVE}
unzip -q $BASE_PDI_ARCHIVE -d /tmp/

# Patch the kettle jars
#
#cp $SOFT_DIR/latest-patches/kettle-core-8.2.0.0-SNAPSHOT.jar $TMP_DIR/lib/kettle-core-8.2.0.0-342.jar
#cp $SOFT_DIR/latest-patches/kettle-dbdialog-8.2.0.0-SNAPSHOT.jar $TMP_DIR/lib/kettle-dbdialog-8.2.0.0-342.jar
#cp $SOFT_DIR/latest-patches/kettle-engine-8.2.0.0-SNAPSHOT.jar $TMP_DIR/lib/kettle-engine-8.2.0.0-342.jar
#cp $SOFT_DIR/latest-patches/kettle-ui-swt-8.2.0.0-SNAPSHOT.jar $TMP_DIR/lib/kettle-ui-swt-8.2.0.0-342.jar

# Get rid of a bunch of plugins...
#
for plugin in $PLUGINS_TO_DELETE_LIST
do
  echo Removing plugin ${plugin}
  rm -rf $TMP_DIR/plugins/${plugin}
done

cp getLatestSamples.sh $TMP_DIR_BASE
cp getLatestBase.sh $TMP_DIR_BASE
cp getLatestSpoonGit.sh $TMP_DIR_BASE

# get the latest samples
#
cd $TMP_DIR_BASE
./getLatestSamples.sh
unzip -q -o kettle-plugin-examples.zip -d $TMP_DIR
cd - > /dev/null

# Latest Azure plugins
#
./getLatestBase.sh mattcasters/kettle-azure-event-hubs kettle-azure-event-hubs
unzip -q -o $TMP_DIR_BASE/kettle-azure-event-hubs-latest.zip -d $TMP_DIR/plugins

# Latest Data Set plugins
#
./getLatestBase.sh mattcasters/pentaho-pdi-dataset pentaho-pdi-dataset
unzip -q -o $TMP_DIR_BASE/pentaho-pdi-dataset-latest.zip -d $TMP_DIR/plugins

# Latest Kettle debug plugin
#
./getLatestBase.sh mattcasters/kettle-debug-plugin kettle-debug-plugin
unzip -q -o $TMP_DIR_BASE/kettle-debug-plugin-latest.zip -d $TMP_DIR/plugins

# Latest Neo4j plugins
#
./getLatestBase.sh knowbi/knowbi-pentaho-pdi-neo4j-output Neo4JOutput
unzip -q -o $TMP_DIR_BASE/Neo4JOutput-latest.zip -d $TMP_DIR/plugins

# Latest Kettle Neo4j Logging plugin
#
./getLatestBase.sh mattcasters/kettle-neo4j-logging kettle-neo4j-logging
unzip -q -o $TMP_DIR_BASE/kettle-neo4j-logging-latest.zip -d $TMP_DIR/plugins

# Latest Kettle Metastore plugin
#
./getLatestBase.sh mattcasters/kettle-metastore kettle-metastore
unzip -q -o $TMP_DIR_BASE/kettle-metastore-latest.zip -d $TMP_DIR/plugins

# Latest needful things & install Maitre
#
./getLatestBase.sh mattcasters/kettle-needful-things kettle-needful-things
unzip -q -o $TMP_DIR_BASE/kettle-needful-things-latest.zip -d $TMP_DIR/plugins
cp $TMP_DIR/plugins/kettle-needful-things/Maitre.bat $TMP_DIR
cp $TMP_DIR/plugins/kettle-needful-things/maitre.sh $TMP_DIR
cp $TMP_DIR/plugins/kettle-needful-things/kettle-needful-things-*.jar $TMP_DIR/lib
cp $TMP_DIR/plugins/kettle-needful-things/lib/picocli-*.jar $TMP_DIR/lib

# GitSpoon!
#
./getLatestSpoonGit.sh 
unzip -q -o $TMP_DIR_BASE/pdi-git-plugin-latest.zip -d $TMP_DIR/plugins

# The Environment plugin
#
./getLatestBase.sh mattcasters/kettle-environment kettle-environment
unzip -q -o $TMP_DIR_BASE/kettle-environment-latest.zip -d $TMP_DIR/plugins

# Correct other writeable permissions
#
cd $TMP_DIR
chmod -R o-w *
echo file permissions fixed

# Now zip it back up...
#
echo Building remix archive ${REMIX_FILE}
cd $TMP_DIR_BASE
if [ -f "$REMIX_FILE" ]
then
  rm -f "$REMIX_FILE"
fi

zip -q -r "$REMIX_FILE" data-integration

#echo Uploading remix archive to s3://kettle-neo4j

s3cmd put "$REMIX_FILE" "$S3_BUCKET"/"$REMIX_FILE" --multipart-chunk-size-mb=4096
s3cmd setacl "$S3_BUCKET"/"$REMIX_FILE" --acl-public

cd -

echo --- Remix build done ---

