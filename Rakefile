require 'fileutils'
require 'shellwords'

$0 = File.expand_path(File.dirname(__FILE__))

def _fix_chttp_load_command(configuration_name)
  puts "Fix Kitura CHTTPParser load path"
  build_path = "#{$0}/.build/#{configuration_name}"
  sh Shellwords.shelljoin [
    "install_name_tool",
    "-change", "#{build_path}/libCHTTPParser.dylib",
    "@executable_path/libCHTTPParser.dylib",
    "#{build_path}/bazel-rest-cache",
  ]
end

namespace :build do
  desc "Perform a debug build"
  task :debug do
    configuration = "debug"
    sh Shellwords.shelljoin [
      "swift",
      "build",
      "-c", configuration,
    ]
    _fix_chttp_load_command(configuration)
  end

  desc "Perform a release build"
  task :release do
    configuration = "release"
    sh Shellwords.shelljoin [
      "swift",
      "build",
      "-c", configuration,
      "-Xswiftc", "-static-stdlib",
    ]
    _fix_chttp_load_command(configuration)
  end
end
