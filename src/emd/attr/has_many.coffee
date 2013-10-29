EMD.attr.hasMany = (model_name, meta = {}) ->
  Em.assert "You must specify model_name for hasMany" unless model_name

  type = false
  query = false
  parent_name = false

  (->
    unless type
      type = Em.get model_name
      parent_name = Em.get @constructor, 'singular' unless parent_name
      belongs_to = type.attributes()[parent_name]
      query = {}
      query[belongs_to.serialized_name] = @get 'id'

    EMD.RecordArrayRelation.create
      parent: @
      modelBinding: model_name
      urlBinding: "parent." + meta.urlBinding
      query: query
  ).property()
