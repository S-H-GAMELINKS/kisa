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
end
