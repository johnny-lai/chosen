class CallbackDataSource extends DataSource

  search: (chosen, response_cb) ->
    @source.call(chosen, chosen.get_search_request(), response_cb)
  