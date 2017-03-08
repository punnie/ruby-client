require 'spec_helper'

describe SplitIoClient::Splitter do
  RSpec.shared_examples 'algo' do |file, legacy_algo|
    it 'returns expected hash and bucket' do
      File.foreach(file) do |row|
        seed, key, hash, bucket = row.split(',')

        expect(described_class.count_hash(key, seed.to_i, legacy_algo)).to eq(hash.to_i)
        expect(described_class.bucket(hash.to_i)).to eq(bucket.to_i)
      end
    end
  end

  include_examples('algo', File.expand_path('spec/test_data/algo/murmur3.csv'), false)
  include_examples('algo', File.expand_path('spec/test_data/algo/murmur3-non-alpha.csv'), false)
end
