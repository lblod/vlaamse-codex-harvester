require 'httparty'

class Codex
  include HTTParty
  
  base_uri 'codex.opendata.api.vlaanderen.be'

  def documents(skip = 0, take = 20)
    self.class.get("/api/WetgevingDocument?skip=#{skip}&take=#{take}")
  end  

  def document(id)
    self.class.get("/api/WetgevingDocument/#{id}/VolledigDocument")
  end

  def document_structure(id)
    self.class.get("/api/WetgevingDocument/#{id}/Structuur?includeArtikelen=true")
  end

  def isValidBesluit(document)
    type = document["WetgevingDocumentType"].downcase
    type.include?("besluit") || type.include?("reglement") || type.include?("decreet")
  end
end
