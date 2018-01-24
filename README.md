# Vlaamse Codex Harvester

This script harvests the data from the Vlaamse Codex at http://codex.opendata.api.vlaanderen.be.

## Running the harvester
The script can be executed in a Docker container through the following command:
```
docker run -it --rm --name codex-harvester -v "$PWD":/app -w /app ruby:2.5 ./run.sh
```

The output will be written to `output/output.ttl`.


## Configuration
The script can be configured in `app.rb`. Currently the following options need to be configured:
* **enable_detail** _(default: true)_: enable the retrieval of additional details of a document. This requires an additonal request per document. 
* **enable_articles** _(default: true)_: enable the retrieval of articles of a document. This requires an additonal request per document. 
* **only_once** _(default: false)_: enable to retrieve only 1 page of documents instead of all pages. This option may be handy during development.

## Developing the script

Start a Docker container:
```
docker run -it --name codex-harvester -v "$PWD":/app -w /app ruby:2.5 /bin/bash
```

Execute the following commands in the Docker container:
```
bundle install
ruby app.rb
```
