# Copyright(c) 2012 Thomas Rampelberg <thomas@saunter.org>

fling =
  config:
    host: "http://10.10.100.194:9050"
    announce: "http://10.10.100.194:9050/announce"

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

class ProgressView extends BaseView
  template: "progress"

  initialize: (model) =>
    @model = model
    model.bind 'change:ratio', @_progress

  _progress: =>
    @$(".bar").attr "style", "width: #{@model.get('ratio') / 10}%"

    if @model.get('ratio') != 1000
      return
    $("#fling_upload").show()
    $(@el).hide()
    $("body").append (new CompleteView()).render().el

class CompleteView extends BaseView
  template: "complete"

class UploadView extends BaseView
  template: "upload"
  events:
    "click .upload": "start"
  _retry_interval: 1000

  get_files: (callback) =>
    btapp.bt.browseforfiles ->
      ""
    , (files) ->
      btapp.bt.create ->
        ""
      , "", _.values(files), (hash) ->
        callback(hash)

  connect: (hash, server, callback) =>
    $.get "/status/#{hash}", (resp) =>
      if resp.connected
        return callback()
      btapp.get("torrent").get(hash).bt.add_peer _.identity, server
      _.delay =>
        @connect hash, server, callback
      , @_retry_interval

  start: =>
    _notify = =>
      connected = new ConnectedView
      $("body").append connected.render().el

    _add = (hash) =>
      _.delay =>
        torrent_view = new ProgressView(
          btapp.get('torrent').get(hash).get('properties')
        )
        $("body").append torrent_view.render().el
      , 100

      @$("#fling_upload").hide()
      announce = $(".announce").val()
      $.ajax
        url: "/add/#{hash}"
        data:
          announce: announce or fling.config.announce
        success: (resp) =>
          @connect hash, resp.server, _notify

    @get_files _add

class ConnectedView extends BaseView
  template: "connected"

jQuery ->

btapp.bind 'client:connected', ->
  $(".client_download").hide()
  uploader = new UploadView
  $("body").append uploader.render().el

btapp.bind 'plugin:install_plugin', (opts) =>
  opts.install = false

btapp.connect()
