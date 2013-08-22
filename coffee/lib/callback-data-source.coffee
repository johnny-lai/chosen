class CallbackDataSource extends DataSource

  constructor: (form_field, source) ->
    super(form_field, source)
    @results = this.options_to_hash()
    
  search: (chosen, response_cb) ->
    if chosen.results_data?
      # Call @source function, setting this to the chosen object
      # @param request
      # @param response_cb
      this.perform_search(chosen, response_cb)
    else
      this.did_search(chosen, response_cb, this.to_array())
  
  perform_search: (chosen, response_cb) ->
    ds = this
    @source.call chosen, chosen.get_search_request(), (data) ->
      ds.did_search(chosen, response_cb, data)
  
  did_search: (chosen, response_cb, data) ->
    results = {}
    
    # Keep only results that have been chosen
    for value in chosen.choices()
      results[value] = @results[value]
    @results = results
    
    # Merge with new results
    options = (this.add_option_from_data child for child in data)
      
    response_cb options
      
  add_option_from_data: (child) ->
    item = @results[child.value] || child
    
    item.array_index = item.value
    item.text = item.label || item if not item.text?
    item.html = item.text if not item.html?
    item.selected = item.selected || false
    item.disabled = item.disabled || false

    @results[item.value] = item
    item
  
  get_option_element: (array_index) ->
    this.get_option_element_by_value(array_index)
  
  get_item: (array_index) ->
    @results[array_index]