require 'http'
require 'json'
require 'diffy'
require 'paint'
require 'tty-reader'
require './lib/request_dumper.rb'
require './lib/request_parser.rb'
require './lib/response_dumper.rb'
require './lib/response_parser.rb'
require './lib/request_executor.rb'

HEADERS_TO_IGNORE = ['Date', 'Server', 'Content-Length']
BodyTransformer = ->(body) {
  begin
    json = JSON.parse(body)
    json.delete('version')
    json['state']&.delete('started_at')
    JSON.dump(json)
  rescue
    body
  end
}


class StepRunner
  def initialize(step_path)
    @step_path = step_path
  end

  def call
    step_name = File.basename(step_path)
    cached_response_path = "./responses_v2/#{step_name}"
    cached_response_string = if File.exists?(cached_response_path)
                               File.read(cached_response_path)
                             else
                               ''
                             end

    request = RequestParser.new(File.read(step_path)).to_h
    response = RequestExecutor.new(request).call

    dumper = ResponseDumper.from_http_response(
      response,
      ignore_headers: HEADERS_TO_IGNORE,
      transform_body: BodyTransformer
    )
    actual_response_string = dumper.to_s

    diff = Diffy::Diff.new(cached_response_string, actual_response_string)

    print "--- #{step_name}: "

    if diff.none?
      puts Paint["OK", :green]
    else
      puts Paint["FAILED", :red]
      puts
      puts diff.to_s(:color)
      puts
      puts '--- ' + Paint[request[:verb], :red] + ' ' + request[:uri] + ' -> ' + response.status.to_s
      print Paint["----- cache response? ", :yellow]

      if tty_reader.read_char.downcase == 'y'
        File.open(cached_response_path, 'wb') { |f| f.write(actual_response_string) }
        puts Paint["---> cached", :green]
      end
      puts
    end
  end

  private

  attr_reader :step_path

  def tty_reader
    @tty_reader ||= TTY::Reader.new
  end
end
