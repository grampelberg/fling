# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

Btapp.VERSION = "3.1"
window.btapp = new Btapp
btapp.bind 'plugin:install_plugin', (opts) =>
  opts.install = false

btapp.bind 'client:connected', ->
  _.delay ->
    btapp.bt.browseforfiles ->
      console.log arguments
    , (files) ->
      console.log arguments
  , 1000

btapp.connect()
