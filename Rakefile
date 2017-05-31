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
  desc "Performs a clean"
  task :clean do
    Dir.chdir $0 do
      sh Shellwords.shelljoin [
        "swift",
        "package",
        "clean",
      ]
    end
  end

  desc "Perform a debug build"
  task :debug do
    Dir.chdir $0 do
      configuration = "debug"
      sh Shellwords.shelljoin [
        "swift",
        "build",
        "-c", configuration,
      ]
      _fix_chttp_load_command(configuration)
    end
  end

  desc "Perform a release build"
  task :release do
    Dir.chdir $0 do
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
end

desc "Deploys the application"
task :deploy do
  Rake::Task['build:clean'].invoke
  Rake::Task['build:release'].invoke
  Dir.chdir "#{$0}/ansible" do
    sh Shellwords.shelljoin [
      "ansible-playbook",
      "-i", "hosts",
      "deploy.yml",
      "--vault-password-file", "~/.bnivault",
    ]
  end
end
