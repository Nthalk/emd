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
