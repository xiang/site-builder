require 'rubygems'
require 'yaml'
require 'deep_merge'

# this thing reads VM config parameters from flat files
# in order of specificity
# global defaults first
# then role defaults
# then individual hosts
#
# issues:
# host folder can't contain any bogus files
# invalid json causes cryptic string error with vagrant

      
module HostBuilder

  $basedir = File.expand_path('..')
#  $basedir = Dir.pwd
  $global_defaults = YAML.load_file("#{$basedir}/global.defaults")

  class Host

    attr_reader :config

    def initialize(host_path, site_defaults)

      # load host specific params
      host_config = YAML.load_file(host_path)

      hostname = File.basename(host_path) # hostname is filename

      fqdn = "#{hostname}.changeme"

      # hash containing all params
      @config = {}  

      @config['hostname'] = hostname
      @config['fqdn'] = fqdn

      # start with global defaults
      @config.deep_merge! $global_defaults

      # add role defaults
      role_defaults = YAML.load_file("#{$basedir}/roles/#{role}") || {}
      role_defaults.delete_if { |k,v| v.nil? } || {}
      @config.deep_merge! role_defaults

      # add site defaults
      @config.deep_merge! site_defaults

      # add host specific settings 
      @config.deep_merge! host_config

    end

    # fancy way to access instance variables
    
    def method_missing(name, *args)
      @config.fetch(name.to_s, nil)
    end

  end

  class Builder

    attr_reader :hosts

    def initialize(site)
      site_defaults = YAML.load_file("#{$basedir}/#{site}/site.defaults").delete_if { |k, v| v.nil? }

      # build a list of Host objects
      @hosts = Dir.glob("#{$basedir}/#{site}/hosts/*").map do |host_path|  
        Host.new(host_path, site_defaults) 
      end

    end
  end
end
