require 'spec_helper_acceptance'

describe 'kibana class' do
  before(:all) { @port = 5602 }

  context 'example manifest' do
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
        it('returns OK', :api) { expect(response.status).to eq(200) }
        it('is live', :api) { expect(response['kbn-name']).to eq('kibana') }
      end
    end
  end

  context 'removal' do
    let(:manifest) do
      <<-EOS
        class { 'kibana':
          ensure => absent,
        }
      EOS
    end

    it 'should work idempotently with no errors' do
      apply_manifest(manifest, :catch_failures => true)
      apply_manifest(manifest, :catch_changes  => true)
    end

    describe package('kibana') do
      it { should_not be_installed }
    end

    describe service('kibana') do
      it { should_not be_enabled }
      it { should_not be_running }
    end

    describe port(@port) { it { should_not be_listening } }
  end
end
