require 'bundler'
Bundler.require
require 'open-uri'
require 'rubygems'
require 'google_drive'

# La première partie du code de la classe reprend le scrapper de jeudi dernier. La correction ayant été faite en vidéo et diffusée hier, nous n'allons pas revenir dessus. Les trois methods d'enregistrement dans les bases de données se font après.
# Le programme est limité à 5 entrées dans un soucis de fluidité. Il est possible de changer ce nombre en changeant la valeur de i à la ligne 40

class Scrapper
  # Initialisation de la classe. La variable de classe @list est un hash reprenant tous les noms des villes en key et les emails corresondants en value
  def initialize
    @list = get_all_email(url_and_name())
  end

  def url_and_name
    url = "http://annuaire-des-mairies.com/val-d-oise.html"
    doc = Nokogiri::HTML(open(url))
    url_path = doc.css("a[href].lientxt")
    name_and_url = []

    url_path.map do |value|
      url_ville = value["href"]
      url_ville[0] = ""
      name_and_url << { "name" => value.text, "url" => "http://annuaire-des-mairies.com" + url_ville }
    end
    name_and_url
  end

  def get_townhall_email(url)
    doc = Nokogiri::HTML(open(url))
    email = doc.xpath("/html/body/div/main/section[2]/div/table/tbody/tr[4]/td[2]").text
  end

  def get_all_email(name_and_url)
    name_and_email = []

    name_and_url.map.with_index do |value, i|
      name_and_email << {value["name"] => get_townhall_email(value["url"])}
      break if i == 5
    end
    name_and_email
    # Cette ligne permet de passer d'une array de hashs à un grand hash avec les noms des villes en key et les emails corresondants en value
    name_and_email.reduce Hash.new, :merge
  end

  # Le fichier db/emails.json est ouvert grace à la gem json. La method .to_json fait rentrer les keys et values de @list dans le fichier email.json. L'argument "w" de la method open() permet d'écrire dans le fichier
  def save_as_json
    File.open("db/emails.json","w") do |f|
      f.write(@list.to_json)
    end
  end

  # La vaiable session est définie comme étant la session de l'utilisateur référencé dans le fichier config.json
  # ws correspond à la Google Sheet https://docs.google.com/spreadsheets/d/1y8eNg5dRwdLISAx_7-9zKhEeUQg1_xwkhVfzdaSBIUc/edit#gid=0
  # Le nom de la colonne 1 et 2 est initialisé par les titres de colonne "Nom ville" et "Email"
  # Une boucle parcourt la liste pour écrire les données du hash vers le tableau
  # Enfin, les changements sont sauvegardés et implémentés dans le tableau
  def save_as_spreadsheet
    session = GoogleDrive::Session.from_config("config.json")
    ws = session.spreadsheet_by_key("1y8eNg5dRwdLISAx_7-9zKhEeUQg1_xwkhVfzdaSBIUc").worksheets[0]
    ws[2,1] = "Nom ville"
    ws[2,2] = "Email"
    i = 3
    @list.each do |k,v|
      ws[i,1] = k
      ws[i,2] = v
      i +=1
    end
    ws.save
  end

  # La variable d'instance @list est parcourrue,  les keys et values s'intégrant dans le fichier CSV comme si on les entrait dans un array
  def save_as_csv
    CSV.open("db/emails.csv", "w") do |csv|
      @list.each do |k,v|
        csv << [k,v]
      end
    end
  end
end
