#= require ../record_array

D.RecordArrayRelation = D.RecordArray.extend
  _parent: null
  parent: null

  init: ->
    @_super.apply @, arguments

  where: (opts = {})->
    query = @get 'query'
    new_query = $.extend query, opts

    D.RecordArrayRelation.create
      _parent: @
      urlBinding: '_parent.url'
      modelBinding: '_parent.model'
      query: new_query

  nextNew: ((_, set)->
    @create()
  ).property()

  nextNewIsntNew: (->
    @set 'nextNew' if @get 'nextNew.id'
  ).observes 'nextNew.id'

  create: (opts = {})->
    model = @get 'model'
    query = @get 'query'
    model.create $.extend query, opts
