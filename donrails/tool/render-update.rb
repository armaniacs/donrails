#!/usr/bin/env ruby

# This file is maked for fixing such a warning.
#
# ..DEPRECATION WARNING: Calling render with a string will render a partial from Rails 2.3. Change this call to render(:file => 'admin/shared/table_article', :locals => locals_hash).. (called from render at /opt/local/lib/ruby/gems/1.8/gems/actionpack-2.2.2/lib/action_view/base.rb:243)

require 'getoptlong'

def renderupdate(filename, render_opt = nil)
  file = File.open(filename)
  alines = ""
  cf = false

  file.each do |line|
    if line =~ /<%= render\s*\((.+),\s*(.+)\)\s*%>/
      f0 = $`
      f1 = $1
      f2 = $2
      f3 = $'

      if f2 =~ /^\"(\w+)\"/
        g1 = $1
        g2 = $'
      end

      alines += f0 + "<%= render :template => " + f1 + ", :locals => {:" + g1 + g2 + "}" + f3 + " %>\n"
      cf = true

    elsif line =~ /<%= render\s*\((.+)\)\s*%>/
      p line if render_opt[:debug]
      f0 = $`
      f1 = $1
      fe = $'
      p f0, f1, fe if render_opt[:debug]
      puts f0 + "<%= render :file => " + f1 + " %>" + fe if render_opt[:debug]

      alines += f0 + "<%= render(:file => " + f1 + ") %>" + fe
      cf = true

    else
      alines += line
    end
  end
  file.close

  if cf == true
    if render_opt[:dry_run] == true
      puts "***" + filename + "is changing (dry-run)"
    else
      File.rename(filename, filename + '.orig-ru')
      file2 = File.open(filename, "w")
      file2 << alines
      file2.close
    end
  else

  end
end

render_opt = Hash.new
parser = GetoptLong.new
parser.set_options(['--dry-run', '-n', GetoptLong::NO_ARGUMENT],
                   ['--debug', '-v', GetoptLong::NO_ARGUMENT])

parser.each_option do |name, arg|
  case name
  when "--dry-run"
    puts "*** dry-run mode"
    render_opt[:dry_run] = true
  when "--debug"
    puts "*** debug mode"
    render_opt[:dry_run] = true
  end
end

ARGV.each do |filename|
  begin
    renderupdate(filename, render_opt)
  rescue
    p $!
    puts "fail #{filename}"
  end
end

