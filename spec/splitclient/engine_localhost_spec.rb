require 'spec_helper'

describe SplitIoClient do
  subject { SplitIoClient::SplitFactory.new('localhost').client }

  let(:split_file) { ["local_feature local_treatment", "local_feature2 local_treatment2", "local_feature local_treatment_rewritten"] }
  let(:split_string) { "local_feature local_treatment\nlocal_feature2 local_treatment2\local_feature local_treatment_rewritten" }

  describe "#get_treatment returns localhost mode" do
    let(:user_id_1) { 'my_random_user_id' }
    let(:user_id_2) { 'my_random_user_id' }

    it 'validates the feature has the correct treatment for any user id in local mode' do
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).and_return(split_file)
      allow(File).to receive(:read).and_return(split_string)
      # Also testing in the following expectation, that the last line of a repeated treatment prevails
      expect(subject.get_treatment(user_id_1, "local_feature")).to eq("local_treatment_rewritten")
      expect(subject.get_treatment(user_id_2, "local_feature2")).to eq("local_treatment2")
    end

    it 'validates a non existing feature has control as treatment for any user id in local mode' do
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:open).and_return(split_file)
      allow(File).to receive(:read).and_return(split_string)
      expect(subject.get_treatment(user_id_1, "weird_local_feature")).to eq(SplitIoClient::Treatments::CONTROL)
      expect(subject.get_treatment(user_id_2, "non_existent_local_feature")).to eq(SplitIoClient::Treatments::CONTROL)
    end

  end
end