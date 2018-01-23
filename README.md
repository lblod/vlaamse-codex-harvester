# Vlaamse Codex Harvester

This script harvests the data from the Vlaamse Codex at http://codex.opendata.api.vlaanderen.be.

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

## Running the script
The script can be executed in a Docker container through the following command:

```
docker run -it --rm --name codex-harvester -v "$PWD":/app -w /app ruby:2.5 ruby app.rb
```

The output will be written to `output/output.ttl`.