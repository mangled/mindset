# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
tasks = Jeweler::Tasks.new do |gem|
  gem.name = "mindset"
  gem.homepage = "http://github.com/mangled/mindset"
  gem.license = "MIT"
  gem.summary = %Q{A ruby gem for connecting to the NeuroSky mindset}
  gem.description = %Q{A ruby gem for connecting to the NeuroSky mindset}
  gem.email = "mindset@mangled.me"
  gem.authors = ["mangled"]
  gem.extensions = ['ext/mindset_device/extconf.rb']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rake/extensiontask'
Rake::ExtensionTask.new('mindset_device', tasks.gemspec)

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mindset #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
