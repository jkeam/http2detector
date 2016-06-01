$:.unshift File.dirname(__FILE__)
require 'json'
require 'simple_framework'

use Rack::Static,
  :urls => ["/images", "/js", "/css"],
  :root => "public"

route("/") do
  model name: 'jon'
  erb 'index.html'
end

route("/validation.json") do
  obj = {}
  if @request.post?
    website = @request.params['website'].to_s.strip
    obj = validate website 
  end
  obj.to_json
end

route("/validation") do
  if @request.post?
    website = @request.params['website'].to_s.strip
    validate website
  end
  erb 'index.html'
end

run SimpleFramework.app
