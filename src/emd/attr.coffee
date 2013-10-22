EMD.attr = (serialized_name, meta = {})->
  Em.assert "You must specify a serialized name", meta.serialized_name = serialized_name

  key = "_data.#{serialized_name}"

  meta.extra_keys ||= []
  unless meta.extra_keys instanceof Array
    meta.extra_keys = [meta.extra_keys]
  meta.extra_keys.unshift key
  property_args = meta.extra_keys
  delete meta.extra_keys

  property = (_, set)->
    if set != undefined
      @set 'isDirty', true
      if meta.convertTo
        @set key, meta.convertTo(set)
      else
        @set key, set
      set
    else
      existing = @get key
      if existing == undefined and meta.if_null
        if typeof meta.if_null == 'function'
          existing = meta.if_null.call @
        else existing = meta.if_null
      return meta.convertFrom(existing) if meta.convertFrom
      existing

  property.property.apply(property, property_args).meta(meta)

EMD.attr.moment = (serialized_name, meta = {})->
  meta.convertFrom = (date)->
    moment(date) if date
  meta.convertTo = (moment)->
    moment.toDate() if moment
  EMD.attr(serialized_name, meta)

EMD.attr.duration = (serialized_name, meta = {})->
  unit = meta.unit ||= 'seconds'
  meta.convertFrom = (unit_value)->
    moment.duration(unit_value,
      unit) unless unit_value == undefined || unit_value == null
  meta.convertTo = (duration)->
    duration.as(unit) if duration
  EMD.attr serialized_name, meta

EMD.attr.object = (serialized_name, meta = {})->
  meta.convertFrom = (json)->
    json ||= {} if meta.optional
    Em.ObjectProxy.create content: json
  meta.convertTo = (proxy)->
    proxy.get 'content'
  EMD.attr serialized_name, meta

EMD.attr.hasMany = (model_name, meta = {}) ->
  if typeof model_name == "object"
    # Support shorthand of: hasMany users: "Pw.User" as hasMany "Pw.User", urlBinding: "links.user"
    key = Em.keys(model_name)[0]
    val = model_name[key]
    model_name = val
    meta.urlBinding = "links.#{key}"

  Em.assert "You must specify model_name for hasMany" unless model_name
  Em.assert "You must specify urlBinding for hasMany" unless meta.urlBinding

  property = (->
    meta.query ||= {}
    if parent_id = @get 'id'
      meta.foreign_key ||= "#{Em.get @constructor, 'singular'}_id"
      meta.query[meta.foreign_key] ||= @get 'id'

    EMD.RecordArrayRelation.create
      parent: @
      modelBinding: model_name
      urlBinding: "parent." + meta.urlBinding
      query: meta.query
  ).property()

EMD.attr.belongsTo = (serialized_name_to_model_name, meta = {})->
  Em.assert "You must specify attr_id: 'Assoc.Type' for belongsTo" unless serialized_name_to_model_name instanceof Object
  serialized_name = Em.keys(serialized_name_to_model_name)[0]
  model_name = serialized_name_to_model_name[serialized_name]
  meta.typeString = model_name
  raw_type = null

  meta.convertFrom = (id)->
    raw_type = meta.type = Em.get model_name unless raw_type
    raw_type.find(id) if id

  meta.convertTo = (model)->
    model.get('id') if model

  EMD.attr serialized_name, meta
