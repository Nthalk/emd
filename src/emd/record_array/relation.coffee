#= require ../record_array

EMD.RecordArrayRelation = EMD.RecordArray.extend
  _parent: null
  parent: null

  where: (opts = {})->
    query = @get 'query'
    new_query = $.extend query, opts

    EMD.RecordArrayRelation.create
      _parent: @
      urlBinding: '_parent.url'
      modelBinding: '_parent.model'
      query: new_query

  nextNew: ((_, set)->
    @create()
  ).property()

  then: (ok, er)->
    @one 'load', ok if ok
    @one 'error', er if er
    @get 'content'
    @

  nextNewIsntNew: (->
    @set 'nextNew' if @get 'nextNew.id'
  ).observes 'nextNew.id'
