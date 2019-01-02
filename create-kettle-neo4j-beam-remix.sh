
# set -ex


SOFT_DIR=/home/kettle/software

BASE_FILE=$SOFT_DIR/pdi-ce-8.2.0.0-342.zip
REMIX_VERSION=8.2.0.1-REMIX
REMIX_FILE=kettle-neo4j-beam-remix-$REMIX_VERSION.zip
TMP=/tmp
FOLDER=$TMP/data-integration
BEAM_PLUGIN_FILE=kettle-beam-20181210.zip

echo Remix build start
echo Remix version : $REMIX_VERSION

if [ -d /tmp/data-integration ]
then
  rm -rf /tmp/data-integration
fi

# Unzip the BASE_FILE
#
echo Extracting base archive ${BASE_FILE}
unzip -q $BASE_FILE -d /tmp/

# Patch the kettle jars
#
cp $SOFT_DIR/latest-patches/kettle-core-8.2.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-core-8.2.0.0-342.jar
cp $SOFT_DIR/latest-patches/kettle-dbdialog-8.2.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-dbdialog-8.2.0.0-342.jar
cp $SOFT_DIR/latest-patches/kettle-engine-8.2.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-engine-8.2.0.0-342.jar
cp $SOFT_DIR/latest-patches/kettle-ui-swt-8.2.0.0-SNAPSHOT.jar $FOLDER/lib/kettle-ui-swt-8.2.0.0-342.jar

# Get rid of a bunch of plugins...
#
for plugin in kettle-openerp-plugin kettle-shapefilereader-plugin kettle-version-checker kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin kettle-drools5-plugin lucid-db-streaming-loader-plugin ms-access-plugins pdi-teradata-tpt-plugin
do
  echo Removing plugin ${plugin}
  rm -rf $FOLDER/plugins/${plugin}
done

cp getLatestSamples.sh $TMP
cp getLatestBase.sh $TMP
cp getLatestSpoonGit.sh $TMP

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

# Latest Kettle Metastore plugin
#
./getLatestBase.sh mattcasters/kettle-metastore kettle-metastore
unzip -q -o $TMP/kettle-metastore-latest.zip -d $FOLDER/plugins

# Latest needful things & install Maitre
#
./getLatestBase.sh mattcasters/kettle-needful-things kettle-needful-things
unzip -q -o $TMP/kettle-needful-things-latest.zip -d $FOLDER/plugins
cp $FOLDER/plugins/kettle-needful-things/Maitre.bat $FOLDER
cp $FOLDER/plugins/kettle-needful-things/maitre.sh $FOLDER
cp $FOLDER/plugins/kettle-needful-things/kettle-needful-things-*.jar $FOLDER/lib
cp $FOLDER/plugins/kettle-needful-things/lib/picocli-*.jar $FOLDER/lib

# GitSpoon!
#
./getLatestSpoonGit.sh 
unzip -q -o $TMP/pdi-git-plugin-latest.zip -d $FOLDER/plugins

# The Environment plugin
#
./getLatestBase.sh mattcasters/kettle-environment kettle-environment
unzip -q -o $TMP/kettle-environment-latest.zip -d $FOLDER/plugins

# Kettle Beam : 300MB
#
unzip -q -o $SOFT_DIR/$BEAM_PLUGIN_FILE -d $FOLDER/plugins
echo $BEAM_PLUGIN_FILE

# The Kettle Beam Examples
#
cd $FOLDER/samples/
git clone git@github.com:mattcasters/kettle-beam-examples.git 2> /dev/null > /dev/null
echo kettle-beam-examples cloned

# Correct other writeable permissions
#
cd $FOLDER
chmod -R o-w *
echo file permissions fixed

# Remove more big data cr*p from system/
# 
# find $FOLDER/system -type d -name '*-big-data*' -exec rm -rf {} \; 2>/dev/null >/dev/null
# rm -f $FOLDER/system/karaf/system/pentaho/pentaho-osgi-config/8.2.0.0-342/pentaho-osgi-config-8.2.0.0-342-pentaho-big-data-impl-cluster.cfg
# cp $SOFT_DIR/latest-patches/pentaho-karaf-features-8.2.0.0-342-standard.xml \
#     $FOLDER/system/karaf/system/pentaho/pentaho-karaf-features/8.2.0.0-342/pentaho-karaf-features-8.2.0.0-342-standard.xml
# echo removed big-data-plugin features

# Patch plugins
#
cp -r -v $SOFT_DIR/plugin-patches/* $FOLDER/plugins/
echo patched plugins

# Now zip it back up...
#
echo Building remix archive ${REMIX_FILE}
cd $TMP
if [ -f "$REMIX_FILE" ]
then
  rm -f "$REMIX_FILE"
fi

zip -q -r "$REMIX_FILE" data-integration


echo Uploading remix archive to s3://kettle-neo4j

s3cmd put "$REMIX_FILE" s3://kettle-neo4j/ --multipart-chunk-size-mb=4096
s3cmd setacl s3://kettle-neo4j/"$REMIX_FILE" --acl-public

cd -

echo Remix build done

