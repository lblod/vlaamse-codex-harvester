# Vlaamse Codex Harvester

## Running the LOD harvester
This script harvests the data from the Vlaamse Codex LOD SPARQL endpoint.
```
cd ./lod
docker run --rm --name codex-harvester -v "$PWD":/app -e NODE_ENV=development semtech/mu-javascript-template:1.3.2
```

The output will be written to `./lod/output/output.ttl`.

## Running the JSON harvester
This script harvests the data from the Vlaamse Codex API at http://codex.opendata.api.vlaanderen.be.

The script can be executed in a Docker container through the following command:
```
cd ./json-api
docker run -it --rm --name codex-harvester -v "$PWD":/app -w /app ruby:2.5 ./run.sh
```

The output will be written to `./json-api/output/output.ttl`.


### Configuration
The script can be configured in `json-api/app.rb`. Currently the following options need to be configured:
* **enable_detail** _(default: true)_: enable the retrieval of additional details of a document. This requires an additonal request per document. 
* **enable_articles** _(default: true)_: enable the retrieval of articles of a document. This requires an additonal request per document. 
* **only_once** _(default: false)_: enable to retrieve only 1 page of documents instead of all pages. This option may be handy during development.

### Developing the script

Start a Docker container:
```
cd ./json-api
docker run -it --name codex-harvester -v "$PWD":/app -w /app ruby:2.5 /bin/bash
```

Execute the following commands in the Docker container:
```
bundle install
ruby app.rb
```
