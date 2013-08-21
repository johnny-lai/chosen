class URLDataSource extends CallbackDataSource

  search: (chosen, response_cb) ->
    ds = this

    $.ajax
      url: @source
      data: chosen.get_search_request()
      success: (data, textStatus, jqXHR) ->
        ds.did_search chosen, response_cb, data
        
      error: (jqXHR, textStatus, errorThrown) ->
        # Still call response_cb, if there is a failure
        ds.did_search chosen, response_cb, []
