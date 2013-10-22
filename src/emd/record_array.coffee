EMD.RecordArray = Em.ArrayProxy.extend Em.Evented,

  ajax: EMD.Store.alias 'ajax'

  url: null
  query: null

  _model: (->
    model = @get 'model'
    model.create()
  ).property()

  model: null

  isLoaded: ((_, set)->
    return set if set != undefined
    @_init()
    false
  ).property()

  isLoading: ((_, set)->
    return set if set != undefined
    @_init()
    false
  ).property()

  extractMeta: (rsp)->
    null

  success: (ok)->
    Em.assert "You must specify a model or a success converter", model = @get 'model'
    model.fromJson ok

  error: (err, url, query)->
    debugger

  content: ((_, set)->
    return set if set != undefined
    @_init()
    []
  ).property()

  _init: ->
    return if @_inited
    @_inited = true
    @_setupContent()
    @_setupArrangedContent()
    unless @_initial_content_load
      @_initial_content_load = true
      @urlOrQueryDidChange()

  init: ->
    @_inited = false
    @_initial_content_load = false

  load: (fn)->
    return fn.apply this if @get "isLoaded"
    @urlOrQueryDidChange()
    @one "load", @, fn
    @

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
