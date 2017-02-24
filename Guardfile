# frozen_string_literal: true
notification :tmux, display_message: true

guard :bundler do
  watch('Gemfile')
end

guard 'rake', :task => 'test' do
  watch(%r{^manifests\/(.+)\.pp$})
end

guard :rspec, :cmd => 'rspec' do
  watch(%r{^spec\/(classes|templates)\/(.+)\_spec.rb$})
end
