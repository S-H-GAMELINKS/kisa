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

  describe 'user_stream' do
    subject { described_class.new(url:, headers:).user_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect {subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Streaming API' do
      context 'when failed' do
        let(:block) { proc {} }

        before do
          connection = instance_double(Faraday::Connection)
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get).and_raise(error)
        end

        context 'when raise Faraday::ConnectionFailed in internal' do
          let(:error) { Faraday::ConnectionFailed }

          it 'should raise Kisa::ConnectionFailedError' do
            expect { subject }.to raise_error(Kisa::ConnectionFailedError)
          end
        end

        context 'when raise Faraday::TimeoutError in internal' do
          let(:error) { Faraday::TimeoutError }

          it 'should raise Kisa::ConnectionFailedError' do
            expect { subject }.to raise_error(Kisa::ConnectionFailedError)
          end
        end

        context 'when raise Faraday::SSLError in internal' do
          let(:error) { Faraday::SSLError }

          it 'should raise Kisa::ConnectionFailedError' do
            expect { subject }.to raise_error(Kisa::ConnectionFailedError)
          end
        end
      end

      context 'when successed' do
        let(:received_events) { [] }
        let(:block) { proc { |event_type, data| received_events << [event_type, data] } }

        before do
          connection = instance_double(Faraday::Connection)
          allow(Faraday).to receive(:new).and_return(connection)

          allow(connection).to receive(:get) do |&block|
            response = double('response')
            response_options = double('response_options')

            allow(response).to receive(:options).and_return(response_options)

            # Store callback when on_data= is called
            callback_proc = nil
            allow(response_options).to receive(:on_data=) do |proc|
              callback_proc = proc
            end

            # Yield response to the block first
            block.call(response)

            # Then simulate streaming events
            if callback_proc
              callback_proc.call('event', '{"type":"update","data":"first message"}')
              callback_proc.call('event', '{"type":"notification","data":"second message"}')
              callback_proc.call('event', '{"type":"update","data":"third message"}')
            end
          end
        end

        it 'should receive multiple streaming events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"type":"update","data":"first message"}']
          expect(received_events[1]).to eq ['event', '{"type":"notification","data":"second message"}']
          expect(received_events[2]).to eq ['event', '{"type":"update","data":"third message"}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
