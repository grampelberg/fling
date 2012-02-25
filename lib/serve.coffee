# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

express   = require   'express'
nconf     = require 'nconf'
winston   = require 'winston'

class Server

  constructor: (utorrent) ->
    @utorrent = utorrent
    @app = express.createServer()
    @app.configure =>
      @app.use express.logger
        format:':req[x-forwarded-for] - :method :url HTTP/:http-version ' +
          ':status :res[content-length] - :response-time ms'
        stream:
          write: (ln) -> winston.info ln.slice(0,-1)
      @app.use express.errorHandler
        showStack: true,
        dumpExceptions: true
      @app.use express.bodyParser()
      @app.use express.cookieParser()
      @app.use express.static "#{__dirname}/../public"
      @app.set "views", "#{__dirname}/../views"
      @app.enable "jsonp callback"
    @routes()

  start: ->
    @app.listen nconf.get('port')
    winston.info 'server listening on:', nconf.get 'port'

  routes: ->
    @app.get '/debug/peers/:hash', @_peer
    @app.get '/debug/torrents', @_torrents
    @app.get '/debug/upload', @_upload
    @app.get '/add', @_add
    @app.get '/upload/:hash', @_status

  _torrents: (req, res) =>
    @utorrent.torrents (body) ->
      res.json body

  _peer: (req, res) =>
    @utorrent.peers req.params.hash, (body) =>
      res.json body

  _upload: (req, res) =>
    opts =
      layout: false
    res.render 'upload_test.ejs', opts

  _add: (req, res) =>
    @utorrent.add_torrent req.query.link, =>
      @utorrent.torrents (body) =>
        res.json
          server: "http://localhost:8889"

  _status: (req, res) =>
    @utorrent.torrents (torrents) =>
      torrent = torrents[req.params.hash]
      @utorrent.peers req.params.hash, (peers) =>
        res.json
          progress: torrent.get 'progress'
          connected: (x for x in peers \
            when x.get('ip') == req.connection.remoteAddress).length != 0

module.exports =
  Server: Server
