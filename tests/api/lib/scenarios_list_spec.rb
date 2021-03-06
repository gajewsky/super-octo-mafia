require_relative 'scenarios_list'

describe ScenariosList do
  it "#all returns all scenarios" do
    list = ScenariosList.new('./fixtures/scenarios')
    scenarios = list.all

    expect(scenarios.length).to eq 6

    # scenarios have steps pointing to existing files
    scenarios.each do |scenario|
      scenario.steps.each do |step|
        expect(File.exist?(step.request_path)).to be_truthy
        expect(File.file?(step.request_path)).to be_truthy

        expect(File.exist?(step.response_path)).to be_truthy
        expect(File.file?(step.response_path)).to be_truthy
      end
    end

    s1, s2, s3, s4, s5, s6 = scenarios

    # scenarios have proper names
    expect(s1.name).to eq 'error_path/second_level/third_level'
    expect(s2.name).to eq 'error_path/second_level_2/third_level_2'
    expect(s3.name).to eq 'happy_path/part1/part1_1'
    expect(s4.name).to eq 'happy_path/part1/part1_2'
    expect(s5.name).to eq 'happy_path/part2/part2_1'
    expect(s6.name).to eq 'happy_path/part2/part2_2'

    # steps are sorted alphabetically
    expect(s1.steps).to eq s1.steps.sort_by(&:request_path)
    expect(s2.steps).to eq s2.steps.sort_by(&:request_path)
    expect(s3.steps).to eq s3.steps.sort_by(&:request_path)
    expect(s4.steps).to eq s4.steps.sort_by(&:request_path)
    expect(s5.steps).to eq s5.steps.sort_by(&:request_path)
    expect(s6.steps).to eq s6.steps.sort_by(&:request_path)
  end

  describe '#by_root_path' do
    it 'returns scenarios matching provided path as a direct ancestor' do
      list = ScenariosList.new('./fixtures/scenarios')
      scenarios = list.by_root_path('fixtures/scenarios/happy_path/part1')
      expect(scenarios.length).to eq 2

      s1, s2 = scenarios

      expect(s1.name).to eq 'happy_path/part1/part1_1'
      expect(s2.name).to eq 'happy_path/part1/part1_2'
    end
  end
end
