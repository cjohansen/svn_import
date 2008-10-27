require 'fileutils'

#
# Import project into subversion, excluding logs, tmp files and database
# configuration (providing a template file instead)
#
# @author Christian Johansen (christian@cjohansen.no)
#
namespace :svn do
  desc "Import project into subversion repository"
  task :import do
    # Check that the project isn't already a working copy
    if File.exist?(".svn")
      match = `svn info`.match(/URL: ([^\n]*)\n/)
      puts "Application is already a working copy of #{match[1]}, aborting"
      exit
    end

    # Verify that we have the repository
    unless ENV.key? "REPOS"
      puts "Usage: rake svn:import REPOS=https://svn.mysite.com/repos [NOCOMMIT]"
      exit
    end

    # Get app name and full repos URL
    app = File.basename(Dir.pwd)
    repos = File.join(ENV['REPOS'], app, "trunk")

    puts "Adding application #{app} to subversion: #{repos}"

    # Create repository
    `svn mkdir --parents #{repos} -m "Creating repository for application"`
    `svn co #{repos} .`

    # Remove standard rails files
    puts "Removing default index.html and favicon"
    File.delete("public/favicon.ico") if File.exist?("public/favicon.ico")
    File.delete("public/index.html") if File.exist?("public/index.html")

    # Create templates from default config files
    puts "Creating template files for database.yml and environment.rb"
    %w{database.yml environment.rb}.each do |file|
      file = "config/#{file}"
      tmp_file = "#{file}.default"
      FileUtils.copy(file, tmp_file) unless File.exist?(tmp_file)
    end

    # Add to subversion
    puts "Adding applicaton sources to svn"
    `svn add app/ db/ doc/ lib/ public/ Rakefile README script/ test/ vendor/`
    `svn add -N config/ log/ tmp/`
    to_add = %w{routes.rb database.yml.default boot.rb initializers/ environments/ environment.rb.default}
    to_add = to_add.inject("") { |str, file| str += " config/#{file}" }
    `svn add#{to_add}`

    # Ignore resources
    puts "Ignoring selected resources"
    `svn propset svn:ignore "#{"database.yml\nenvironment.rb"}" .`
    `svn propset svn:ignore "*" log/`
    `svn add -N tmp/pids/ tmp/cache/ tmp/sessions/ tmp/sockets/`
    `svn propset svn:ignore "*" tmp/pids/`
    `svn propset svn:ignore "*" tmp/cache/`
    `svn propset svn:ignore "*" tmp/sessions/`
    `svn propset svn:ignore "*" tmp/sockets/`

    # Commit
    unless ENV.key?('NOCOMMIT')
      puts "Commiting..."
      `svn commit -m "Importing application skeleton"`
    end
  end
end
