require 'bundler'
Bundler.require
require 'open-uri'
require 'rubygems'
require 'google_drive'

# Le fichier contenant la classe Scrapper est appelé
require_relative 'lib/app/scrapper.rb'

# Une instance du Scrapper est appelée directement
scrap = Scrapper.new

# Le binding.pry permet de d'experimenter directement depuis le terminal
binding.pry

puts "end of program"
