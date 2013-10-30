#<!--
# = require ./store
#-->


EMD.Model = Em.Object.extend Em.Evented,
  baseUrl: (->
    Em.warn "You should set a baseUrl on #{@constructor}"
  ).property()

  url: EMD.attr 'url',
    readonly: true
    optional: true
    extra_keys: ['id', 'baseUrl']
    if_null: ->
      return false unless base_url = @get "baseUrl"
      return base_url unless id = @get("id") or id == null
      "#{base_url}/#{id}"

  id: EMD.attr 'id', optional: true, readonly: true

  idDidChange: (->
    @constructor.cache(@)
  ).observes("id")

# then
# ---
# This is a ghetto promise interface, it allows this model to behave
# asynchronously with EmberJS's routing system as well as providing a helper
# for telling when the model is loaded or if it already is
  then: (ok, er)->
    return ok(@) if @get 'isLoaded'
    return ok(@) unless @get 'id'
    @one 'load', ok
    @reload()

  toString: ->
    "#{@constructor}(#{@get('id') || 'new' })"

  toJson: ->
    props = {}
    @constructor.eachComputedProperty (name, meta)=>
      return if meta.readonly
      if serialized_name = meta.serialized_name
        value = @get name
        value = meta.convertToData(value) if meta.convertToData
        props[serialized_name] = value if value != undefined
    props

# _data
# ----
# The `_data` object is where the data from the server is stored.
  _data: (->
    Em.Object.create()
  ).property()

# ajax
# ----
# Here we defer our ajax to our constructor, which allows each model to
# override it's ajax method.
  ajax: ->
    @constructor.ajax.apply @, arguments

# load
# ----
# This forcefully injects json ito the `_data` field and extracts
# errors that the developer should see.
#
# If the json document has a `errors` object in it, the errors will be logged
# to the console and available on the model.
#
  load: (data)->
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

# reload
# ----
# If the model has an id, it triggers a fetch from the server.
  reload: ->
    return @ if @get("id") is undefined
    return @ unless url = @get "url"
    return @ if @get "isLoading"

    @set "isLoaded", false
    @set "isLoading", true

    @ajax
      url: url
      cache: false
      success: (ok)=>
        @constructor.fromJson(ok, @)
      error: (err)=>
        debugger

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
      unless @get "baseUrl"
        @addObserver "baseUrl", @, ->
          @save().then(ok, er)
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

  isDeleted: false
  isLoading: false
  isLoaded: false
  isNew: (->return @get('id') == undefined).property 'id'
  isDirty: ((_, set)->
    return set if set != undefined
    return false if @get "id"
    true
  ).property "id"


  created: EMD.attr.moment 'created_at', readonly: true, optional: true
  updated: EMD.attr.moment 'updated_at', readonly: true, optional: true
  errors: EMD.attr 'errors', readonly: true, optional: true
  links: EMD.attr.object 'links', readonly: true, optional: true

# Model class methods and properties
# ----
EMD.Model.reopenClass
  find: EMD.Store.aliasWithThis 'find'
  cache: EMD.Store.aliasWithThis 'cache'
  load: EMD.Store.aliasWithThis 'load'
  ajax: EMD.Store.alias 'ajax'

  where: (query)->
    mixins = @PrototypeMixin.mixins
    mixin = mixins[mixins.length - 1]
    url = mixin.properties.url
    EMD.RecordArray.create
      model: @
      url: url
      query: query

  extend: ->
    args = Array.prototype.slice.call arguments
    args = $.map args, (arg)->
      if arg instanceof Function
        return arg()
      arg
    @_super.apply @, args

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
    return @_attributes if @_attributes
    @_attributes = {}
    @eachComputedProperty (name, meta)=>
      @_attributes[name] = meta if serialized_name = meta.serialized_name
    @_attributes

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

# Inflection
# ----
# The singular is often derivable by the class name, however, the plural is more
# difficult.
#
# There is default support for the inflector found here
# [http://msnexploder.github.io/inflect/](http://msnexploder.github.io/inflect/).
#
# Or you can add your own: `EMD.Model.set 'pluralizer', (model)-> model.toString().split('.').pop().underscore() + "s"`
#
  singular: (->
    @toString().split(".").pop().underscore()
  ).property()

  pluralizer: (->
    if inflect != undefined
      (model)->
        name = model.toString().split('.').pop().underscore()
        inflect.pluralize(name)
  ).property()

  plural: (->
    if pluralize = Em.get @, "pluralizer"
      return pluralize @
    Em.assert "Please define a plural plural: 'plural' for #{@constructor} or register a pluralizer with EMD.Model.set('pluralizer', ((model)->'models')"
  ).property "singular"


