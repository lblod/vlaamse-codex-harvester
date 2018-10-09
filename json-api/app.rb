require_relative './lib/harvester'

# Enable the retrieval of additional details of a document
# This requires an additional call per document
enable_detail = true

# Enable the retrieval of articles related to documents
# This requires an additional call per document
enable_articles = true

# Enable to retrieve only 1 page of documents instead of all pages
# This will limit the duration of the script
only_once = false

harvester = Harvester.new(enable_detail, enable_articles, only_once)
harvester.harvest



