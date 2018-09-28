
# Populate the kettle-plugin-examples folder
# Zip the results
#
./getLatestSamples.sh

# Create the data folder for the Neo4j data
#
if [ ! -d data ]
then
  mkdir data
fi

docker build --no-cache -f Dockerfile.webspoon-neo4j -t mattcasters/webspoon-neo4j:latest . && \
docker push mattcasters/webspoon-neo4j:latest
