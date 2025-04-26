require 'spec_helper'

RSpec.describe Kisa do
  describe '.initialize' do
    subject { described_class.new(url:, headers:) }

    context 'given url is nil' do
      let(:url) { nil }
      let(:headers) { { 'Authorization' => 'dummy_token' } }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'given headers is nil' do
      let(:url) { 'https://www.example.com' }
      let(:headers) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'given correct argument' do
      let(:url) { 'https://www.example.com' }
      let(:headers) { { 'Authorization' => 'dummy_token' } }

      it 'should return Kisa instance' do
        expect(subject).to be_instance_of(Kisa)
      end
    end
  end
end
