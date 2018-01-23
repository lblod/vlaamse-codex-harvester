require 'linkeddata'

class SemanticModelGenerator
  CODEX = RDF::Vocabulary.new("http://codex.opendata.api.vlaanderen.be/api/")
  BESLUIT = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/besluit#")
  ELI = RDF::Vocabulary.new("http://data.europa.eu/eli/ontology#")

  def initialize
    @graph = RDF::Graph.new
  end
  
  def insert_besluit(document)
    subject = RDF::URI(document["Link"]["Href"])

    id = document["Id"]
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
    @graph << RDF.Statement(subject, RDF::RDFS.seeAlso, RDF::URI.new("https://codex.vlaanderen.be/Zoeken/Document.aspx?DID=#{id}&param=inhoud"))
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

  def write_ttl_to_file(file)
    RDF::Writer.open(file) { |writer| writer << @graph }
    # graph.to_ttl
    # puts ttl
  end
end
