# = require ./store

########################################################
#
D.Model = Em.Object.extend Em.Evented,
########################################################
# The root link to this item
  link: null
  linkChange: ->
    link = @get 'link'
    cachebust = "_cacheBust=#{new Date().getTime()}"
    if link.indexOf('_cacheBust') == -1
      if link.indexOf '?' == -1
        connector = '?'
      else
        connector = '&'
      link = "#{link}#{connector}#{cachebust}"
    else
      link = link.replace /([\?&])_cacheBust=\d+/, "$1#{cachebust}"
    @set 'link', link

  linkDidChange: (->
    # Prevent double loading, but reload if the link
    # suddenly becomes available
    @reload() unless @get "isLoaded"
  ).observes "link"

########################################################
# The remote json object
  _data: (->
    Em.Object.create()
  ).property()

  toString: ->
    "#{@constructor}(#{@get 'id' })"

########################################################
# Default Properties
  id: D.attr 'id', readonly: true
  created: D.attr.moment 'created_at', readonly: true, optional: true
  updated: D.attr.moment 'updated_at', readonly: true, optional: true
  errors: D.attr 'errors', readonly: true, optional: true
  links: D.attr.object 'links', readonly: true, optional: true

########################################################
# Changers
  idDidChange: (->
    @constructor.cache(@)
  ).observes("id")

########################################################
# URL, often a combination of link/id
  url: D.attr 'url',
    readonly: true
    extra_keys: ['id', 'link']
    if_null: ->
      return false unless link = @get "link"
      return link unless id = @get("id") or id == null
      "#{link}/#{id}"

########################################################
# Our ghetto promise interface
  then: (ok, er)->
    return ok(@) if @get 'isLoaded'
    @one 'load', ok
    @reload() unless @get 'isLoading'

########################################################
# Serialization
  toJson: ->
    props = {}
    @constructor.eachComputedProperty (name, meta)=>
      return if meta.readonly
      if serialized_name = meta.serialized_name
        value = @get name
        value = meta.convertTo(value) if meta.convertTo
        props[serialized_name] = value if value != undefined
    props

########################################################
# States
  isDeleted: false
  isLoading: false
  isLoaded: false
  isNew: (->return @get('id') == undefined).property 'id'
  isDirty: ((_, set)->
    return set if set != undefined
    return false if @get "id"
    true
  ).property "id"

########################################################
# Loading data from the server
  ajax: ->
    @constructor.ajax.apply @, arguments

  load: (data)->
    return @one 'load', @, data if typeof data == 'function'
    Em.assert "Load with no data?", typeof data == 'object'

    if data.errors
      for key, value of data.errors
        Em.warn "#{@get('url')} - #{key} #{value.join("and")}"

    if @constructor._needsBeforeLoad
      @constructor._beforeLoad(data)

    # Load the data into our model
    @set "_data", Em.Object.create data

    # Set our state to loaded
    @set "isDirty", false
    @set "isLoaded", true
    @set "isLoading", false

    # Fire triggers
    @trigger 'load', @
    @

  cancel: ->
    @reload()

  reload: ->
    id = @get("id")
    return @ if id == undefined
    return @ unless url = @get "url"

    @set "isLoaded", false
    @set "isLoading", true

    @ajax
      url: url
      cache: false
      success: (ok)=>
        @constructor.fromJson(ok, @)
      error: (err)=>
        debugger

    @

  delete: ->
    if @get("id")
      @ajax @get("url"),
        method: 'delete'
        success: (rsp)=>
          @linkChange()
    @set 'isDeleted', true
    @set '_data', null

  save: (ok)->
    @load(ok) if ok

    new Em.RSVP.Promise (ok, er)=>
      unless @get "link"
        console.log "deferring"
        @addObserver "link", @, ->
          @save().then(ok,er)
      else
        console.log "saving"
        Em.assert "Cannot save without a link or url", url = @get "url"
        method = if @get("id") then "put" else "post"
        data = {}
        data[Em.get(@constructor, 'singular')] = @toJson()

        return ok() unless @get 'isDirty'
        @ajax
          method: method
          contentType: "application/json; charset=utf-8"
          dataType: "json"
          processData: false
          url: url
          data: JSON.stringify data
          success: (rsp)=>
            @load rsp[Em.get(@constructor, "singular")]

            # We need to inform all record arrays off this link
            # that we have changed their contents
            @linkChange()

            ok()
          error: (rsp)->
            er(rsp)

########################################################
#
D.Model.reopenClass
  find: D.Store.aliasWithThis 'find'
  cache: D.Store.aliasWithThis 'cache'
  load: D.Store.aliasWithThis 'load'
  ajax: D.Store.alias 'ajax'

  _beforeLoad: (data)->
    @_needsBeforeLoad = false
    attributes = @attributes()
    has_serialized_keys = {}
    serialized_keys = Em.keys data
    property_keys = Em.keys attributes
    shown_data = false

    $.each property_keys, (_, property_key)=>
      serialized_name = attributes[property_key].serialized_name
      optional = attributes[property_key].optional
      has_serialized_keys[serialized_name] = attributes[property_key]
      if data[serialized_name] == undefined && !optional
        unless shown_data
          shown_data = true
          Em.warn "#{@}: potential issues with model attributes after receiving #{serialized_keys}"
        Em.warn "#{@} has extranious attr mapping for: #{serialized_name} on property #{property_key}"


    $.each serialized_keys, (_, serialized_key)=>
      Em.warn "#{@} is missing attr mapping for: #{serialized_key}" if has_serialized_keys[serialized_key] == undefined

  _needsBeforeLoad: true

  attributes: ->
    attributes = {}
    @eachComputedProperty (name, meta)=>
      attributes[name] = meta if serialized_name = meta.serialized_name
    attributes

  singular: (->
    @toString().split(".").pop().underscore()
  ).property()

  plural: (->
    Em.assert "Please define a plural plural: 'plural' for #{@constructor}"
  ).property "singular"

  fromJson: (data, instance)->
    # Try to load singular
    singular = Em.get(@, "singular")
    return @load(data[singular], instance) if data[singular]
    Em.assert "Cannot load into an instance without the singular: #{singular}", !instance

    # Try to load plural
    plural = Em.get(@, "plural")
    Em.assert "Cannot load without singular: #{singular} or plural: #{plural}", data[plural]
    data[plural].map((data)=>
      @load(data))

  create: (config)->
    @_super().setProperties config
