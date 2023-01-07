# frozen_string_literal: true

require 'spec_helper'
describe 'kibana::hash2yaml' do
  context 'with header' do
    it do
      is_expected.to run.with_params({ cle: 1 }, { header: '# HEADER' }).and_return('# HEADER\ncle: 1')
    end
  end

  context 'without header' do
    it do
      is_expected.to run.with_params({ cle: 1 }).and_return('# File managed by Puppet.\ncle: 1')
    end
  end
end
