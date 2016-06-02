require 'erb'
require 'net/http'
require 'json'

class Action
  attr_reader :headers, :body, :request

  def initialize(&block)
    @block = block
    @status = 200
    @headers = {"Content-Type" => "text/html"}
    @body = ""
    @model = {}
  end

  def status(value = nil)
    value ? @status = value : @status
  end

  def model(value = nil)
    value ? @model = value : @model
  end

  def params
    request.params
  end

  def call(env)
    @request = Rack::Request.new(env)
    @body = self.instance_eval(&@block)
    [status, headers, [body]]
  end

  def erb(template)
    path = File.expand_path("templates/#{template}.erb")
    ERB.new(File.read(path)).result(binding)
  end

  def protocols(website)
    to_return = '' 
    advertised = `openssl s_client -connect "#{website}":443 -nextprotoneg '' 2> /dev/null`
    protocol_line = advertised.match(/Protocols advertised by server.*/)
    to_return = protocol_line[0].gsub('Protocols advertised by server:', '').strip if protocol_line
    to_return.split(',').map(&:strip)
  end

  def version(website)
    # calls curl locallly
    # to_return = nil
    # protocol_line = `curl --http2 -I https://"#{website}"`
    # lines = protocol_line.split("\n") if protocol_line
    # to_return = lines[0].split(' ')[0] if lines[0] 
    # to_return

    uri = URI("http://162.243.195.43:8080/?website=https://#{website}")
    resp = JSON.parse Net::HTTP.get(uri)
    methods = resp['methods']
    if methods && !methods.empty?
      methods.map{|m| m.split(' ')[0] }.join(',')
    else
      ''
    end
  end

  def validate(website, redis)
    obj = {}
    unless website.empty?
      cached = cache_get redis, website
      if cached
        log "cache hit for #{website}"
        cached = JSON.parse cached
        obj[:website] = cached['website']
        obj[:version] = cached['version']
        obj[:protocols] = cached['protocols']
      else
        log "cache miss for #{website}"
        obj[:website] = website
        obj[:version] = version(website)
        obj[:protocols] = protocols(website)
      end
    else
      obj[:errors] = 'Missing website'
      status 500
    end
    cache_set redis, website, obj
    model obj
  end

  private
    def log(message)
      puts message + " at #{Time.new}"
    end

    def cache_set(redis, website, obj)
      redis.set website, obj.to_json
    rescue Exception => e
      puts e  
    end

    def cache_get(redis, website)
      redis.get website
    rescue Exception => e
      puts e
    end
end
