require 'fileutils'

#
# After checking a project out from subversion, this task will copy template
# files for the developer to edit.
#
namespace :svn do
  desc "Sets up application from subversion"
  task :setup do
    Dir.glob("**/*.default").each do |tmp_file|
      file = tmp_file.sub(/\.default$/, "")
      FileUtils.copy(tmp_file, file) unless File.exist?(file)
      puts "Created #{file} from template"
    end
  end
end
