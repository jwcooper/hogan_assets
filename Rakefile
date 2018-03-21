require 'bundler'
Bundler.setup

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts = ['-Itest']
  t.ruby_opts << '-rubygems' if defined? Gem
  t.warning = false
end
