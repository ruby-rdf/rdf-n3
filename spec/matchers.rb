require 'rdf/isomorphic'

# Don't use be_equivalent_graph from rdf/spec because of odd N3 semantics
Info = Struct.new(:about, :logger, :inputDocument, :outputDocument, :format)

RSpec::Matchers.define :be_equivalent_graph do |expected, info|
  match do |actual|
    def normalize(graph)
      case graph
      when RDF::Enumerable then graph
      when IO, StringIO
        RDF::Repository.new.load(graph, base_uri: @info.about)
      else
        # Figure out which parser to use
        g = RDF::Repository.new
        reader_class = RDF::Reader.for(detect_format(graph))
        reader_class.new(graph, base_uri: @info.about).each {|s| g << s}
        g
      end
    end

    @info = if info.respond_to?(:about)
      info
    elsif info.is_a?(Logger)
      Info.new("", info)
    elsif info.is_a?(Hash)
      Info.new(info[:about], info[:logger])
    else
      Info.new(expected.is_a?(RDF::Graph) ? expected.graph_name : info, info.to_s)
    end
    @info.format ||= :n3
    @expected = normalize(expected)
    @actual = normalize(actual)
    @actual.isomorphic_with?(@expected) rescue false
  end
  
  failure_message do |actual|
    trace = case @info.logger
    when Logger then @info.logger.to_s
    when Array then @info.logger.join("\n")
    end
    info = @info.respond_to?(:about) ? @info.about : @info.inspect
    if @expected.is_a?(RDF::Enumerable) && @actual.size != @expected.size
      "Graph entry count differs:\nexpected: #{@expected.size}\nactual:   #{@actual.size}"
    elsif @expected.is_a?(Array) && @actual.size != @expected.length
      "Graph entry count differs:\nexpected: #{@expected.length}\nactual:   #{@actual.size}"
    else
      "Graph differs"
    end +
    "\n#{info + "\n" unless info.to_s.empty?}" +
    (@info.inputDocument ? "Input file: #{@info.inputDocument}\n" : "") +
    (@info.outputDocument ? "Output file: #{@info.outputDocument}\n" : "") +
    "Expected:\n#{@expected.dump(@info.format, standard_prefixes: true)}" +
    "Results:\n#{@actual.dump(@info.format, standard_prefixes: true)}" +
    (trace ? "\nDebug:\n#{trace}" : "")
  end  
end
