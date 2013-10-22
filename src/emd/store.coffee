EMD.Store = Em.Object.extend
  _cache: ({})

  ajax: (options)->
    options.headers ||= {}
    options.headers.Accept ||= "application/json"
    $.ajax.apply @, arguments

  find: (type, id)->
    Em.assert "Cannot find a record without an id", id or id == null

    if type.constructor == String
      type = @container.lookup("model:#{type}")
      Em.assert "Cannot find a record without a valid type", type instanceof EMD.Model
      type = type.constructor

    return record if record = @findCached type, id
    record = @load(type, id: id, null, true)
    record.reload()
    record

  cache: (type, object)->
    type_cache = @_cache[type] ||= {}
    return unless id = object.get("id")
    if existing = type_cache[id]
      return if existing == object
      type_cache[id].set 'content', object
    else
      type_cache[id] = object

  findCached: (type, id)->
    Em.assert "Cannot find #{type} without an id", id or id == null
    type_cache = @_cache[type] ||= {}
    type_cache[id]

  load: (type, data, instance, just_id)->
    if data.errors
      for key, value of data.errors
        Em.warn "#{key} #{value.join("and")}"

    if data.id || data.id == null
      cached = @findCached(type, data.id)
      return cached if just_id and cached

      type_cache = @_cache[type] ||= {}
      record = (instance || type.create())
      if just_id
        record.set("id", data.id)
      else
        record.load(data)
      type_cache[data.id] = record
    else
      (instance || type.create()).load(data)

EMD.Store.reopenClass
  alias: (method)->
    ->
      store = Em.get EMD, "defaultStore"
      args = [].slice.call arguments
      store[method].apply store, args

  aliasWithThis: (method)->
    ->
      store = Em.get EMD, "defaultStore"
      args = [].slice.call arguments
      args.unshift(@)
      store[method].apply store, args
