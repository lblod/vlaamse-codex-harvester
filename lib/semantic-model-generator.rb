require 'linkeddata'
require 'bson'

class SemanticModelGenerator
  CODEX = RDF::Vocabulary.new("http://codex.opendata.api.vlaanderen.be/api/")
  BESLUIT = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/besluit#")
  ELI = RDF::Vocabulary.new("http://data.europa.eu/eli/ontology#")
  MU = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/core/")

  LANG_NL = RDF::URI.new("http://publications.europa.eu/resource/authority/language/NLD")

  def initialize
    @graph = RDF::Graph.new
  end

  def insert_besluit(document)
    subject = construct_document_uri(document)

    id = document["Id"]
    uuid = BSON::ObjectId.new.to_s
    date = document["Datum"][0, 10] # "YYYY-MM-DD" substring
    title = "#{document["WetgevingDocumentType"]} #{document["Opschrift"]}".strip
    doc_type = document["WetgevingDocumentType"].gsub " ", "_"

    match = title.match(/\(citeeropschrift: \"(.*)\"\)/)
    citeeropschrift = if match then match[1] else title end

    @graph << RDF.Statement(subject, RDF.type, BESLUIT.Besluit)
    @graph << RDF.Statement(subject, MU.uuid, uuid)
    @graph << RDF.Statement(subject, ELI["date_publication"], RDF::Literal.new(date, datatype: RDF::XSD.date))
    @graph << RDF.Statement(subject, ELI.title, title)
    @graph << RDF.Statement(subject, ELI["title_short"], citeeropschrift)
    # TODO replace with correct documentType URI
    @graph << RDF.Statement(subject, ELI["type_document"], CODEX["WetgevingDocumentType/#{doc_type}"])
    @graph << RDF.Statement(subject, ELI.language, LANG_NL)

    { id: id, uri: subject }
  end

  def enrich_besluit(document_detail)
    document = document_detail["Document"]
    subject = construct_document_uri(document)

    if document["StartDatum"]
      startDate = document["StartDatum"][0, 10] # "YYYY-MM-DD" substring
      @graph << RDF.Statement(subject, ELI["first_date_entry_in_force"], RDF::Literal.new(startDate, datatype: RDF::XSD.date))
    end
    if document["EindDatum"]
      endDate = document["EindDatum"][0, 10] # "YYYY-MM-DD" substring
      @graph << RDF.Statement(subject, ELI["date_no_longer_in_force"], RDF::Literal.new(endDate, datatype: RDF::XSD.date))
    end

    { id: document["Id"], uri: subject }
  end

  def insert_article(article, besluit)
    subject = RDF::URI(article["Link"]["Href"])

    id = article["Id"]
    uuid = BSON::ObjectId.new.to_s

    @graph << RDF.Statement(subject, RDF.type, BESLUIT.Artikel)
    @graph << RDF.Statement(subject, MU.uuid, uuid)
    @graph << RDF.Statement(subject, ELI.title, "Artikel #{article["Titel"]}".strip)
    @graph << RDF.Statement(subject, ELI.number, article["Titel"])
    @graph << RDF.Statement(subject, ELI.language, LANG_NL)
    @graph << RDF.Statement(subject, ELI["is_part_of"], besluit[:uri])
    @graph << RDF.Statement(subject, RDF::Vocab::FOAF.page, RDF::URI.new("https://codex.vlaanderen.be/Zoeken/Document.aspx?DID=#{besluit[:id]}&param=inhoud&AID=#{id}"))

    { id: id, uri: subject }
  end

  def construct_document_uri(document)
    RDF::URI(document["Link"]["Href"] + '/volledigdocument')
  end

  def write_ttl_to_file(file)
    RDF::Writer.open(file) { |writer| writer << @graph }
    # graph.to_ttl
    # puts ttl
  end
end
