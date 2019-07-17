
# Spotify Tasks

## Description

This repository contains the [Puppet Bolt](https://puppet.com/docs/bolt/0.x/bolt.html) tasks generated from [Spotify OpenAPI specs](https://github.com/APIs-guru/openapi-directory/tree/master/APIs/spotify.com) allowing users to interact with the Spotify API to manage their spotify account and playlists.

## Usage

### Run a task

All Bolt tasks accept parameters based on the metadata.json for the relevant task. A Spotify token is required in order to run the tasks.

Get my playlists:

```bolt task run gen::swagger_gen_get_usersuser_idplaylists --nodes localhost endpoint_api=https://api.spotify.com/v1 user_id=<your user id> token="<your account token>" --modulepath ./```

### Spotbox Script

This includes a frontend "jukebox" script that will execute tasks for you. It's intended to manage a single playlist, like one that's playing in the Puppet Overlook common area.

It requires that you log in to the Spotify API using [spotifycli](https://github.com/masroorhasan/spotifycli) first.


```
$ spotifycli login
authorize
Please log in to Spotify by visiting the following page in your browser: https://accounts.spotify.com/authorize?client_id=&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fcallback&response_type=code&scope=user-read-private+user-read-currently-playing+playlist-read-collaborative+playlist-modify-private+playlist-modify-public&state=%9DR4%02%A87%11%E9%3A%E3o%FC%00%3C%1D%C2

$ ./scripts/spotbox.rb --help
NAME
    spotbox.rb - A Spotify jukebox backed by Bolt

SYNOPSIS
    spotbox.rb [global options] command [command options] [arguments...]

GLOBAL OPTIONS
    --help - Show this message

COMMANDS
    add    - Search for and add a track to the playlist.
    help   - Shows a list of commands or help for one command
    list   - List songs on the playlist.
    remove - Interactively choose and remove a song from the playlist.
```

Configuration is via a simple json file at `~/.config/spotbox.json` that looks like:

```json
{
  "username": "<your username>",
  "playlist": "<the name of the playlist to interact with>"
}
```
