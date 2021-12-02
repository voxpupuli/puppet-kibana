# frozen_string_literal: true

shared_examples 'basic acceptance' do
  context 'example manifest' do
    request_path = if RSpec.configuration.is_snapshot && !RSpec.configuration.oss
                     '/login'
                   else
                     ''
                   end

    it { apply_manifest(manifest, catch_failures: true) }
    it { apply_manifest(manifest, catch_changes: true) }

    describe package("kibana#{RSpec.configuration.oss ? '-oss' : ''}") do
      it { is_expected.to be_installed }
    end

    describe service('kibana') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(5602) { it { is_expected.to be_listening } }

    describe "http://localhost:5602#{request_path}" do
      # Kibana versions reply to requests differently depending upon whether
      # Elasticsearch is up and responding on the backend. In most cases we
      # just want to ensure that Kibana has installed and started, so testing
      # to confirm whether Kibana is replying with proper HTTP response codes
      # is sufficient (earlier versions return 200 in most cases, later
      # versions pass through ES unavailability as 503's).
      subject { shell("curl -o /dev/null -w '%{http_code}' http://localhost:5602#{request_path}") }

      it('returns OK', :api) do
        expect(subject.stdout.to_i).to eq(200).or(eq(503))
      end
    end
  end
end
