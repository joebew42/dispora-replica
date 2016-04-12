require "diaspora_api"
require "logger"

module Diaspora
  module Replica
  end
end

module Diaspora::Replica::API
  attr_writer :logdir

  def logdir
    @logdir || "/tmp"
  end

  def logger
    return @logger unless @logger.nil?
    file = File.new("#{logdir}/#{Time.now.utc.to_i}.log", "w")
    file.sync = true
	  @logger = Logger.new(file)
#	  @logger = Logger.new(STDOUT)
    @logger.datetime_format = "%H:%M:%S"
	  @logger.level = Logger::INFO
	  @logger
  end

  def pipesh(cmd)
    logger.info("Launching \"#{cmd}\"")
    IO.popen (cmd) do |f|
      while str = f.gets
        logger.info(str.chomp)
      end
    end
    $?
  end

  def report_error(str)
    logger.error(str)
    puts(str)
  end

  def report_info(str)
    logger.info(str)
    puts(str)
  end

  def within_diaspora_replica(&block)
    Dir.chdir(File.dirname(__FILE__), &block)
  end

  def within_capistrano(&block)
    Dir.chdir("#{File.dirname(__FILE__)}/capistrano", &block)
  end

  def machine_off?(name)
    within_diaspora_replica do
      !`vagrant status #{name}`.include?("running")
    end
  end

  def diaspora_up?(pod_uri)
    !DiasporaApi::Client.new(pod_uri).nodeinfo_href.nil?
  end

  def eye(cmd, stage_name, env=nil)
    within_capistrano do
      env_cmd = "env #{env}" unless env.nil?
      pipesh "bundle exec #{env_cmd} cap #{stage_name} diaspora:eye:#{cmd}"
      $?
    end
  end

  def wait_pod_up(pod_uri, timeout=60)
    timeout.times do
      break if diaspora_up?(pod_uri)
      sleep 1
    end
    up = diaspora_up?(pod_uri)
    logger.error "failed to access pod at #{pod_uri} after #{timeout} seconds; there may be some problems with your configuration" unless up
    up
  end

  def deploy_app(stage_name, env=nil)
    within_capistrano do
      env_cmd = "env #{env}" unless env.nil?
      pipesh "bundle exec #{env_cmd} cap #{stage_name} deploy"
      $?
    end
  end
end
