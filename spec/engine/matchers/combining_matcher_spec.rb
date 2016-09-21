require 'spec_helper'

describe SplitIoClient::CombiningMatcher do
  subject { SplitIoClient::SplitFactory.new('', logger: Logger.new('/dev/null')).client }

  let(:splits_json) { File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../test_data/splits/combining_matcher_splits.json'))) }
  let(:segments_json) { File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../test_data/segments/combining_matcher_segments.json'))) }

  let(:user_included) { 'fake_user_id_1' }
  let(:user_excluded) { 'fake_user_id_2' }
  let(:attributes_included) { { custom_attribute: 'argentina', join: 1461380400 } }
  let(:attributes_partially_excluded_1) { { custom_attribute: 'argentina', join: 46138040 } }
  let(:attributes_partially_excluded_2) { { custom_attribute: 'chile', join: 1461380400 } }
  let(:attributes_excluded) { { custom_attribute: 'chile', join: 46138040 } }
  let(:feature) { 'RUBY_anding' }

  before do
    stub_request(:get, 'https://sdk.split.io/api/segmentChanges/employees?since=-1')
      .to_return(status: 200, body: segments_json)
    stub_request(:get, 'https://sdk.split.io/api/splitChanges?since=-1')
      .to_return(status: 200, body: splits_json)
  end

  it 'checks that the feature is V2 for the right AND conditions' do
    expect(subject.get_treatment(user_included, feature, attributes_included)).to eq 'V2'
  end

  it 'checks that the feature is V3 for the right else condition' do
    expect(subject.get_treatment(user_included, feature, attributes_excluded)).to eq 'V3'
    expect(subject.get_treatment(user_included, feature, attributes_partially_excluded_1)).to eq 'V3'
    expect(subject.get_treatment(user_included, feature, attributes_partially_excluded_2)).to eq 'V3'
  end

  it 'checks that the feature is V1 as default treatment for a non matching set of id and attributes' do
    expect(subject.get_treatment(user_excluded, feature, attributes_excluded)).to eq 'V1'
    expect(subject.get_treatment(user_excluded, feature, attributes_partially_excluded_1)).to eq 'V1'
    expect(subject.get_treatment(user_excluded, feature, attributes_partially_excluded_2)).to eq 'V1'
  end

  it 'checks that the feature is control for a wrong set of params' do
    expect(subject.get_treatment(nil, feature, another: 'attribute')).to eq(SplitIoClient::Treatments::CONTROL)
  end

  it 'checks that failing first condition with wrong date format attribute, '\
     'and matching second returns correct second condition expected result' do

    expect(subject.get_treatment(user_included, feature, custom_attribute: 'argentina', join: 'random')).to eq 'V3'
  end
end
