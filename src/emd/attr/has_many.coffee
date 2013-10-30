EMD.attr.hasMany = (foreign_key_to_child_model, meta = {}) ->
  child_model_name = foreign_key_to_child_model
  if typeof foreign_key_to_child_model == 'object'
    foreign_key = Em.keys(foreign_key_to_child_model)[0]
    child_model_name = foreign_key_to_child_model[foreign_key]

  model = false
  meta.extra_keys ||= ['id']
  where = meta.where || ->
    query = {}
    query[foreign_key] = @get 'id'
    query

  results = false

  property = (triggered, set)->
    if results
      results.set 'query', where.call @
      return results

    model = Em.get child_model_name unless model
    results = model.where where.call @

  property.property.apply property, meta.extra_keys
