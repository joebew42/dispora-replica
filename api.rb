require "logger"
require "json"

module Diaspora
  module Replica
  end
end

module Diaspora::Replica::API
  attr_writer :logdir

  def pod_count
    ENV["pod_count"] && ENV["pod_count"].to_i || 2
  end

  def logdir
    @logdir || "/tmp"
  end

  def logger
    return @logger unless @logger.nil?
    file = File.new("#{logdir}/replica.#{Time.now.strftime "%Y%m%d%H%M%S"}.log", "w")
    file.sync = true
	  @logger = Logger.new(file)
#	  @logger = Logger.new(STDOUT)
    @logger.datetime_format = "%H:%M:%S"
	  @logger.level = Logger::INFO
	  @logger
  end

  def pipesh(cmd, to_stdout=false)
    pipesh_block(cmd) do |line|
      logger.info(line)
      puts(line) if to_stdout
    end
  end

  def pipesh_log_and_stdout(cmd)
    pipesh(cmd, true)
  end

  def pipesh_block(cmd, &print_string)
    print_string.call("Launching \"#{cmd}\"")
    IO.popen (cmd) do |f|
      while str = f.gets
        print_string.call(str.chomp)
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
      !`env pod_count=#{pod_count} vagrant status #{name}`.include?("running")
    end
  end

  def diaspora_up?(pod_uri)
    !nodeinfo_href(pod_uri).nil?
  end

  def eye(cmd, stage_name, env=nil, to_stdout=false)
    within_capistrano do
      env_cmd = "env #{env}" unless env.nil?
      pipesh "bundle exec #{env_cmd} cap #{stage_name} diaspora:eye:#{cmd}", to_stdout
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

  def send_plain_request(request, poduri)
    uri = URI.parse(poduri)
    logger.debug("send_plain_request: poduri #{poduri} uri.host #{uri.host} uri.port #{uri.port}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.request(request)
  end

  def nodeinfo_href(poduri)
    response = send_plain_request(Net::HTTP::Get.new("/.well-known/nodeinfo"), poduri)
    if response.code == "200"
      JSON.parse(response.body)["links"]
        .select {|res| res["rel"] == "http://nodeinfo.diaspora.software/ns/schema/1.0"}
        .first["href"]
    end
  rescue Net::OpenTimeout
  rescue SocketError
  rescue Errno::EHOSTUNREACH
  end
end
