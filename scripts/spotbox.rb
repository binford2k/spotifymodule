#! /usr/bin/env ruby
require 'json'
require 'gli'
require 'open3'
require 'uri'
require 'terminal-table'

require 'pry'

class Spotify
  def initialize
    conf = JSON.parse(File.read(File.expand_path('~/.config/spotbox.json')))
    auth = JSON.parse(File.read(File.expand_path('~/.sptok')))

    @user       = conf['username']
    @token      = auth['access_token']
    @playlist   = conf['playlist']
    @endpoint   = 'https://api.spotify.com/v1'
    @modulepath = '~/.puppetlabs/etc/code/environments/production/modules'
  end

  def bolt(task, *params)
    puts "=> bolt task run #{task}..."
    output, status = Open3.capture2('bolt', 'task', 'run', task,
    '--transport=local',
#    '--debug', '--trace',
                                      '--format', 'json',
                                      '--nodes', 'localhost',
                                      '--modulepath', @modulepath,
                                      "endpoint_api=#{@endpoint}",
                                      "token=#{@token}",
                                      *params,
                                    )

    raise "Bolt task [#{task}] failed: #{output}" unless status.success?
    data = JSON.parse(output)
    raise "Unexpected number of responses!" unless data['items'].size == 1
    data['items'].first['result']
  end

  def search(query)
    data = bolt('gen::swagger_gen_get_search', URI.encode("q=name:#{query}&type=album,track"))

    albums = data['albums']['items'] rescue []
    tracks = data['tracks']['items'] rescue []

    display_albums(albums)
    display_tracks(tracks)

    print "Please enter the line number of the Album or Track you'd like to queue up: "
    item = STDIN.gets.strip

    case item.slice!(0)
    when 'a', 'A'
      albums[item.to_i]['uri']
    when 't', 'T'
      tracks[item.to_i]['uri']
    else
      raise "Unknown item. Please enter the complete Album or Track code. (example: T3)"
    end
  end

  def add(track)
    bolt('gen::swagger_gen_post_usersuser_idplaylistsplaylist_idtracks', "user_id=#{@user}", "playlist_id=#{playlist_id}", URI.encode("uris=#{track}"))
  end

  def list
    tracks = bolt('gen::swagger_gen_get_usersuser_idplaylistsplaylist_id', "user_id=#{@user}", "playlist_id=#{playlist_id}")
    display_tracks(tracks['tracks']['items'].map {|t| t['track'] })
  end

  def remove
    data   = bolt('gen::swagger_gen_get_usersuser_idplaylistsplaylist_id', "user_id=#{@user}", "playlist_id=#{playlist_id}")
    tracks = data['tracks']['items'].map {|t| t['track'] }

    display_tracks(tracks)
    print "Please enter the line number of the Track to remove: "
    item = STDIN.gets.strip

    case item.slice!(0)
    when 't', 'T'
      track = tracks[item.to_i]['uri']
    else
      raise "Unknown item. Please enter the complete Track code. (example: T3)"
    end

    body = {"tracks"=>[{"uri" => URI.encode(track)}]}.to_json
    bolt('gen::swagger_gen_delete_usersuser_idplaylistsplaylist_idtracks', "user_id=#{@user}", "playlist_id=#{playlist_id}", "body=#{body}")
  end

  def playlist_id
    lists = bolt('gen::swagger_gen_get_usersuser_idplaylists', URI.encode("user_id=#{@user}"))
    list  = lists['items'].find {|list| list['name'] == @playlist}['id']
    list
  end

  def display_albums(albums)
    rows = albums.map.with_index do |album, index|
      artists = album['artists'].first['name']
      artists << ', ...' if album['artists'].size > 1

      ["A#{index}", album['name'], artists, album['release_date'], album['total_tracks']]
    end
    table = Terminal::Table.new :headings => ["#", 'Album', 'Artist(s)', 'Release Date', 'Tracks'], :rows => rows
    table.align_column(4, :center)
    puts
    puts "Albums:"
    puts table
  end

  def display_tracks(tracks)
    rows = tracks.map.with_index do |track, index|
      artists = track['artists'].first['name']
      artists << ', ...' if track['artists'].size > 1
      explicit = track['explicit'] ? '*' : ''
      popularity = '◼︎' * (track['popularity']/10)

      ["T#{index}", track['name'], track['album'], artists, explicit, popularity]
    end
    table = Terminal::Table.new :headings => ["#", 'Track', 'Album', 'Artist(s)', 'Explicit', 'Popularity'], :rows => rows
    table.align_column(4, :center)
    puts
    puts "Tracks"
    puts table
  end
end

class App
  extend GLI::App

  program_desc 'A Spotify jukebox backed by Bolt'

  pre do |global_options,command,options,args|
    @spotify = Spotify.new
  end

  desc 'Search for and add a track to the playlist.'
  arg_name "<search query>"
  command :add do |c|
    c.action do |global_options,options,args|
      help_now!('Search string is required') if args.empty?
      track = @spotify.search(args.first)
      @spotify.add(track)
    end
  end

  desc 'List songs on the playlist.'
  command :list do |c|
    c.action do |global_options,options,args|
      @spotify.list
    end
  end

  desc 'Interactively choose and remove a song from the playlist.'
  command :remove do |c|
    c.action do |global_options,options,args|
      @spotify.remove
    end
  end

end

exit App.run(ARGV)


