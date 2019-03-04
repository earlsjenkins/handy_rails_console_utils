# Easy reloading of this file
def uload(reload_routes = false)
  @rails_routes_loaded = !reload_routes
  puts "Reloading #{__FILE__}..."
  load __FILE__
end

require 'active_record'
# Easier-to-read ActiveRecord inspection
class ActiveRecord::Base
  def self.fields
    inspect[/\((.*)\)/, 1].split(', ')
  end
end

class ActiveRecord::Base
  def self.[](id)
    self.send "find_by_#{self.primary_key}", id
  end
end

class ActiveRecord::Base
  def ems
    self.errors.full_messages
  end
end

class ActiveRecord::Base
  def self.change_db(new_db_name)
    conn_config = ActiveRecord::Base.connection_config
    conn_config[:database] = new_db_name
    ActiveRecord::Base.establish_connection conn_config
  end

  def self.db_name
    ActiveRecord::Base.connection_config[:database]
  end
end


# Load up the routes so you can call url_for-based magic methods
require 'action_controller'
def rails_routes
  unless @rails_routes_loaded
    puts "Loading routes..."
    if Rails.version > "3.0.9"
      include Rails.application.routes.url_helpers
    else
      include ActionController::UrlWriter
    end
    default_url_options[:host] = 'localhost:3000'
    @rails_routes_loaded = true
  end
end

rails_routes

def reroute(force = false)
  if Rails.version > "4.0"
    Rails.application.reload_routes!
  else
    ActionController::Routing::Routes.send(force ? :reload! : :reload)
  end
end


# Access the console history
def history
  Readline::HISTORY.to_a
end

def hgrep(match)
  matched = history.select {|h| begin Regexp.new(match).match(h) rescue nil end}
  puts matched
  matched.size
end


# Easy access to the fields/methods of a collection of duck-homogeneous objects
module Enumerable
  def mcollect(*syms)
    self.collect do |elem|
      syms.inject([]) do |collector, sym|
        collector << elem.send(sym)
      end
    end
  end
end


# Handy alias for the split method
class String
  alias / split
end


# Add JavaScript-like accessing of hash values by key
# Notice that this WILL NOT override any existing methods (magic or mundane)
class Hash
  def method_missing(sym, *args, &block)
    begin
      super
    rescue NoMethodError => nme
      if self.has_key?(sym)
        self.fetch(sym)
      elsif self.has_key?(sym.to_s)
        self.fetch(sym.to_s)
      elsif pos = sym.to_s =~ /(=$)/
        self.send(:store, sym.to_s[0..pos-1].to_sym, *args)
      else
        raise nme
      end
    end
  end

  def respond_to?(sym, include_private = false)
    super || self.has_key?(sym) || self.has_key?(sym.to_s)
  end
end

# Reverse-find element in an Array
class Array
  def rfind(*args, &block)
    i = rindex(*args, &block)
    i && self[i]
  end
end

# Memory usage
def curr_mem
  `ps -o rss= -p #{Process.pid}`.to_i
end

def mem_profile
  mem_before = curr_mem
  yield
  mem_after = curr_mem
  mem_diff = mem_after - mem_before
  puts "Before: #{mem_before}"
  puts "After: #{mem_after}"
  puts "Difference: #{mem_diff}"
  mem_diff
end


# Only works in Rails 2
if Rails.configuration.respond_to? :gems

  #########################################
  ## STOLEN FROM gems.rake ################
  #########################################
  
  def print_gem_status(gem, indent=1)
    code = case
      when gem.framework_gem? then 'R'
      when gem.frozen?        then 'F'
      when gem.installed?     then 'I'
      else                         ' '
    end
    puts "   "*(indent-1)+" - [#{code}] #{gem.name} #{gem.requirement.to_s}"
    gem.dependencies.each { |g| print_gem_status(g, indent+1) }
  end
  
  # Same as gems:base task
  def print_all_gems
    Rails.configuration.gems.each do |gem|
      print_gem_status(gem)
    end
    puts
    puts "I = Installed"
    puts "F = Frozen"
    puts "R = Framework (loaded before rails starts)"
  end

end

