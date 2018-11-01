require 'diffy'
require 'tty-reader'
require_relative 'step_ui'
require_relative 'request_dumper'
require_relative 'request_parser'
require_relative 'response_dumper'
require_relative 'response_parser'
require_relative 'request_executor'
require_relative 'octo_mafia_response'

class StepRunner
  def initialize(step, ui: StepUI.new(STDOUT))
    @step = step
    @ui = ui
  end

  def call
    response_string = if File.exists?(response_path)
                        File.read(response_path)
                      else
                        ''
                      end

    request = RequestParser.new(File.read(request_path)).parse
    response = RequestExecutor.new(request).call

    dumper = ResponseDumper.new(OctoMafiaResponse.new response)
    actual_response_string = dumper.to_s
    diff = Diffy::Diff.new(response_string, actual_response_string)

    ui.started(step)

    if diff.none?
      ui.ok(step)
    else
      ui.failed(step)
      ui.show_diff(step, diff, request, response)

      if ui.ask_to_cache(step, diff, request, response)
        File.open(response_path, 'wb') { |f| f.write(actual_response_string) }
        ui.step_cached
      else
        ui.exiting
        exit 1
      end
      ui.step_ended
    end
  end

  private

  attr_reader :step, :ui

  def request_path
    step.request_path
  end

  def response_path
    step.response_path
  end
end

