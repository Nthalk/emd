#= require ../record_array

D.RecordArrayPaged = D.RecordArray.extend
  page: ((_, set)->
    if set != undefined
      @reload page: set
      set
    else
      @get("query.page") || 1
  ).property("query.page")

  totalRecords: null
  totalPages: null
  perPage: null
  nextPageUrl: null
  previousPageUrl: null
  hasNextPageBinding: "nextPageUrl"
  hasPreviousPageBinding: "previousPageUrl"

  nextPage: ->
    @set "url", @get("nextPageUrl")

  previousPage: ->
    @set "url", @get("previousPageUrl")

  extractMeta: (rsp)->
    @setProperties
      perPage: rsp.meta.per_page
      totalRecords: rsp.meta.total_records
      totalPages: rsp.meta.total_pages
      nextPageUrl: rsp.links.next_page
      previousPageUrl: rsp.links.previous_page
