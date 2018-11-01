require 'paint'

class ScenarioUI
  attr_reader :step_ui

  def initialize(output, step_ui: StepUI.new(STDOUT))
    @output = output
    @step_ui = step_ui
  end

  def started(scenario)
    output.print Paint["- #{scenario.name}", :bold]
    output.print ' '
  end

  def ended(scenario)
    output.puts
  end

  private

  attr_reader :output
end

