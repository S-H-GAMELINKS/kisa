require 'spec_helper'
require 'json'

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

  describe 'health_stream' do
    subject { described_class.new(url:, headers:).health_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Health Streaming API' do
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

            # Then simulate health check events
            if callback_proc
              callback_proc.call('event', 'data: ok')
              callback_proc.call('event', 'data: ok')
              callback_proc.call('event', 'data: ok')
            end
          end
        end

        it 'should receive multiple health check events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', 'data: ok']
          expect(received_events[1]).to eq ['event', 'data: ok']
          expect(received_events[2]).to eq ['event', 'data: ok']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'notification_stream' do
    subject { described_class.new(url:, headers:).notification_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Notification Streaming API' do
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

            # Then simulate notification events
            if callback_proc
              callback_proc.call('event', '{"event":"notification","payload":{"type":"mention","id":"1"}}')
              callback_proc.call('event', '{"event":"notification","payload":{"type":"follow","id":"2"}}')
              callback_proc.call('event', '{"event":"notification","payload":{"type":"reblog","id":"3"}}')
            end
          end
        end

        it 'should receive multiple notification events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"notification","payload":{"type":"mention","id":"1"}}']
          expect(received_events[1]).to eq ['event', '{"event":"notification","payload":{"type":"follow","id":"2"}}']
          expect(received_events[2]).to eq ['event', '{"event":"notification","payload":{"type":"reblog","id":"3"}}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'public_stream' do
    subject { described_class.new(url:, headers:).public_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Public Streaming API' do
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

            # Then simulate public timeline events
            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Public post 1","visibility":"public"}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Public post 2","visibility":"public"}}')
              callback_proc.call('event', '{"event":"delete","payload":"123456"}')
            end
          end
        end

        it 'should receive multiple public timeline events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Public post 1","visibility":"public"}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Public post 2","visibility":"public"}}']
          expect(received_events[2]).to eq ['event', '{"event":"delete","payload":"123456"}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'public_local_stream' do
    subject { described_class.new(url:, headers:).public_local_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Local Public Streaming API' do
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

            # Then simulate local timeline events
            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Local post 1","visibility":"public","local":true}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Local post 2","visibility":"unlisted","local":true}}')
              callback_proc.call('event', '{"event":"status.update","payload":{"content":"Edited local post","local":true}}')
            end
          end
        end

        it 'should receive multiple local timeline events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Local post 1","visibility":"public","local":true}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Local post 2","visibility":"unlisted","local":true}}']
          expect(received_events[2]).to eq ['event', '{"event":"status.update","payload":{"content":"Edited local post","local":true}}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'public_remote_stream' do
    subject { described_class.new(url:, headers:).public_remote_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Remote Public Streaming API' do
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

            # Then simulate remote timeline events
            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Remote post from other.server","visibility":"public","local":false}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Another remote post","visibility":"public","local":false}}')
              callback_proc.call('event', '{"event":"delete","payload":"789012"}')
            end
          end
        end

        it 'should receive multiple remote timeline events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Remote post from other.server","visibility":"public","local":false}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Another remote post","visibility":"public","local":false}}']
          expect(received_events[2]).to eq ['event', '{"event":"delete","payload":"789012"}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe '#hashtag_timeline' do
    subject { described_class.new(url:, headers:).hashtag_timeline(hashtag, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:hashtag) { 'ruby' }
    let(:params) { {} }

    context 'when hashtag is nil' do
      let(:hashtag) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
      end
    end

    context 'when hashtag is empty' do
      let(:hashtag) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
      end
    end

    context 'when hashtag has # prefix' do
      let(:hashtag) { '#ruby' }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/tag/ruby').and_return(response)
      end

      it 'should remove # prefix' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/tag/ruby')
      end
    end

    context 'with query parameters' do
      let(:params) { { limit: 10, local: true, only_media: true } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/tag/ruby?limit=10&local=true&only_media=true').and_return(response)
      end

      it 'should include valid parameters in URL' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/tag/ruby?limit=10&local=true&only_media=true')
      end
    end

    context 'with array parameters' do
      let(:params) { { any: ['tech', 'programming'], all: ['news'], limit: 5 } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/tag/ruby?any[]=tech&any[]=programming&all[]=news&limit=5').and_return(response)
      end

      it 'should handle array parameters correctly' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/tag/ruby?any[]=tech&any[]=programming&all[]=news&limit=5')
      end
    end

    context 'with invalid parameters' do
      let(:params) { { invalid_param: 'value', limit: 20 } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/tag/ruby?limit=20').and_return(response)
      end

      it 'should filter out invalid parameters' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/tag/ruby?limit=20')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to fetch hashtag timeline: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end

    context 'when request succeeds' do
      let(:timeline_data) { [
        { 'id' => '1', 'content' => 'Post about #ruby' },
        { 'id' => '2', 'content' => 'Another #ruby post' }
      ] }
      let(:response) { double('response', success?: true, body: timeline_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(timeline_data)
      end
    end
  end

  describe '#boost' do
    subject { described_class.new(url:, headers:).boost(status_id, visibility: visibility) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }
    let(:visibility) { 'public' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when visibility is invalid' do
      let(:visibility) { 'invalid' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'visibility must be one of: public, unlisted, private, direct')
      end
    end

    context 'when visibility is valid' do
      let(:visibility) { 'unlisted' }
      let(:response) { double('response', success?: true, body: '{"id":"123456","reblogged":true}') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/reblog', '{"visibility":"unlisted"}', { 'Content-Type' => 'application/json' }).and_return(response)
      end

      it 'should make POST request with correct visibility' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/reblog', '{"visibility":"unlisted"}', { 'Content-Type' => 'application/json' })
      end
    end

    context 'when using default visibility' do
      subject { described_class.new(url:, headers:).boost(status_id) }

      let(:response) { double('response', success?: true, body: '{"id":"123456","reblogged":true}') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/reblog', '{"visibility":"public"}', { 'Content-Type' => 'application/json' }).and_return(response)
      end

      it 'should use public as default visibility' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/reblog', '{"visibility":"public"}', { 'Content-Type' => 'application/json' })
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to boost status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end

    context 'when request succeeds' do
      let(:boost_data) { { 'id' => '123456', 'reblogged' => true, 'reblogs_count' => 5 } }
      let(:response) { double('response', success?: true, body: boost_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(boost_data)
      end
    end
  end

  describe 'direct_stream' do
    subject { described_class.new(url:, headers:).direct_stream(&block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc { } }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Direct Message Streaming API' do
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

            # Then simulate direct message events
            if callback_proc
              callback_proc.call('event', '{"event":"conversation","payload":{"id":"1","last_status":{"content":"Hello!","visibility":"direct"}}}')
              callback_proc.call('event', '{"event":"conversation","payload":{"id":"2","last_status":{"content":"Private message","visibility":"direct"}}}')
              callback_proc.call('event', '{"event":"conversation","payload":{"id":"3","last_status":{"content":"Another DM","visibility":"direct"}}}')
            end
          end
        end

        it 'should receive multiple direct message events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"conversation","payload":{"id":"1","last_status":{"content":"Hello!","visibility":"direct"}}}']
          expect(received_events[1]).to eq ['event', '{"event":"conversation","payload":{"id":"2","last_status":{"content":"Private message","visibility":"direct"}}}']
          expect(received_events[2]).to eq ['event', '{"event":"conversation","payload":{"id":"3","last_status":{"content":"Another DM","visibility":"direct"}}}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe '#favourite' do
    subject { described_class.new(url:, headers:).favourite(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:favourite_data) { { 'id' => '123456', 'favourited' => true, 'favourites_count' => 3 } }
      let(:response) { double('response', success?: true, body: favourite_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/favourite').and_return(response)
      end

      it 'should make POST request to favourite endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/favourite')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(favourite_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to favourite status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#home_timeline' do
    subject { described_class.new(url:, headers:).home_timeline(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'without parameters' do
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/home').and_return(response)
      end

      it 'should request home timeline endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/home')
      end
    end

    context 'with query parameters' do
      let(:params) { { limit: 20, max_id: '12345' } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/home?limit=20&max_id=12345').and_return(response)
      end

      it 'should include valid parameters in URL' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/home?limit=20&max_id=12345')
      end
    end

    context 'when request succeeds' do
      let(:timeline_data) { [
        { 'id' => '1', 'content' => 'Home timeline post 1' },
        { 'id' => '2', 'content' => 'Home timeline post 2' }
      ] }
      let(:response) { double('response', success?: true, body: timeline_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(timeline_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to fetch timeline: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#public_timeline' do
    subject { described_class.new(url:, headers:).public_timeline(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'without parameters' do
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/public').and_return(response)
      end

      it 'should request public timeline endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/public')
      end
    end

    context 'with local parameter' do
      let(:params) { { local: true, limit: 10 } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/public?local=true&limit=10').and_return(response)
      end

      it 'should include local parameter in URL' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/public?local=true&limit=10')
      end
    end

    context 'with only_media parameter' do
      let(:params) { { only_media: true, remote: true } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/public?only_media=true&remote=true').and_return(response)
      end

      it 'should include media and remote parameters in URL' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/public?only_media=true&remote=true')
      end
    end

    context 'when request succeeds' do
      let(:timeline_data) { [
        { 'id' => '1', 'content' => 'Public post 1' },
        { 'id' => '2', 'content' => 'Public post 2' }
      ] }
      let(:response) { double('response', success?: true, body: timeline_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(timeline_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 500, body: 'Server error') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to fetch timeline: 500 Server error')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::TimeoutError)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#list_timeline' do
    subject { described_class.new(url:, headers:).list_timeline(list_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:list_id) { '123' }
    let(:params) { {} }

    context 'when list_id is nil' do
      let(:list_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'list_id is required')
      end
    end

    context 'when list_id is empty' do
      let(:list_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'list_id is required')
      end
    end

    context 'with valid list_id' do
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/list/123').and_return(response)
      end

      it 'should request list timeline endpoint with list_id' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/list/123')
      end
    end

    context 'with query parameters' do
      let(:params) { { limit: 15, since_id: '999' } }
      let(:response) { double('response', success?: true, body: '[]') }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/timelines/list/123?limit=15&since_id=999').and_return(response)
      end

      it 'should include valid parameters in URL' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/timelines/list/123?limit=15&since_id=999')
      end
    end

    context 'when request succeeds' do
      let(:timeline_data) { [
        { 'id' => '1', 'content' => 'List post 1' },
        { 'id' => '2', 'content' => 'List post 2' }
      ] }
      let(:response) { double('response', success?: true, body: timeline_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(timeline_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'List not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to fetch timeline: 404 List not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::SSLError)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'hashtag_stream' do
    subject { described_class.new(url:, headers:).hashtag_stream(hashtag, &block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:hashtag) { 'ruby' }

    describe 'about hashtag parameter validation' do
      context 'when hashtag is nil' do
        let(:hashtag) { nil }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
        end
      end

      context 'when hashtag is empty string' do
        let(:hashtag) { '' }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
        end
      end

      context 'when hashtag has # prefix' do
        let(:hashtag) { '#ruby' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to eq('/api/v1/streaming/hashtag?tag=ruby')
          end
        end

        it 'should remove # prefix and encode correctly' do
          subject
        end
      end

      context 'when hashtag contains Unicode characters' do
        let(:hashtag) { 'プログラミング' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to include('tag=%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0')
          end
        end

        it 'should URL encode Unicode characters correctly' do
          subject
        end
      end

      context 'when hashtag contains emoji' do
        let(:hashtag) { '❤️' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to include('tag=')
          end
        end

        it 'should URL encode emoji correctly' do
          subject
        end
      end

      context 'when hashtag contains spaces' do
        let(:hashtag) { 'ruby rails' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to include('tag=ruby+rails')
          end
        end

        it 'should URL encode spaces correctly' do
          subject
        end
      end
    end

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc {} }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Hashtag Streaming API' do
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

            callback_proc = nil
            allow(response_options).to receive(:on_data=) do |proc|
              callback_proc = proc
            end

            block.call(response)

            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Post with #ruby","tags":[{"name":"ruby"}]}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Another #ruby post","tags":[{"name":"ruby"}]}}')
              callback_proc.call('event', '{"event":"delete","payload":"12345"}')
            end
          end
        end

        it 'should receive multiple hashtag stream events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Post with #ruby","tags":[{"name":"ruby"}]}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Another #ruby post","tags":[{"name":"ruby"}]}}']
          expect(received_events[2]).to eq ['event', '{"event":"delete","payload":"12345"}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'hashtag_local_stream' do
    subject { described_class.new(url:, headers:).hashtag_local_stream(hashtag, &block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:hashtag) { 'rails' }

    describe 'about hashtag parameter validation' do
      context 'when hashtag is nil' do
        let(:hashtag) { nil }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
        end
      end

      context 'when hashtag is empty string' do
        let(:hashtag) { '' }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'hashtag is required')
        end
      end

      context 'when hashtag has # prefix' do
        let(:hashtag) { '#rails' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to eq('/api/v1/streaming/hashtag/local?tag=rails')
          end
        end

        it 'should remove # prefix and encode correctly' do
          subject
        end
      end
    end

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc {} }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to Local Hashtag Streaming API' do
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

            callback_proc = nil
            allow(response_options).to receive(:on_data=) do |proc|
              callback_proc = proc
            end

            block.call(response)

            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Local post with #rails","local":true,"tags":[{"name":"rails"}]}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Another local #rails post","local":true,"tags":[{"name":"rails"}]}}')
            end
          end
        end

        it 'should receive multiple local hashtag stream events' do
          subject

          expect(received_events.length).to eq 2
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Local post with #rails","local":true,"tags":[{"name":"rails"}]}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Another local #rails post","local":true,"tags":[{"name":"rails"}]}}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe 'list_stream' do
    subject { described_class.new(url:, headers:).list_stream(list_id, &block) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:list_id) { 12345 }

    describe 'about list_id parameter validation' do
      context 'when list_id is nil' do
        let(:list_id) { nil }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'list_id is required')
        end
      end

      context 'when list_id is empty string' do
        let(:list_id) { '' }
        let(:block) { proc {} }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError, 'list_id is required')
        end
      end

      context 'when list_id is Integer' do
        let(:list_id) { 12345 }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to eq('/api/v1/streaming/list?list=12345')
          end
        end

        it 'should convert Integer to String correctly' do
          subject
        end
      end

      context 'when list_id is String' do
        let(:list_id) { '67890' }
        let(:block) { proc {} }
        let(:connection) { instance_double(Faraday::Connection) }

        before do
          allow(Faraday).to receive(:new).and_return(connection)
          allow(connection).to receive(:get) do |url, &blk|
            expect(url).to eq('/api/v1/streaming/list?list=67890')
          end
        end

        it 'should use String list_id directly' do
          subject
        end
      end
    end

    describe 'about block argument' do
      context 'when block was not given' do
        let(:block) { nil }

        it 'should raise ArgumentError' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when block was given' do
        let(:block) { proc {} }

        it 'should not raise error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    describe 'about connect to List Streaming API' do
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

            callback_proc = nil
            allow(response_options).to receive(:on_data=) do |proc|
              callback_proc = proc
            end

            block.call(response)

            if callback_proc
              callback_proc.call('event', '{"event":"update","payload":{"content":"Post from list member","account":{"username":"alice"}}}')
              callback_proc.call('event', '{"event":"update","payload":{"content":"Another post from list","account":{"username":"bob"}}}')
              callback_proc.call('event', '{"event":"notification","payload":{"type":"mention","account":{"username":"alice"}}}')
            end
          end
        end

        it 'should receive multiple list stream events' do
          subject

          expect(received_events.length).to eq 3
          expect(received_events[0]).to eq ['event', '{"event":"update","payload":{"content":"Post from list member","account":{"username":"alice"}}}']
          expect(received_events[1]).to eq ['event', '{"event":"update","payload":{"content":"Another post from list","account":{"username":"bob"}}}']
          expect(received_events[2]).to eq ['event', '{"event":"notification","payload":{"type":"mention","account":{"username":"alice"}}}']
        end

        it 'should not raise error when streaming' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe '#get_status' do
    subject { described_class.new(url:, headers:).get_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:status_data) { { 'id' => '123456', 'content' => 'Hello World', 'favourites_count' => 5 } }
      let(:response) { double('response', success?: true, body: status_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456').and_return(response)
      end

      it 'should make GET request to status endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(status_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#delete_status' do
    subject { described_class.new(url:, headers:).delete_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:delete_data) { { 'id' => '123456', 'text' => 'Deleted status content' } }
      let(:response) { double('response', success?: true, body: delete_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:delete).with('/api/v1/statuses/123456').and_return(response)
      end

      it 'should make DELETE request to status endpoint' do
        subject
        expect(connection).to have_received(:delete).with('/api/v1/statuses/123456')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(delete_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:delete).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to delete status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:delete).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unfavourite' do
    subject { described_class.new(url:, headers:).unfavourite(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:unfavourite_data) { { 'id' => '123456', 'favourited' => false, 'favourites_count' => 2 } }
      let(:response) { double('response', success?: true, body: unfavourite_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/unfavourite').and_return(response)
      end

      it 'should make POST request to unfavourite endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/unfavourite')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(unfavourite_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unfavourite status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unboost' do
    subject { described_class.new(url:, headers:).unboost(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:unboost_data) { { 'id' => '123456', 'reblogged' => false, 'reblogs_count' => 1 } }
      let(:response) { double('response', success?: true, body: unboost_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/unreblog').and_return(response)
      end

      it 'should make POST request to unreblog endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/unreblog')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(unboost_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unboost status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#bookmark' do
    subject { described_class.new(url:, headers:).bookmark(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:bookmark_data) { { 'id' => '123456', 'bookmarked' => true } }
      let(:response) { double('response', success?: true, body: bookmark_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/bookmark').and_return(response)
      end

      it 'should make POST request to bookmark endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/bookmark')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(bookmark_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to bookmark status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unbookmark' do
    subject { described_class.new(url:, headers:).unbookmark(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:unbookmark_data) { { 'id' => '123456', 'bookmarked' => false } }
      let(:response) { double('response', success?: true, body: unbookmark_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/unbookmark').and_return(response)
      end

      it 'should make POST request to unbookmark endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/unbookmark')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(unbookmark_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unbookmark status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#pin_status' do
    subject { described_class.new(url:, headers:).pin_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:pin_data) { { 'id' => '123456', 'pinned' => true } }
      let(:response) { double('response', success?: true, body: pin_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/pin').and_return(response)
      end

      it 'should make POST request to pin endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/pin')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(pin_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 422, body: 'Validation failed') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to pin status: 422 Validation failed')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unpin_status' do
    subject { described_class.new(url:, headers:).unpin_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:unpin_data) { { 'id' => '123456', 'pinned' => false } }
      let(:response) { double('response', success?: true, body: unpin_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/unpin').and_return(response)
      end

      it 'should make POST request to unpin endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/unpin')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(unpin_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unpin status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#mute_status' do
    subject { described_class.new(url:, headers:).mute_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:mute_data) { { 'id' => '123456', 'muted' => true } }
      let(:response) { double('response', success?: true, body: mute_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/mute').and_return(response)
      end

      it 'should make POST request to mute endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/mute')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(mute_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to mute status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unmute_status' do
    subject { described_class.new(url:, headers:).unmute_status(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:unmute_data) { { 'id' => '123456', 'muted' => false } }
      let(:response) { double('response', success?: true, body: unmute_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/unmute').and_return(response)
      end

      it 'should make POST request to unmute endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/unmute')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(unmute_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unmute status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#get_status_context' do
    subject { described_class.new(url:, headers:).get_status_context(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:context_data) do
        {
          'ancestors' => [{ 'id' => '100', 'content' => 'Parent post' }],
          'descendants' => [{ 'id' => '102', 'content' => 'Reply post' }]
        }
      end
      let(:response) { double('response', success?: true, body: context_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/context').and_return(response)
      end

      it 'should make GET request to context endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/context')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(context_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get status context: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#get_status_history' do
    subject { described_class.new(url:, headers:).get_status_history(status_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds' do
      let(:history_data) do
        [
          { 'content' => 'Original content', 'created_at' => '2024-01-01T00:00:00Z' },
          { 'content' => 'Edited content', 'created_at' => '2024-01-02T00:00:00Z' }
        ]
      end
      let(:response) { double('response', success?: true, body: history_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/history').and_return(response)
      end

      it 'should make GET request to history endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/history')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(history_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get status history: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#reblogged_by' do
    subject { described_class.new(url:, headers:).reblogged_by(status_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }
    let(:params) { {} }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds without params' do
      let(:accounts_data) do
        [
          { 'id' => '1', 'username' => 'user1', 'acct' => 'user1' },
          { 'id' => '2', 'username' => 'user2', 'acct' => 'user2' }
        ]
      end
      let(:response) { double('response', success?: true, body: accounts_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/reblogged_by').and_return(response)
      end

      it 'should make GET request to reblogged_by endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/reblogged_by')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(accounts_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 20, max_id: '999' } }
      let(:accounts_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: accounts_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/reblogged_by?limit=20&max_id=999').and_return(response)
      end

      it 'should make GET request with query params' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/reblogged_by?limit=20&max_id=999')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get reblogged_by: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#favourited_by' do
    subject { described_class.new(url:, headers:).favourited_by(status_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }
    let(:params) { {} }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds without params' do
      let(:accounts_data) do
        [
          { 'id' => '1', 'username' => 'user1', 'acct' => 'user1' },
          { 'id' => '2', 'username' => 'user2', 'acct' => 'user2' }
        ]
      end
      let(:response) { double('response', success?: true, body: accounts_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/favourited_by').and_return(response)
      end

      it 'should make GET request to favourited_by endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/favourited_by')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(accounts_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 20, max_id: '999' } }
      let(:accounts_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: accounts_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/statuses/123456/favourited_by?limit=20&max_id=999').and_return(response)
      end

      it 'should make GET request with query params' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/statuses/123456/favourited_by?limit=20&max_id=999')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get favourited_by: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#translate_status' do
    subject { described_class.new(url:, headers:).translate_status(status_id, lang:) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }
    let(:lang) { nil }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when request succeeds without lang' do
      let(:translation_data) do
        {
          'content' => 'Translated text',
          'detected_source_language' => 'en',
          'provider' => 'DeepL'
        }
      end
      let(:response) { double('response', success?: true, body: translation_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/statuses/123456/translate').and_return(response)
      end

      it 'should make POST request to translate endpoint without body' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/statuses/123456/translate')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(translation_data)
      end
    end

    context 'when request succeeds with lang' do
      let(:lang) { 'ja' }
      let(:translation_data) do
        {
          'content' => '翻訳されたテキスト',
          'detected_source_language' => 'en',
          'provider' => 'DeepL'
        }
      end
      let(:response) { double('response', success?: true, body: translation_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with(
          '/api/v1/statuses/123456/translate',
          { lang: 'ja' }.to_json,
          { 'Content-Type' => 'application/json' }
        ).and_return(response)
      end

      it 'should make POST request with lang in body' do
        subject
        expect(connection).to have_received(:post).with(
          '/api/v1/statuses/123456/translate',
          { lang: 'ja' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(translation_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to translate status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#create_status' do
    subject { described_class.new(url:, headers:).create_status(status, options) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status) { 'Hello, Mastodon!' }
    let(:options) { {} }

    context 'when status is nil' do
      let(:status) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status is required')
      end
    end

    context 'when status is empty' do
      let(:status) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status is required')
      end
    end

    context 'when request succeeds without options' do
      let(:created_status) { { 'id' => '123456', 'content' => '<p>Hello, Mastodon!</p>' } }
      let(:response) { double('response', success?: true, body: created_status.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should make POST request to statuses endpoint' do
        subject
        expect(connection).to have_received(:post).with(
          '/api/v1/statuses',
          { status: 'Hello, Mastodon!' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(created_status)
      end
    end

    context 'when request succeeds with options' do
      let(:options) { { visibility: 'private', sensitive: true, spoiler_text: 'CW' } }
      let(:created_status) { { 'id' => '123456', 'content' => '<p>Hello, Mastodon!</p>', 'visibility' => 'private' } }
      let(:response) { double('response', success?: true, body: created_status.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should include options in request body' do
        subject
        expect(connection).to have_received(:post).with(
          '/api/v1/statuses',
          { status: 'Hello, Mastodon!', sensitive: true, spoiler_text: 'CW', visibility: 'private' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 422, body: 'Validation failed') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to create status: 422 Validation failed')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#edit_status' do
    subject { described_class.new(url:, headers:).edit_status(status_id, status, options) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:status_id) { '123456' }
    let(:status) { 'Edited content' }
    let(:options) { {} }

    context 'when status_id is nil' do
      let(:status_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status_id is empty' do
      let(:status_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status_id is required')
      end
    end

    context 'when status is nil' do
      let(:status) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status is required')
      end
    end

    context 'when status is empty' do
      let(:status) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'status is required')
      end
    end

    context 'when request succeeds without options' do
      let(:edited_status) { { 'id' => '123456', 'content' => '<p>Edited content</p>' } }
      let(:response) { double('response', success?: true, body: edited_status.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:put).and_return(response)
      end

      it 'should make PUT request to status endpoint' do
        subject
        expect(connection).to have_received(:put).with(
          '/api/v1/statuses/123456',
          { status: 'Edited content' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(edited_status)
      end
    end

    context 'when request succeeds with options' do
      let(:options) { { sensitive: true, spoiler_text: 'Updated CW' } }
      let(:edited_status) { { 'id' => '123456', 'content' => '<p>Edited content</p>', 'sensitive' => true } }
      let(:response) { double('response', success?: true, body: edited_status.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:put).and_return(response)
      end

      it 'should include options in request body' do
        subject
        expect(connection).to have_received(:put).with(
          '/api/v1/statuses/123456',
          { status: 'Edited content', sensitive: true, spoiler_text: 'Updated CW' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Status not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:put).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to edit status: 404 Status not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:put).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  # Accounts API

  describe '#get_account' do
    subject { described_class.new(url:, headers:).get_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:account_data) { { 'id' => '123456', 'username' => 'testuser', 'display_name' => 'Test User' } }
      let(:response) { double('response', success?: true, body: account_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should make GET request to account endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(account_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get account: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#verify_credentials' do
    subject { described_class.new(url:, headers:).verify_credentials }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }

    context 'when request succeeds' do
      let(:credential_data) { { 'id' => '123456', 'username' => 'testuser', 'source' => { 'privacy' => 'public' } } }
      let(:response) { double('response', success?: true, body: credential_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should make GET request to verify_credentials endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/verify_credentials')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(credential_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to verify credentials: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#account_statuses' do
    subject { described_class.new(url:, headers:).account_statuses(account_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }
    let(:params) { {} }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds without params' do
      let(:statuses_data) { [{ 'id' => '1', 'content' => 'Hello' }, { 'id' => '2', 'content' => 'World' }] }
      let(:response) { double('response', success?: true, body: statuses_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should make GET request to account statuses endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/statuses')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(statuses_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 10, only_media: true, exclude_replies: true } }
      let(:statuses_data) { [{ 'id' => '1', 'content' => 'Hello' }] }
      let(:response) { double('response', success?: true, body: statuses_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should include query parameters in request' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/statuses?limit=10&only_media=true&exclude_replies=true')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get account statuses: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#followers' do
    subject { described_class.new(url:, headers:).followers(account_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }
    let(:params) { {} }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds without params' do
      let(:followers_data) { [{ 'id' => '1', 'username' => 'user1' }, { 'id' => '2', 'username' => 'user2' }] }
      let(:response) { double('response', success?: true, body: followers_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should make GET request to followers endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/followers')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(followers_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 20, max_id: '999' } }
      let(:followers_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: followers_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should include query parameters in request' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/followers?limit=20&max_id=999')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get followers: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#following' do
    subject { described_class.new(url:, headers:).following(account_id, params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }
    let(:params) { {} }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds without params' do
      let(:following_data) { [{ 'id' => '1', 'username' => 'user1' }, { 'id' => '2', 'username' => 'user2' }] }
      let(:response) { double('response', success?: true, body: following_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should make GET request to following endpoint' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/following')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(following_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 20, max_id: '999' } }
      let(:following_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: following_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should include query parameters in request' do
        subject
        expect(connection).to have_received(:get).with('/api/v1/accounts/123456/following?limit=20&max_id=999')
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get following: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#follow' do
    subject { described_class.new(url:, headers:).follow(account_id, options) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }
    let(:options) { {} }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds without options' do
      let(:relationship_data) { { 'id' => '123456', 'following' => true, 'followed_by' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should make POST request to follow endpoint' do
        subject
        expect(connection).to have_received(:post).with(
          '/api/v1/accounts/123456/follow',
          {}.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request succeeds with options' do
      let(:options) { { reblogs: false, notify: true } }
      let(:relationship_data) { { 'id' => '123456', 'following' => true, 'notifying' => true } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should include options in request body' do
        subject
        expect(connection).to have_received(:post).with(
          '/api/v1/accounts/123456/follow',
          { reblogs: false, notify: true }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to follow account: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#unfollow' do
    subject { described_class.new(url:, headers:).unfollow(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123456' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123456', 'following' => false, 'followed_by' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should make POST request to unfollow endpoint' do
        subject
        expect(connection).to have_received(:post).with('/api/v1/accounts/123456/unfollow')
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Account not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unfollow account: 404 Account not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe '#update_credentials' do
    subject { described_class.new(url:, headers:).update_credentials(options) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:options) { {} }

    context 'when request succeeds without options' do
      let(:credential_data) { { 'id' => '123456', 'username' => 'testuser', 'display_name' => 'Test User' } }
      let(:response) { double('response', success?: true, body: credential_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:patch).and_return(response)
      end

      it 'should make PATCH request to update_credentials endpoint' do
        subject
        expect(connection).to have_received(:patch).with(
          '/api/v1/accounts/update_credentials',
          {}.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end

      it 'should return parsed JSON response' do
        expect(subject).to eq(credential_data)
      end
    end

    context 'when request succeeds with options' do
      let(:options) { { display_name: 'New Name', note: 'New bio', locked: true } }
      let(:credential_data) { { 'id' => '123456', 'display_name' => 'New Name', 'note' => 'New bio', 'locked' => true } }
      let(:response) { double('response', success?: true, body: credential_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:patch).and_return(response)
      end

      it 'should include options in request body' do
        subject
        expect(connection).to have_received(:patch).with(
          '/api/v1/accounts/update_credentials',
          { display_name: 'New Name', note: 'New bio', locked: true }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end
    end

    context 'when request succeeds with invalid options filtered out' do
      let(:options) { { display_name: 'New Name', invalid_option: 'should be ignored' } }
      let(:credential_data) { { 'id' => '123456', 'display_name' => 'New Name' } }
      let(:response) { double('response', success?: true, body: credential_data.to_json) }
      let(:connection) { instance_double(Faraday::Connection) }

      before do
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:patch).and_return(response)
      end

      it 'should filter out invalid options' do
        subject
        expect(connection).to have_received(:patch).with(
          '/api/v1/accounts/update_credentials',
          { display_name: 'New Name' }.to_json,
          { 'Content-Type' => 'application/json' }
        )
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 422, body: 'Validation failed') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:patch).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to update credentials: 422 Validation failed')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:patch).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  # Accounts API - Extended

  describe 'block_account' do
    subject { described_class.new(url:, headers:).block_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123', 'blocking' => true } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/block').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to block account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'unblock_account' do
    subject { described_class.new(url:, headers:).unblock_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123', 'blocking' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/unblock').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unblock account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'mute_account' do
    subject { described_class.new(url:, headers:).mute_account(account_id, options) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }
    let(:options) { {} }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds without options' do
      let(:relationship_data) { { 'id' => '123', 'muting' => true } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/mute').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request succeeds with options' do
      let(:options) { { notifications: false, duration: 3600 } }
      let(:relationship_data) { { 'id' => '123', 'muting' => true, 'muting_notifications' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with(
          '/api/v1/accounts/123/mute',
          { notifications: false, duration: 3600 }.to_json,
          { 'Content-Type' => 'application/json' }
        ).and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to mute account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'unmute_account' do
    subject { described_class.new(url:, headers:).unmute_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123', 'muting' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/unmute').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unmute account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'pin_account' do
    subject { described_class.new(url:, headers:).pin_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123', 'endorsed' => true } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/pin').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to pin account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'unpin_account' do
    subject { described_class.new(url:, headers:).unpin_account(account_id) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_id) { '123' }

    context 'when account_id is nil' do
      let(:account_id) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when account_id is empty' do
      let(:account_id) { '' }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_id is required')
      end
    end

    context 'when request succeeds' do
      let(:relationship_data) { { 'id' => '123', 'endorsed' => false } }
      let(:response) { double('response', success?: true, body: relationship_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).with('/api/v1/accounts/123/unpin').and_return(response)
      end

      it 'should return relationship data' do
        expect(subject).to eq(relationship_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 404, body: 'Not found') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to unpin account: 404 Not found')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:post).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'relationships' do
    subject { described_class.new(url:, headers:).relationships(account_ids) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:account_ids) { ['123', '456'] }

    context 'when account_ids is nil' do
      let(:account_ids) { nil }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_ids is required')
      end
    end

    context 'when account_ids is empty' do
      let(:account_ids) { [] }

      it 'should raise ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'account_ids is required')
      end
    end

    context 'when request succeeds with multiple ids' do
      let(:relationships_data) do
        [
          { 'id' => '123', 'following' => true, 'blocking' => false },
          { 'id' => '456', 'following' => false, 'blocking' => true }
        ]
      end
      let(:response) { double('response', success?: true, body: relationships_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/accounts/relationships?id[]=123&id[]=456').and_return(response)
      end

      it 'should return relationships data' do
        expect(subject).to eq(relationships_data)
      end
    end

    context 'when request succeeds with single id' do
      let(:account_ids) { '123' }
      let(:relationships_data) { [{ 'id' => '123', 'following' => true }] }
      let(:response) { double('response', success?: true, body: relationships_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/accounts/relationships?id[]=123').and_return(response)
      end

      it 'should return relationships data' do
        expect(subject).to eq(relationships_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get relationships: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'bookmarks' do
    subject { described_class.new(url:, headers:).bookmarks(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'when request succeeds without params' do
      let(:bookmarks_data) { [{ 'id' => '1', 'content' => 'Bookmark 1' }, { 'id' => '2', 'content' => 'Bookmark 2' }] }
      let(:response) { double('response', success?: true, body: bookmarks_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/bookmarks').and_return(response)
      end

      it 'should return bookmarks data' do
        expect(subject).to eq(bookmarks_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 10, max_id: '100' } }
      let(:bookmarks_data) { [{ 'id' => '1', 'content' => 'Bookmark 1' }] }
      let(:response) { double('response', success?: true, body: bookmarks_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/bookmarks?limit=10&max_id=100').and_return(response)
      end

      it 'should return bookmarks data' do
        expect(subject).to eq(bookmarks_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get bookmarks: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'favourites' do
    subject { described_class.new(url:, headers:).favourites(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'when request succeeds without params' do
      let(:favourites_data) { [{ 'id' => '1', 'content' => 'Favourite 1' }, { 'id' => '2', 'content' => 'Favourite 2' }] }
      let(:response) { double('response', success?: true, body: favourites_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/favourites').and_return(response)
      end

      it 'should return favourites data' do
        expect(subject).to eq(favourites_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 10, max_id: '100' } }
      let(:favourites_data) { [{ 'id' => '1', 'content' => 'Favourite 1' }] }
      let(:response) { double('response', success?: true, body: favourites_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/favourites?limit=10&max_id=100').and_return(response)
      end

      it 'should return favourites data' do
        expect(subject).to eq(favourites_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get favourites: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'mutes' do
    subject { described_class.new(url:, headers:).mutes(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'when request succeeds without params' do
      let(:mutes_data) { [{ 'id' => '1', 'username' => 'user1' }, { 'id' => '2', 'username' => 'user2' }] }
      let(:response) { double('response', success?: true, body: mutes_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/mutes').and_return(response)
      end

      it 'should return mutes data' do
        expect(subject).to eq(mutes_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 10, max_id: '100' } }
      let(:mutes_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: mutes_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/mutes?limit=10&max_id=100').and_return(response)
      end

      it 'should return mutes data' do
        expect(subject).to eq(mutes_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get mutes: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end

  describe 'blocks' do
    subject { described_class.new(url:, headers:).blocks(params) }

    let(:url) { 'https://www.example.com' }
    let(:headers) { { 'Authorization' => 'dummy_token' } }
    let(:params) { {} }

    context 'when request succeeds without params' do
      let(:blocks_data) { [{ 'id' => '1', 'username' => 'user1' }, { 'id' => '2', 'username' => 'user2' }] }
      let(:response) { double('response', success?: true, body: blocks_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/blocks').and_return(response)
      end

      it 'should return blocks data' do
        expect(subject).to eq(blocks_data)
      end
    end

    context 'when request succeeds with params' do
      let(:params) { { limit: 10, max_id: '100' } }
      let(:blocks_data) { [{ 'id' => '1', 'username' => 'user1' }] }
      let(:response) { double('response', success?: true, body: blocks_data.to_json) }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).with('/api/v1/blocks?limit=10&max_id=100').and_return(response)
      end

      it 'should return blocks data' do
        expect(subject).to eq(blocks_data)
      end
    end

    context 'when request fails' do
      let(:response) { double('response', success?: false, status: 401, body: 'Unauthorized') }

      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_return(response)
      end

      it 'should raise Kisa::Error' do
        expect { subject }.to raise_error(Kisa::Error, 'Failed to get blocks: 401 Unauthorized')
      end
    end

    context 'when connection fails' do
      before do
        connection = instance_double(Faraday::Connection)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::ConnectionFailed)
      end

      it 'should raise Kisa::ConnectionFailedError' do
        expect { subject }.to raise_error(Kisa::ConnectionFailedError)
      end
    end
  end
end
