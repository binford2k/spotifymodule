
# Spotify Tasks

## Description

This repository contains the [Puppet Bolt](https://puppet.com/docs/bolt/0.x/bolt.html) tasks generated from [Spotify OpenAPI specs](https://github.com/APIs-guru/openapi-directory/tree/master/APIs/spotify.com) allowing users to interact with the Spotify API to manage their spotify account and playlists.

## Usage

### Run a task

All Bolt tasks accept parameters based on the metadata.json for the relevant task. A Spotify token is required in order to run the tasks.

Get my playlists:

```bolt task run gen::swagger_gen_get_usersuser_idplaylists --nodes localhost endpoint_api=https://api.spotify.com/v1 user_id=<your user id> token="<your account token>" --modulepath ./```
