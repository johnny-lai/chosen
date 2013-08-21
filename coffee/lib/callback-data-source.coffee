class CallbackDataSource extends DataSource

  constructor: (form_field, source) ->
    super(form_field, source)
    @results = {}
    
  search: (chosen, response_cb) ->
    ds = this
    # Call @source function, setting this to the chosen object
    # @param request
    # @param response_cb
    @source.call chosen, chosen.get_search_request(), (data) ->
      ds.did_search(chosen, response_cb, data)
  
  did_search: (chosen, response_cb, data) ->
    results = {}
      
    # Keep only results that have been chosen
    for value in chosen.choices()
      results[value] = @results[value]
    @results = results
    
    # Merge with new results
    options = (this.add_option child for child in data)
      
    response_cb options
      
  add_option: (child) ->
    item = @results[child.value] || child
    
    item.array_index = item.value
    item.html = item.label || item if not item.html?
    item.selected = item.selected || false
    item.disabled = item.disabled || false

    @results[item.value] = item
    item
  
  get_option_element: (array_index) ->
    this.get_option_element_by_value(array_index)
  
  get_item: (array_index) ->
    @results[array_index]