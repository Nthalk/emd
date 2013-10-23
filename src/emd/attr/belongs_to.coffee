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
