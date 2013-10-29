EMD.attr.hasMany = (foreign_key_to_child_model, meta = {}) ->
  foreign_key = Em.keys(foreign_key_to_child_model)[0]
  child_model_name = foreign_key_to_child_model[foreign_key]

  model = false
  query = {}
  (->
    query[foreign_key] = @get 'id'
    model = Em.get child_model_name unless model
    model.where query
  ).property 'id'
