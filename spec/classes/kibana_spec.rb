# frozen_string_literal: true
require 'spec_helper'

describe 'kibana', :type => 'class' do
  let(:repo_baseurl)    { 'https://artifacts.elastic.co/packages' }
  let(:repo_key_id)     { '46095ACC8548582C1A2699A9D27D666CD88E42B4' }
  let(:repo_key_source) { 'https://artifacts.elastic.co/GPG-KEY-elasticsearch' }
  let(:repo_version)    { '5.x' }

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'kibana class without any parameters' do
          it { is_expected.to compile.with_all_deps }

          it 'sets expected defaults' do
            is_expected.to contain_class('kibana').with(
              :ensure => 'present',
              :manage_repo => true
            )
          end
          it { is_expected.to contain_class('kibana::params') }
          it 'declares install before config' do
            is_expected.to contain_class('kibana::install')
              .that_comes_before('Class[kibana::config]')
          end
          it { is_expected.to contain_class('kibana::config') }
          it 'subscribes service to config' do
            is_expected.to contain_class('kibana::service')
              .that_subscribes_to('Class[kibana::config]')
          end

          it 'installs the kibana config file' do
            is_expected.to contain_file('/etc/kibana/kibana.yml')
              .with_content(/
              # Managed by Puppet..
              ---.
              /xm)
          end

          it 'enables and starts the service' do
            is_expected.to contain_service('kibana').with(
              :ensure => true,
              :enable => true
            )
          end
          it { is_expected.to contain_package('kibana').with_ensure('present') }

          describe "#{facts[:osfamily]} resources" do
            case facts[:osfamily]
            when 'Debian'
              it { is_expected.to contain_class('apt') }
              it 'installs TLS support before updating the package cache' do
                is_expected.to contain_package('apt-transport-https')
                  .that_comes_before('Class[apt::update]')
              end
              it 'updates package cache before installing kibana' do
                is_expected.to contain_class('apt::update')
                  .that_comes_before('Package[kibana]')
              end
              it 'installs the repo apt source' do
                is_expected.to contain_apt__source('kibana')
                  .with(
                    :ensure   => 'present',
                    :location => "#{repo_baseurl}/#{repo_version}/apt",
                    :release  => 'stable',
                    :repos    => 'main',
                    :key      => {
                      'id'     => repo_key_id,
                      'source' => repo_key_source
                    },
                    :include => {
                      'src' => false,
                      'deb' => true
                    }
                  )
                  .that_comes_before('Package[kibana]')
              end
            when 'RedHat'
              it 'installs the yum repository' do
                is_expected.to contain_yumrepo('kibana')
                  .with(
                    :ensure   => 'present',
                    :descr    => "Elastic #{repo_version} repository",
                    :baseurl  => "#{repo_baseurl}/#{repo_version}/yum",
                    :gpgcheck => 1,
                    :gpgkey   => repo_key_source,
                    :enabled  => 1
                  )
                  .that_comes_before(
                    'Package[kibana]'
                  )
                  .that_notifies(
                    'Exec[kibana_yumrepo_yum_clean]'
                  )
                is_expected.to contain_exec('kibana_yumrepo_yum_clean')
                  .with(
                    :command     => 'yum clean metadata expire-cache --disablerepo="*" --enablerepo="kibana"',
                    :path        => ['/bin', '/usr/bin'],
                    :refreshonly => true,
                    :returns     => [0, 1]
                  )
                  .that_comes_before(
                    'Package[kibana]'
                  )
              end
            else
              pending "no tests for #{facts[:osfamily]}"
            end
          end
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'kibana class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta'
        }
      end

      it 'fails to compile' do
        expect { is_expected.to contain_package('kibana') }
          .to raise_error(Puppet::Error, /Nexenta not supported/)
      end
    end
  end
end
