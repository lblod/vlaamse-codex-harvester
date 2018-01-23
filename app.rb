require 'httparty'
require 'linkeddata'

class Codex
  include HTTParty
  
  base_uri 'codex.opendata.api.vlaanderen.be'

  def documents(skip = 0, take = 20)
    self.class.get("/api/WetgevingDocument?skip=#{skip}&take=#{take}")
  end  

  def document(id)
    self.class.get("/api/WetgevingDocument/#{id}/VolledigDocument")
  end

  def isValidBesluit(document)
    type = document["WetgevingDocumentType"].downcase
    type.include?("besluit") || type.include?("reglement") || type.include?("decreet")
  end
end

class SemanticModelGenerator
  CODEX = RDF::Vocabulary.new("http://codex.opendata.api.vlaanderen.be/api/")
  BESLUIT = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/besluit#")
  ELI = RDF::Vocabulary.new("http://data.europa.eu/eli/ontology#")

  def initialize(graph)
    @graph = graph
  end
  
  def insert_besluit(document)
    subject = RDF::URI(document["Link"]["Href"])

    date = document["Datum"][0, 10] # "YYYY-MM-DD" substring
    title = "#{document["WetgevingDocumentType"]} #{document["Opschrift"]}".strip
    doc_type = document["WetgevingDocumentType"].gsub " ", "_"

    match = title.match(/\(citeeropschrift: \"(.*)\"\)/)
    citeeropschrift = if match then match[1] else title end

    @graph << RDF.Statement(subject, RDF.type, BESLUIT.Besluit)
    @graph << RDF.Statement(subject, ELI["date_publication"], RDF::Literal.new(date, datatype: RDF::XSD.date))
    @graph << RDF.Statement(subject, ELI.title, title)
    @graph << RDF.Statement(subject, ELI["title_short"], citeeropschrift)
    # TODO replace documentType URI
    @graph << RDF.Statement(subject, ELI["type_document"], CODEX["WetgevingDocumentType/#{doc_type}"])
    @graph << RDF.Statement(subject, ELI.language, RDF::URI.new("http://publications.europa.eu/resource/authority/language/NLD"))        
  end

  def enrich_besluit(document_detail)
    document = document_detail["Document"]
    subject = RDF::URI(document["Link"]["Href"])

    if document["StartDatum"]
      startDate = document["StartDatum"][0, 10] # "YYYY-MM-DD" substring
      @graph << RDF.Statement(subject, ELI["first_date_entry_in_force"], RDF::Literal.new(startDate, datatype: RDF::XSD.date))
    end
    if document["EindDatum"]
      endDate = document["EindDatum"][0, 10] # "YYYY-MM-DD" substring
      @graph << RDF.Statement(subject, ELI["date_no_longer_in_force"], RDF::Literal.new(endDate, datatype: RDF::XSD.date))
    end
  end
end


puts "Start harvesting Vlaamse Codex"

# Enable the retrieval of additional details of a document
# This requires an additional call per document
enable_detail = false

codex = Codex.new
graph = RDF::Graph.new
generator = SemanticModelGenerator.new(graph)

count = 0
skip = 0
take = 10
total = 1

while skip < total
  puts "Get documents [#{skip}-#{skip + take}]"
  documents_list = codex.documents(skip, take)
  total = documents_list["TotaalAantal"]

  documents_list["ResultatenLijst"].each do |document|
    if codex.isValidBesluit(document)
      count += 1
      generator.insert_besluit(document)

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
