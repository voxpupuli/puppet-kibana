require 'spec_helper_acceptance'

describe 'kibana class' do
  context 'example manifest' do
    before(:all) { @port = 5602 }
    let(:manifest) do
      <<-EOS
        class { 'kibana':
          config => {
            'server.host' => '0.0.0.0',
            'server.port' => #{@port},
          }
        }
      EOS
    end

    it 'should work idempotently with no errors' do
      apply_manifest(manifest, :catch_failures => true)
      apply_manifest(manifest, :catch_changes  => true)
    end

    describe package('kibana') do
      it { is_expected.to be_installed }
    end

    describe service('kibana') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    describe port(@port) { it { should be_listening } }

    describe server :container do
      describe http('http://localhost:5602') do
        it('is ok', :api) { expect(response.status).to eq(200) }
        it('works', :api) { expect(response['kbn-name']).to eq('kibana') }
      end
    end
  end
end
