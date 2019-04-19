#!/usr/bin/env ruby

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'rdf/n3'

data = <<-EOF;
  @prefix dc: <http://purl.org/dc/elements/1.1/>.
  @prefix po: <http://purl.org/ontology/po/>.
  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>.
  _:broadcast
   a po:Broadcast;
   po:schedule_date """2008-06-24T12:00:00Z""";
   po:broadcast_of _:version;
   po:broadcast_on <http://www.bbc.co.uk/programmes/service/6music>;
  .
  _:version
   a po:Version;
  .
  <http://www.bbc.co.uk/programmes/b0072l93>
   dc:title """Nemone""";
   a po:Brand;
  .
  <http://www.bbc.co.uk/programmes/b00c735d>
   a po:Episode;
   po:episode <http://www.bbc.co.uk/programmes/b0072l93>;
   po:version _:version;
   po:long_synopsis """Actor and comedian Rhys Darby chats to Nemone.""";
   dc:title """Nemone""";
   po:synopsis """Actor and comedian Rhys Darby chats to Nemone.""";
  .
  <http://www.bbc.co.uk/programmes/service/6music>
   a po:Service;
   dc:title """BBC 6 Music""";
  .

  #_:abcd a po:Episode.
EOF

RDF::N3::Reader.new(data, base_uri: 'http://www.bbc.co.uk/programmes/on-now.n3') do |reader|
  reader.each_statement do |statement|
    statement.inspect!
  end
end
