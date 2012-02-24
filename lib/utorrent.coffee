# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

_         = require('underscore')._
proc      = require 'child_process'
request   = require 'request'
winston   = require 'winston'

class Server

  logger: (type, data) =>
    winston.info "#{type}: \n\n#{data}"

  start: ->
    dir = "#{__dirname}/../../utserver/"
    @utorrent_proc = proc.spawn "#{dir}utserver", [],
      cwd: dir
    winston.info "utorrent running at: #{@utorrent_proc.pid}"
    @utorrent_proc.stdout.on 'data', _.bind(@logger, this, 'utserver')
    @utorrent_proc.stderr.on 'data', _.bind(@logger, this, 'utserver')
    process.on 'exit', @die

  die: ->
    @utorrent_proc.kill()

module.exports =
  Server: Server

