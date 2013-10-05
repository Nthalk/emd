D.RecordArray = Em.ArrayProxy.extend Em.Evented,

  ajax: D.Store.alias 'ajax'

  url: null
  query: null

  _model: (->
    model = @get 'model'
    model.create()
  ).property()

  model: null

  isLoaded: false
  isLoading: false

  extractMeta: (rsp)->
    null

  success: (ok)->
    Em.assert "You must specify a model or a success converter", model = @get 'model'
    model.fromJson ok

  error: (err, url, query)->
    debugger

  content: ((_, set)->
    @_init() unless @_inited
    return set if set != undefined
    @urlOrQueryDidChange()
    []
  ).property()

  _init: ->
    @_inited = true
    @_setupContent()
    @_setupArrangedContent()

  init: ->
    @_inited = false

  load: (fn)->
    return fn.apply this if @get "isLoaded"
    @urlOrQueryDidChange()
    @one "load", @, fn

  reload: (overrides = {})->
    @set "query", $.extend({}, @get("query"), overrides)

  urlOrQueryDidChange: ((_, change_key)->
    # Nobody asked for content!
    return unless @_inited

    # Hmm... url not available? When does this happen again?
    return unless @get "_model.link"

    # no url?
    return unless url = @get "url"

    # Protect against eager loading twice
    return if !change_key and @get 'isLoading'

    query = @get "query"
    @set "isLoaded", false
    @set "isLoading", true

    console.log "#{@}::#{@get('model').toString()}.loading(#{change_key}:#{@get change_key if change_key})", query

    @ajax(
      method: "get"
      url: url
      data: query
    ).success((ok)=>
      return if @isDestroyed
      @extractMeta ok
      @set "content", @success ok
      @set "isLoaded", true
      @set "isLoading", false
      @trigger "load", @
    ).error((err)=>
      @error err, url, query
    )

  ).observes "query", "url", "_model.link"
