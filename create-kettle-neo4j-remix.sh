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
PLUGINS_TO_DELETE_LIST="kettle-openerp-plugin kettle-shapefilereader-plugin kettle-version-checker kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin kettle-palo-plugin platform-utils-plugin"
ENGINE_CONFIG_PATCH=$SOFT_DIR/pdi-engine-configuration-${KETTLE_BUILD}.zip
BEAM_PLUGIN_FILE=$SOFT_DIR/kettle-beam-0.6.0.zip

# Make sure the base release file exists
#
if [ ! -f "$BEAM_PLUGIN_FILE" ] 
then
  echo The base Kettle release file \"$BASE_FILE\" couldn\'t be found
  exit 1
fi

if [ "$BUILD_TYPE" = "beam" ]
then

################################################################
# BEAM options
################################################################

  REMIX_ZIP=kettle-neo4j-remix-beam-${REMIX_VERSION}.zip
  REMIX_TGZ=kettle-neo4j-remix-beam-${REMIX_VERSION}.tgz
  REMIX_LOG=kettle-neo4j-remix-beam-${REMIX_VERSION}.log

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
# Kettle options
################################################################

elif [ "$BUILD_TYPE" = "kettle" ]
then
  REMIX_ZIP=kettle-neo4j-remix-${REMIX_VERSION}.zip
  REMIX_TGZ=kettle-neo4j-remix-${REMIX_VERSION}.tgz
  REMIX_LOG=kettle-neo4j-remix-${REMIX_VERSION}.log
else
  echo Specify \"beam\" or \"kettle\" as build type
  exit
fi

LOGFILE=${TMP_DIR_BASE}/${REMIX_LOG}
> $LOGFILE

################################################################
# Start the build
################################################################

echo Remix build start >> ${LOGFILE}
echo Remix version : ${REMIX_VERSION} >> ${LOGFILE}
echo Remix date    : $(date '+%F %H:%M:%S') >> ${LOGFILE}

if [ -d /tmp/data-integration ]
then
  rm -rf /tmp/data-integration
fi

# Unzip the BASE_FILE
#
echo Extracting base archive ${BASE_FILE} >> ${LOGFILE}
unzip -q $BASE_FILE -d /tmp/

# Get rid of a bunch of plugins...
#
for plugin in ${PLUGINS_TO_DELETE_LIST}
do
  echo Removing plugin ${plugin} >> ${LOGFILE}
  rm -rf $KETTLE_FOLDER/plugins/${plugin}
done

# Beam options
#
if [ "$BUILD_TYPE" = "beam" ]
then

  # Install the Kettle Beam plugin
  #
  unzip -q -o $BEAM_PLUGIN_FILE -d $KETTLE_FOLDER/plugins
  echo Installed $BEAM_PLUGIN_FILE >> ${LOGFILE}

  # Patch the run configuration
  #
  unzip -q -o $ENGINE_CONFIG_PATCH -d $KETTLE_FOLDER
  echo Patched to add the Beam Run Configuration >> ${LOGFILE}
fi

cp getLatestSamples.sh $TMP_DIR_BASE
cp getLatestBase.sh $TMP_DIR_BASE
cp getLatestSpoonGit.sh $TMP_DIR_BASE

# get the latest samples
#
cd $TMP_DIR_BASE
./getLatestSamples.sh >> ${LOGFILE}
unzip -q -o kettle-plugin-examples.zip -d $KETTLE_FOLDER
cd - > /dev/null

# Latest Azure plugins
#
./getLatestBase.sh mattcasters/kettle-azure-event-hubs kettle-azure-event-hubs >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-azure-event-hubs-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Data Set plugins
#
./getLatestBase.sh mattcasters/pentaho-pdi-dataset pentaho-pdi-dataset >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/pentaho-pdi-dataset-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle debug plugin
#
./getLatestBase.sh mattcasters/kettle-debug-plugin kettle-debug-plugin >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-debug-plugin-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Neo4j plugins
#
./getLatestBase.sh knowbi/knowbi-pentaho-pdi-neo4j-output Neo4JOutput >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/Neo4JOutput-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle Neo4j Logging plugin
#
./getLatestBase.sh mattcasters/kettle-neo4j-logging kettle-neo4j-logging >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-neo4j-logging-latest.zip -d $KETTLE_FOLDER/plugins

# Latest Kettle Metastore plugin
#
./getLatestBase.sh mattcasters/kettle-metastore kettle-metastore >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-metastore-latest.zip -d $KETTLE_FOLDER/plugins

# Latest needful things & install Maitre
#
./getLatestBase.sh mattcasters/kettle-needful-things kettle-needful-things >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-needful-things-latest.zip -d $KETTLE_FOLDER/plugins
cp $KETTLE_FOLDER/plugins/kettle-needful-things/Maitre.bat $KETTLE_FOLDER
cp $KETTLE_FOLDER/plugins/kettle-needful-things/maitre.sh $KETTLE_FOLDER
cp $KETTLE_FOLDER/plugins/kettle-needful-things/kettle-needful-things-*.jar $KETTLE_FOLDER/lib
cp $KETTLE_FOLDER/plugins/kettle-needful-things/lib/picocli-*.jar $KETTLE_FOLDER/lib

# GitSpoon!
#
./getLatestSpoonGit.sh  >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/pdi-git-plugin-latest.zip -d $KETTLE_FOLDER/plugins

# The Environment plugin
#
./getLatestBase.sh mattcasters/kettle-environment kettle-environment >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/kettle-environment-latest.zip -d $KETTLE_FOLDER/plugins

# The Load Text From File plugin
#
./getLatestBase.sh mattcasters/load-text-from-file-plugin load-text-from-file-plugin >> ${LOGFILE}
unzip -q -o $TMP_DIR_BASE/load-text-from-file-plugin-latest.zip -d $KETTLE_FOLDER/plugins

################################################################
# Packaging
################################################################

# Correct other writeable permissions
#
cd $KETTLE_FOLDER
chmod -R o-w *
chmod 770 ../data-integration
echo file permissions fixed >> ${LOGFILE}

# Patch Spoon.sh, get rid of silly warnings
#
< spoon.sh \
  sed 's/ -XX:MaxPermSize=256m//g' \
| sed 's/export UBUNTU_MENUPROXY=0/export UBUNTU_MENUPROXY=0\n\n# Skip WebkitGTK warning\n#\nexport SKIP_WEBKITGTK_CHECK=1\n/g' \
> spoon.sh.new

mv spoon.sh spoon.sh.orig
mv spoon.sh.new spoon.sh
chmod +x spoon.sh
echo patched \"spoon.sh\" >> ${LOGFILE}

# Now zip it back up...
#
cd $TMP_DIR_BASE
if [ -f "$REMIX_ZIP" ]
then
  rm -f "$REMIX_ZIP"
fi
if [ -f "$REMIX_TGZ" ]
then
  rm -f "$REMIX_TGZ"
fi

################################################################
# Packaging
################################################################

echo Building remix archive ${REMIX_ZIP} >> ${LOGFILE}
zip -q -r "$REMIX_ZIP" data-integration
echo Building remix archive ${REMIX_TGZ} >> ${LOGFILE}
tar -czf "$REMIX_TGZ" data-integration

################################################################
# Upload to AWS
################################################################

echo Uploading archive to s3://kettle-neo4j/$REMIX_ZIP >> ${LOGFILE}
s3cmd put "$REMIX_ZIP" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_ZIP" --acl-public

echo Uploading archive to s3://kettle-neo4j/$REMIX_TGZ >> ${LOGFILE}
s3cmd put "$REMIX_TGZ" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_TGZ" --acl-public

echo Remix build done >> ${LOGFILE}

s3cmd put "$REMIX_LOG" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_LOG" --acl-public

cd -
