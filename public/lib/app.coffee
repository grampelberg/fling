# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

fling =
  config:
    host: "http://localhost:9050"
    announce: "http://localhost:9050/announce"

Btapp.VERSION = "3.1"
window.btapp = new Btapp
btapp.bind 'plugin:install_plugin', (opts) =>
  opts.install = false

class BaseView extends Backbone.View
  render: =>
    return @ if !@template
    _.extend {}, @options, (if @model then @model.attributes else {})
    $(@el).html Handlebars.templates[@template](@options)
    @

class UploadView extends BaseView
  template: "upload"
  events:
    "click .upload": "start"
  _retry_interval: 1000

  get_files: (callback) =>
    callback("6A50D50EF407735AA748272585353BD1B11D6452")

  connect: (hash, server, callback) =>
    $.get "#{fling.config.host}/status/#{hash}", (resp) =>
      if not resp.connected
        return callback()
      # btapp.bt.add_peer(hash, resp.server)
      _.delay =>
        @connect hash, server, callback
      , @_retry_interval

  start: =>
    _notify = =>
      connected = new ConnectedView
      $("body").append connected.render().el

    _add = (hash) =>
      @$(".progress").show()
      @$(".btn-primary").hide()
      $.ajax
        url: "#{fling.config.host}/add/#{hash}"
        data:
          announce: fling.config.announce
        success: (resp) =>
          @connect hash, resp.server, _notify

    @get_files _add

class ConnectedView extends BaseView
  template: "connected"

jQuery ->
  uploader = new UploadView
  $("body").append uploader.render().el

# btapp.bind 'client:connected', ->
#   _.delay ->
#     btapp.bt.browseforfiles ->
#       ""
#     , (files) ->
#       btapp.bt.create ->
#         console.log "one", arguments
#       , '', files, ->
#         console.log "two", arguments
#   , 1000

# btapp.connect()
