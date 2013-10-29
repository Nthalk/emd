EMD.attr.object = (serialized_name, meta = {})->
  meta.convertFromData = (json)->
    json ||= {} if meta.optional
    Em.ObjectProxy.create content: json
  meta.convertToData = (proxy)->
    proxy.get 'content'
  EMD.attr serialized_name, meta
