# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

express   = require   'express'
nconf     = require 'nconf'
winston   = require 'winston'

class Server

  constructor: ->
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

  start: ->
    @app.listen nconf.get('port')
    winston.info 'server listening on:', nconf.get 'port'

module.exports =
  Server: Server
