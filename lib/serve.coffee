# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

express   = require 'express'
nconf     = require 'nconf'
request   = require 'request'
winston   = require 'winston'

class Server

  _outstanding: { }

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
      @app.use express.static "#{__dirname}/../utorrent"
      @app.set "views", "#{__dirname}/../views"
      @app.enable "jsonp callback"
    @routes()

  start: ->
    @app.listen nconf.get('port')
    winston.info 'server listening on:', nconf.get 'port'
    @check_interval = setInterval @check, 1000

  check: =>
    report = (opts, hash) =>
      @utorrent.files hash, (flist) =>
        console.log (
            "http://#{nconf.get('ip')}:#{nconf.get('port')}/#{x.get('name')}" \
              for x in flist)
        request.post
          url: opts.announce
          body: JSON.stringify
            session_id: opts.session_id
            files: (
              "http://#{nconf.get('ip')}:#{nconf.get('port')}/" +
                "#{x.get('name')}" for x in flist)
        , (error, body, resp) =>
          winston.info error or "reported #{hash} to #{announce}"

    @utorrent.torrents (torrents) =>
      for k,v of @_outstanding
        if torrents[k].get('progress') < 1000
          return

        delete @_outstanding[k]
        report v, k

  routes: ->
    @app.get '/debug/peers/:hash', @_peer
    @app.get '/debug/torrents', @_torrents
    @app.get '/debug/files/:hash', @_files
    @app.get '/debug/upload', @_upload
    @app.get '/debug/include', @_include
    @app.get '/add/:hash', @_add
    @app.get '/status/:hash', @_status
    @app.get '/download/:fname', @_download
    @app.post '/announce', @_announce

  _announce: (req, res) =>
    res.json ""

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
    link = "magnet:?xt=urn:btih:#{req.params.hash}"
    @utorrent.add_torrent link, =>
      @_outstanding[req.params.hash] =
        announce: req.query.announce
        session_id: req.query.session_id
      res.json
        server: "#{nconf.get('ip')}:#{nconf.get('server_port')}"

  _status: (req, res) =>
    @utorrent.torrents (torrents) =>
      torrent = torrents[req.params.hash]
      @utorrent.peers req.params.hash, (peers) =>
        res.json
          progress: torrent.get 'progress'
          connected: (x for x in peers \
            when x.get('ip') == req.connection.remoteAddress).length != 0

  _files: (req, res) =>
    @utorrent.files req.params.hash, (files) =>
      res.json files

  _download: (req, res) =>
    winston.info req.params.fname

  _include: (req, res) =>
    opts =
      layout: false
    res.render 'include.ejs', opts

module.exports =
  Server: Server
