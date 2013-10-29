#<!--
# = require ./store
#-->

#
# Models are collections of attributes, that can be persisted via HTTP methods
# on a specified path or `link`.
#
# Basic Usage
# ----
#
# Creating a model that maps the following json document:
#
#     user:
#       id: 1
#       name: "Carl"
#       email_address: "carl@yay.com"
#
# Located at `/api/users/1`
#
# Add a link property to your application for the model:
#
#     App = Em.Application.create
#       userLink: "/api/users"
#
# Define the model class:
#
#     App.User = EMD.Model.extend
#       linkBinding: "App.userLink"
#       name: EMD.attr "name"
#       emailAddress: EMD.attr "email_address"
#
# And then use it in your application:
#
#     u = App.User.find 1
#     u.get "name"          => "carl"
#     u.get "emailAddress"  => "carl@yay.com"
#     u.get "link"          => "/api/users"
#     u.get "url"           => "/api/users/1"
#
# Annotated source
# ----
EMD.Model = Em.Object.extend Em.Evented,
# Link
# ----
# The `link` property  defines the resource path for __all__ models of a type.
#
# For example, all `App.User` models would share a `link` like `/api/users`
#
# The link is special because it defines the basic path for retrieving,
# creating, updating, and deleting models.
#
# When the `link` changes, all models of that type reload. All record arrays
# that use that type as a base reload.
#
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
    @reload() unless @get "isLoaded"
  ).observes "link"

# Url
# ---
# The `url` property is different than the link in that it is the link with
# the model's `id` property appended to it.
#
# See [EMD.attr](attr.html) for more documentation on `EMD.attr`.
  url: EMD.attr 'url',
    readonly: true
    extra_keys: ['id', 'link']
    if_null: ->
      return false unless link = @get "link"
      return link unless id = @get("id") or id == null
      "#{link}/#{id}"

# Id
# ---
# This is id of the object, it is set to readonly because it is present in the
# url that actions are performed on.
#
# For example, `App.User.find(1).get("url")` would return `/api/users/1`.
#
# When the id changes and becomes present, the record is cached in the store
# cache.
#
  id: EMD.attr 'id', readonly: true

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
    "#{@constructor}(#{@get 'id' })"

  toJson: ->
    props = {}
    @constructor.eachComputedProperty (name, meta)=>
      return if meta.readonly
      if serialized_name = meta.serialized_name
        value = @get name
        value = meta.convertTo(value) if meta.convertTo
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

  extend: ->
    args = Array.prototype.slice.call arguments
    args = $.map args, (arg)->
      console.log arg if arg instanceof Function

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
    attributes = {}
    @eachComputedProperty (name, meta)=>
      attributes[name] = meta if serialized_name = meta.serialized_name
    attributes

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


