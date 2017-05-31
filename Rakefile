require 'shellwords'

namespace :build do
  desc "Perform a debug build"
  task :debug do
    sh Shellwords.shelljoin [
      "swift",
      "build",
      "-c", "debug",
    ]
  end

  desc "Perform a release build"
  task :release do
    sh Shellwords.shelljoin [
      "swift",
      "build",
      "-c", "release",
      "-Xswiftc", "-static-stdlib",
    ]
  end
end
