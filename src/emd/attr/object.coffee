EMD.attr.object = (serialized_name, meta = {})->
  meta.convertFrom = (json)->
    json ||= {} if meta.optional
    Em.ObjectProxy.create content: json
  meta.convertTo = (proxy)->
    proxy.get 'content'
  EMD.attr serialized_name, meta
