class CallbackDataSource extends DataSource

  constructor: (form_field, source) ->
    super(form_field, source)
    @results = @select_parser.select_to_hash('value')
    @cache = {}
    
  search: (chosen, response_cb) ->
    if chosen.results_data?
      # Call @source function, setting this to the chosen object
      # @param request
      # @param response_cb
      key = JSON.stringify(chosen.get_search_request())
      data = @cache[key]
      if not data?
        chosen.loading(true)
        @perform_search chosen, (data) =>
          chosen.loading(false)
          @cache[key] = data
          response_cb (data)
      else
        response_cb(data)
    else
      this.did_search(chosen, response_cb, this.items_as_array())
  
  perform_search: (chosen, response_cb) ->
    @source.call chosen, chosen.get_search_request(), (data) =>
      @did_search(chosen, response_cb, data)
  
  did_search: (chosen, response_cb, data) ->
    # Merge with new results
    options = (this.add_option_from_data child for child in data)
      
    response_cb options
      
  add_option_from_data: (child) ->
    item = @results[child.value] || child

    item.text = item.label || item if not item.text?
    item.html = item.text if not item.html?
    item.value = item.text if not item.value
    item.array_index = item.value
    item.selected = item.selected || false
    item.disabled = item.disabled || false

    @results[item.value] = item
    item
  
  get_option_element: (array_index) ->
    # array_index is set to item.value in this DataSource
    this.get_option_element_by_value(array_index)
  
  get_item: (array_index) ->
    @results[array_index]
  
  get_item_by_value: (value) ->
    this.get_item value