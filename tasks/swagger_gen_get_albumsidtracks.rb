#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'openssl'

def get_albumsidtracks(*args)
  header_params = {}
  
  params=args[0][1..-1].split(',')

  arg_hash={}
  params.each { |param|
   mapValues= param.split(':',2)
   if mapValues[1].include?(';')
      mapValues[1].gsub! ';',','
   end
   arg_hash[mapValues[0][1..-2]]=mapValues[1][1..-2]
  }

  # Remove task name from arguments - should contain all necessary parameters for URI
  arg_hash.delete('_task')
  operation_verb = 'Get'

  query_params, body_params, path_params = format_params(arg_hash)

  uri_string = "#{arg_hash['endpoint_api']}/albums/%{id}/tracks" % path_params

  if query_params
    uri_string = uri_string + '?' + to_query(query_params)
  end

  header_params['Content-Type'] = 'application/json' # first of #{parent_consumes}

  if arg_hash['token']
    header_params['Authorization'] = 'Bearer ' + arg_hash['token']
  end

  uri = URI(uri_string)
 
  verify_mode= OpenSSL::SSL::VERIFY_NONE
  if arg_hash['ca_file']
    verify_mode=OpenSSL::SSL::VERIFY_PEER
  end

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', verify_mode: verify_mode, ca_file: arg_hash['ca_file']) do |http|
    if operation_verb == 'Get'
      req = Net::HTTP::Get.new(uri)
    elsif operation_verb == 'Put'
      req = Net::HTTP::Put.new(uri)
    elsif operation_verb == 'Delete'
      req = Net::HTTP::Delete.new(uri)
    elsif operation_verb == 'Post'
      req = Net::HTTP::Post.new(uri)
    end

    header_params.each { |x, v| req[x] = v } unless header_params.empty?

    unless body_params.empty?
      if body_params.key?('file_content')
        req.body = body_params['file_content']
      else
        req.body = body_params.to_json
      end
    end

    Puppet.debug("URI is (#{operation_verb}) #{uri} headers are #{header_params}")
    response = http.request req # Net::HTTPResponse object
    Puppet.debug("response code is #{response.code} and body is #{response.body}")
    success = response.is_a? Net::HTTPSuccess
    Puppet.debug("Called (#{operation_verb}) endpoint at #{uri}, success was #{success}")
    response
  end
end

def to_query(hash)
  if hash
    return_value = hash.map { |x, v| "#{x}=#{v}" }.reduce { |x, v| "#{x}&#{v}" }
    if !return_value.nil?
      return return_value
    end
  end
  return ''
end

def op_param(name, inquery, paramalias, namesnake)
  { :name => name, :location => inquery, :paramalias => paramalias, :namesnake => namesnake }
end

def format_params(key_values)
  query_params = {}
  body_params = {}
  path_params = {}

 key_values.each { | key, value |
    if value.include?("=>")
       Puppet.debug("Running hash from string on #{value}")
       value.gsub!("=>",":")
       value.gsub!("'","\"")
       key_values[key] = JSON.parse(value)
       Puppet.debug("Obtained hash #{key_values[key].inspect}")
    end
  }


  if key_values.key?('body')
    if File.file?(key_values['body'])
      if key_values['body'].include?('json')
        body_params['file_content'] = File.read(key_values['body'])
      else
        body_params['file_content'] =JSON.pretty_generate(YAML.load_file(key_values['body']))
      end
    end
  end

  op_params = [
      op_param('artists', 'body', 'artists', 'artists'),
      op_param('available_markets', 'body', 'available_markets', 'available_markets'),
      op_param('disc_number', 'body', 'disc_number', 'disc_number'),
      op_param('duration_ms', 'body', 'duration_ms', 'duration_ms'),
      op_param('explicit', 'body', 'explicit', 'explicit'),
      op_param('external_urls', 'body', 'external_urls', 'external_urls'),
      op_param('href', 'body', 'href', 'href'),
      op_param('id', 'path', 'id', 'id'),
      op_param('is_playable', 'body', 'is_playable', 'is_playable'),
      op_param('limit', 'query', 'limit', 'limit'),
      op_param('linked_from', 'body', 'linked_from', 'linked_from'),
      op_param('market', 'query', 'market', 'market'),
      op_param('name', 'body', 'name', 'name'),
      op_param('offset', 'query', 'offset', 'offset'),
      op_param('preview_url', 'body', 'preview_url', 'preview_url'),
      op_param('track_number', 'body', 'track_number', 'track_number'),
      op_param('type', 'body', 'type', 'type'),
      op_param('uri', 'body', 'uri', 'uri'),
    ]
  op_params.each do |i|
    location = i[:location]
    name     = i[:name]
    paramalias = i[:paramalias]
    name_snake = i[:namesnake]
    if location == 'query'
      query_params[name] = key_values[name_snake] unless key_values[name_snake].nil?
      query_params[name] = ENV["azure__#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    elsif location == 'body'
      body_params[name] = key_values[name_snake] unless key_values[name_snake].nil?
      body_params[name] = ENV["azure_#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    else
      path_params[name_snake.to_sym] = key_values[name_snake] unless key_values[name_snake].nil?
      path_params[name_snake.to_sym] = ENV["azure__#{name_snake}"] unless ENV["<no value>_#{name_snake}"].nil?
    end
  end
  
  return query_params,body_params,path_params
end

def task
  # Get operation parameters from an input JSON
  params = STDIN.read
  result = get_albumsidtracks(params)
  if result.is_a? Net::HTTPSuccess
    puts result.body
  else
    raise result.body
  end
rescue StandardError => e
  result = {}
  result[:_error] = {
    msg: e.message,
    kind: 'puppetlabs-kubernetes/error',
    details: { class: e.class.to_s },
  }
  puts result
  exit 1
end

task
