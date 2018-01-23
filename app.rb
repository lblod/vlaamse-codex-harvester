require 'linkeddata'
require_relative './lib/codex'
require_relative './lib/semantic-model-generator'

puts "Start harvesting Vlaamse Codex"

# Enable the retrieval of additional details of a document
# This requires an additional call per document
enable_detail = false

codex = Codex.new
graph = RDF::Graph.new
generator = SemanticModelGenerator.new(graph)

count = 0; skip = 0; take = 10; total = 1

# Go through all document pages
while skip < total
  puts "Get documents [#{skip}-#{skip + take}]"
  documents_list = codex.documents(skip, take)
  total = documents_list["TotaalAantal"]

  # Handle each document on a page
  documents_list["ResultatenLijst"].each do |document|
    if codex.isValidBesluit(document)
      count += 1
      generator.insert_besluit(document)

      # Add additional document information if enabled
      if (enable_detail)
        detail = codex.document(document["Id"])
        generator.enrich_besluit(detail)
      end
    end
  end

  skip += take
  skip = total # TODO remove
end

puts "#{count}/#{total} documents harvested"

RDF::Writer.open("output/output.ttl") { |writer| writer << graph }
# graph.to_ttl
# puts ttl
