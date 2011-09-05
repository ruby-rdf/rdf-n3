$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::N3::Format do
  context "discovery" do
    {
      "n3" => RDF::Format.for(:n3),
      "etc/foaf.n3" => RDF::Format.for("etc/foaf.n3"),
      "foaf.n3" => RDF::Format.for(:file_name      => "foaf.n3"),
      ".n3" => RDF::Format.for(:file_extension => "n3"),
      "text/n3" => RDF::Format.for(:content_type   => "text/n3"),
      "text/rdf+n3" => RDF::Format.for(:content_type   => "text/rdf+n3"),
      "application/rdf+n3" => RDF::Format.for(:content_type   => "application/rdf+n3"),
    }.each_pair do |label, format|
      it "should discover '#{label}'" do
        format.should == RDF::N3::Format
      end
    end
    
    it "should discover 'notation3'" do
      RDF::Format.for(:notation3).reader.should == RDF::N3::Reader
      RDF::Format.for(:notation3).writer.should == RDF::N3::Writer
    end
  end
end
