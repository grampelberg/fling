# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

fs        = require 'fs'
proc      = require 'child_process'
request   = require 'request'

tarball = "http://com.bittorrent.dropbox.s3-website-us-east-1.amazonaws.com/" +
  "utorrent-server.tar.gz"
webui = "http://apps.bittorrent.com.s3.amazonaws.com/webui.zip"

extract_utorrent = (callback) ->
  try
    fs.mkdirSync "#{__dirname}/build"
  catch err
    ""
  local_tarball = "#{__dirname}/build/utorrent.tar.gz"
  request.get(tarball, ->
    proc.exec "tar zxf #{local_tarball} -C #{__dirname} && " +
      "rm -rf #{__dirname}/utorrent && " +
      "mv -f utorrent-server-v3_0 utorrent && " +
      "rm #{__dirname}/utorrent/webui.zip", ->
        callback()
  ).pipe(fs.createWriteStream(local_tarball))

fetch_webui = ->
  request.get(webui).pipe(
    fs.createWriteStream("#{__dirname}/utorrent/webui.zip"))

task 'setup', 'Get setup for running', (options) ->
  extract_utorrent ->
    fetch_webui()
