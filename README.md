# dockerfile-webspoon-neo4j
This contains everything to set up a Neo4j server alongside a Webspoon instance

# Running

To run Neo4j alongside a WebSpoon instance you can run this:

docker-compose up -d

or the script: runWebspoonNeo4j.sh

# Using

WebSpoon: http://<server>:8080/spoon/spoon
Carte   : http://<server>:8080/spoon/kettle/status  (use application spoon in slave server definitions)
Neo4j   : http://<server>:7474/spoon/spoon
          bolt port : 7687
          username: neo4j
          password: change in docker-compose.yml

# Prerequisites

You need to have the following installed:
- docker
- docker-compose
- git
- zip / unzip

# Building

To build the custom webspoon image with the very latest Kettle plugins installed I use:

build-push-webspoon-neo4j.sh

you need to be logged into docker to access your hub if you want to build your own images (docker login)
