require_relative './codex'
require_relative './semantic-model-generator'

class Harvester

  def initialize(enable_detail = true, enable_articles = true, only_once = false, output = "output/output.ttl")
    @enable_detail = enable_detail
    @enable_articles = enable_articles
    @only_once = only_once
    @output = output

    @codex = Codex.new
    @generator = SemanticModelGenerator.new
  end

  def harvest
    puts "Start harvesting Vlaamse Codex"

    handled = 0; inserted = 0; skip = 0; take = 10; total = 1

    # Go through all document pages
    while skip < total
      puts "Get documents [#{skip}-#{skip + take}]"
      documents_list = @codex.documents(skip, take)
      total = documents_list["TotaalAantal"]

      # Handle each document on a page
      documents_list["ResultatenLijst"].each_with_index do |document, i|
        handled += 1
        
        if @codex.isValidBesluit(document)
          inserted += 1
          besluit = @generator.insert_besluit(document)

          # Add additional document information if enabled
          if (@enable_detail)
            puts "-- Get document details [#{i}]"
            detail = @codex.document(document["Id"])
            @generator.enrich_besluit(detail)
          end

          # Add articles if enabled
          if (@enable_articles)
            puts "-- Get articles [#{i}]"            
            structure = @codex.document_structure(document["Id"])
            walk_items(structure, besluit)
          end
        end
      end

      skip += take
      skip = total if @only_once
    end

    puts "#{handled}/#{total} documents harvested. #{inserted} documents are mapped."

    @generator.write_ttl_to_file @output
  end


  
  private

  def walk_items(structure, besluit)
    if (structure["Items"])
      structure["Items"].each do |item|
        if (item["ItemType"] == "A")
          @generator.insert_article(item, besluit)
        end

        walk_items(item, besluit)
      end
    end
  end
end
