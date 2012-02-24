# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

_            = require('underscore')._
iconv        = require 'iconv'
proc         = require 'child_process'
querystring  = require 'querystring'
request      = require 'request'
winston      = require 'winston'

q = require('iconv')

class Server

  constructor: ->
    @iconv = new iconv.Iconv('utf-8', 'ascii//translit//ignore')

  logger: (type, data) =>
    winston.info "#{type}: \n\n#{data}"

  start: ->
    dir = "#{__dirname}/../utorrent/"
    @utorrent_proc = proc.spawn "#{dir}utserver", [],
      cwd: dir
    winston.info "utorrent running at: #{@utorrent_proc.pid}"
    @utorrent_proc.stdout.on 'data', _.bind(@logger, this, 'utserver')
    @utorrent_proc.stderr.on 'data', _.bind(@logger, this, 'utserver')
    process.on 'exit', @die

  die: ->
    @utorrent_proc.kill()

  request: (params, callback) ->
    request.get
      url: "http://localhost:8080/gui/?#{querystring.stringify(params)}"
      headers:
        Authorization: "Basic YWRtaW46",
      (error, resp, body) =>
        callback JSON.parse(@iconv.convert(body))

  torrents: (callback) ->
    @request
      list: 1, (body) ->
        callback _.reduce body.torrents, (acc, v) ->
          acc[v[0]] = new Torrent(v)
          acc
        , {}

  add_torrent: (link, callback) ->
    @request
      action: 'add-url'
      s: link, ->
        callback()

  peers: (hash, callback) ->
    @request
      action: 'getpeers'
      hash: hash
    , (body) ->
      if not body.peers.length
        return callback([])
      callback _.map body.peers[1], (v) ->
        new Peer(v)

class BaseType

  constructor: (item) ->
    @attrs = {}
    for k,v of _.zip @_names, item
      if not v[0]
        continue
      @attrs[v[0]] = v[1]

  get: (k) =>
    @attrs[k]

  toJSON: =>
    @attrs

class Torrent extends BaseType

  _names: [ 'hash', 'status', 'name', 'size', 'progress', 'down', 'up',
            'ratio', 'up_speed', 'down_speed', 'eta', 'label',
            'peers_connected', 'peers_swarm', 'seeds_connected',
            'seeds_swarm', 'availability', 'queue_order', 'remaining',
            'download_url', 'feed_url', 'status_msg',
            'streamid', 'stream_progress' ]

class Peer extends BaseType

  _names: [ "country", "ip", "hostname", "protocol", "port", "client",
            "flags", "complete", "down_speed", "up_speed", "pending",
            "requests", "waited", "uploaded", "downloaded", "hasherr",
            "peer_download_rate", "maxup", "maxdown", "queued",
            "inactive", "relevance" ]

module.exports =
  Server: Server

