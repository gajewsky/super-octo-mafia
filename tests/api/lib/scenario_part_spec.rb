require_relative 'spec_helper'
require_relative 'scenario_part'

describe ScenarioPart do
  context "finding of all nested scenarios" do
    specify do
      happy_path = ScenarioPart.new('./fixtures/scenarios/happy_path/')
      expect(happy_path.parent).to be_nil
      expect(happy_path).not_to be_leaf
      expect(happy_path.path).to eq './fixtures/scenarios/happy_path'

      part1, part2 = happy_path.sub_parts
      expect(part1.parent).to eq happy_path
      expect(part2.parent).to eq happy_path
      expect(part1).not_to be_leaf
      expect(part2).not_to be_leaf
      expect(part1.path).to eq './fixtures/scenarios/happy_path/part1'
      expect(part2.path).to eq './fixtures/scenarios/happy_path/part2'

      part1_1, part1_2 = part1.sub_parts
      expect(part1_1.parent).to eq part1
      expect(part1_2.parent).to eq part1
      expect(part1_1).to be_leaf
      expect(part1_2).to be_leaf
      expect(part1_1.path).to eq './fixtures/scenarios/happy_path/part1/part1_1'
      expect(part1_2.path).to eq './fixtures/scenarios/happy_path/part1/part1_2'

      part2_1, part2_2 = part2.sub_parts
      expect(part2_1.parent).to eq part2
      expect(part2_2.parent).to eq part2
      expect(part2_1).to be_leaf
      expect(part2_2).to be_leaf
      expect(part2_1.path).to eq './fixtures/scenarios/happy_path/part2/part2_1'
      expect(part2_2.path).to eq './fixtures/scenarios/happy_path/part2/part2_2'
    end
  end
end
