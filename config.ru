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
  if @request.post?
    website = @request.params['website']
    obj = {
      website: website,
      version: version(website),
      protocols: protocols(website)
    }

    unless website
      obj[:errors] = 'Missing website'
      status 500
    end

    # fun debugging
    puts obj.to_json 
    obj.to_json 
  else 
    ''
  end
end

run SimpleFramework.app
