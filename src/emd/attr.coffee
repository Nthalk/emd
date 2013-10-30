#<!--
# = require_self
# = require_tree ./attr
#-->

EMD.attr = (serialized_name, meta = {})->
  Em.assert "You must specify a serialized name", meta.serialized_name = serialized_name

  key = "_data.#{serialized_name}"

  if meta.convertTo
    Em.deprecate "EMD.attr, use convertToData instead of convertTo"
    meta.convertToData = meta.convertTo
    delete meta.convertTo

  if meta.convertFrom
    Em.deprecate "EMD.attr, use convertFromData instead of convertFrom"
    meta.convertFromData = meta.convertFrom
    delete meta.convertFrom

  meta.extra_keys ||= []
  unless meta.extra_keys instanceof Array
    meta.extra_keys = [meta.extra_keys]
  meta.extra_keys.unshift key
  property_args = meta.extra_keys
  delete meta.extra_keys

  property = (_, set)->
    if set != undefined
      @set 'isDirty', true
      if meta.convertToData
        @set key, meta.convertToData set
      else
        @set key, set
      set
    else
      existing = @get key
      if existing is undefined and meta.if_null
        if typeof meta.if_null is 'function'
          existing = meta.if_null.call @
        else existing = meta.if_null
      return meta.convertFromData(existing) if meta.convertFromData
      existing

  property.property.apply(property, property_args).meta(meta)
