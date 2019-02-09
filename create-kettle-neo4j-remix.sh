#!/bin/bash

# Stop on error
#
set -e

# Log execution 
#
#set -ex

BUILD_TYPE=$1

SOFT_DIR=/home/kettle/software
KETTLE_BUILD=8.2.0.3-519
BASE_FILE=$SOFT_DIR/pdi-ce-${KETTLE_BUILD}.zip
REMIX_VERSION=${KETTLE_BUILD}-REMIX
TMP_DIR_BASE=/tmp
KETTLE_FOLDER=${TMP_DIR_BASE}/data-integration
PLUGINS_TO_DELETE_LIST="kettle-openerp-plugin kettle-shapefilereader-plugin kettle-version-checker kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin"
ENGINE_CONFIG_PATCH=$SOFT_DIR/pdi-engine-configuration-${KETTLE_BUILD}.zip
BEAM_PLUGIN_FILE=$SOFT_DIR/kettle-beam-0.3.0.zip

# Make sure the base release file exists
#
if [ ! -f "$BEAM_PLUGIN_FILE" ] 
then
  echo The base Kettle release file \"$BASE_FILE\" couldn\'t be found
  exit 1
fi

################################################################
# BEAM options
################################################################

if [ "$BUILD_TYPE" = "beam" ]
then
  REMIX_FILE=kettle-neo4j-remix-beam-${REMIX_VERSION}.zip

  # Make sure the beam plugin can be found
  #
  if [ ! -f "$BEAM_PLUGIN_FILE" ] 
  then
    echo The beam plugin file \"$BEAM_PLUGIN_FILE\" couldn\'t be found
    exit 1
  fi

  # Make sure the engine patch file exists
  #
  if [ ! -f "$ENGINE_CONFIG_PATCH" ] 
  then
    echo The engine configuration patch file \"$ENGINE_CONFIG_PATCH\" couldn\'t be found
    exit 1
  fi

################################################################
# BEAM options
################################################################

elif [ "$BUILD_TYPE" = "kettle" ]
then
  REMIX_FILE=kettle-neo4j-remix-${REMIX_VERSION}.zip
else
  echo Specify \"beam\" or \"kettle\" as build type
  exit
fi


################################################################
# Start the build
################################################################

echo Remix build start
echo Remix version : ${REMIX_VERSION}

if [ -d /tmp/data-integration ]
then
  rm -rf /tmp/data-integration
fi

# Unzip the BASE_FILE
#
echo Extracting base archive ${BASE_FILE}
unzip -q $BASE_FILE -d /tmp/

# Get rid of a bunch of plugins...
#
for plugin in ${PLUGINS_TO_DELETE_LIST}
do
  echo Removing plugin ${plugin}
  rm -rf $KETTLE_FOLDER/plugins/${plugin}
done

# Beam options
#
if [ "$BUILD_TYPE" = "beam" ]
then

  # Install the Kettle Beam plugin
  #
  unzip -q -o $BEAM_PLUGIN_FILE -d $KETTLE_FOLDER/plugins
  echo Installed $BEAM_PLUGIN_FILE

  # Patch the run configuration
  #
  unzip -q -o $ENGINE_CONFIG_PATCH -d $KETTLE_FOLDER
  echo Patched to add the Beam Run Configuration
fi

cp getLatestSamples.sh $TMP_DIR_BASE
cp getLatestBase.sh $TMP_DIR_BASE
cp getLatestSpoonGit.sh $TMP_DIR_BASE

# get the latest samples
#
cd $TMP_DIR_BASE
./getLatestSamples.sh
unzip -q -o kettle-plugin-examples.zip -d $KETTLE_FOLDER
cd - > /dev/null

# Latest Azure plugins
#
./getLatestBase.sh mattcasters/kettle-azure-event-hubs kettle-azure-event-hubs
unzip -q -o $TMP_DIR_BASE/kettle-azure-event-hubs-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Data Set plugins
#
./getLatestBase.sh mattcasters/pentaho-pdi-dataset pentaho-pdi-dataset
unzip -q -o $TMP_DIR_BASE/pentaho-pdi-dataset-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle debug plugin
#
./getLatestBase.sh mattcasters/kettle-debug-plugin kettle-debug-plugin
unzip -q -o $TMP_DIR_BASE/kettle-debug-plugin-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Neo4j plugins
#
./getLatestBase.sh knowbi/knowbi-pentaho-pdi-neo4j-output Neo4JOutput
unzip -q -o $TMP_DIR_BASE/Neo4JOutput-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle Neo4j Logging plugin
#
./getLatestBase.sh mattcasters/kettle-neo4j-logging kettle-neo4j-logging
unzip -q -o $TMP_DIR_BASE/kettle-neo4j-logging-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle Metastore plugin
#
./getLatestBase.sh mattcasters/kettle-metastore kettle-metastore
unzip -q -o $TMP_DIR_BASE/kettle-metastore-latest.zip -d $KETTLE_FOLDER/plugins

# Latest needful things & install Maitre
#
./getLatestBase.sh mattcasters/kettle-needful-things kettle-needful-things
unzip -q -o $TMP_DIR_BASE/kettle-needful-things-latest.zip -d $KETTLE_FOLDER/plugins
cp $KETTLE_FOLDER/plugins/kettle-needful-things/Maitre.bat $KETTLE_FOLDER
cp $KETTLE_FOLDER/plugins/kettle-needful-things/maitre.sh $KETTLE_FOLDER
cp $KETTLE_FOLDER/plugins/kettle-needful-things/kettle-needful-things-*.jar $KETTLE_FOLDER/lib
cp $KETTLE_FOLDER/plugins/kettle-needful-things/lib/picocli-*.jar $KETTLE_FOLDER/lib

# GitSpoon!
#
./getLatestSpoonGit.sh 
unzip -q -o $TMP_DIR_BASE/pdi-git-plugin-latest.zip -d $KETTLE_FOLDER/plugins

# The Environment plugin
#
./getLatestBase.sh mattcasters/kettle-environment kettle-environment
unzip -q -o $TMP_DIR_BASE/kettle-environment-latest.zip -d $KETTLE_FOLDER/plugins

# The Load Text From File plugin
#
./getLatestBase.sh mattcasters/load-text-from-file-plugin load-text-from-file-plugin
unzip -q -o $TMP_DIR_BASE/load-text-from-file-plugin-latest.zip -d $KETTLE_FOLDER/plugins

################################################################
# Packaging
################################################################

# Correct other writeable permissions
#
cd $KETTLE_FOLDER
chmod -R o-w *
chmod 770 ../data-integration
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

################################################################
# Upload to AWS
################################################################

echo Uploading remix archive to s3://kettle-neo4j

s3cmd put "$REMIX_FILE" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_FILE" --acl-public

cd -

echo Remix build done

