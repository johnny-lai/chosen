class DataSource

  # search_cb should be a function that accepts two arguments:
  # * A request object, with a single term property.
  # * A response callback. You must call this function and pass it an array
  #   with the results.
  constructor: (form_field, source) ->
    @form_field = form_field
    @source = source
    @select_parser = new SelectParser(form_field)

  get_option_element_by_value: (value) ->
    # Check if option already exists
    e = $(@form_field)
    option = e.find('option[value="' + value + '"]')
    if !option.length
      e.append('<option value="' + value + '"></option>')
      option = e.find('option[value="' + value + '"]')
    option[0]
    
  # Should return the option element represented by the array_index
  get_option_element: (array_index) ->
    @select_parser.get_option_element(array_index)
  
  # Should return the item data associated with the array_index
  get_item: (array_index) ->
    @select_parser.get_item(array_index)
    
  get_item_by_value: (value) ->
    @select_parser.get_item_by_value(value)

  search: (chosen, response_cb) ->
    filter_scope = if not chosen.results_data?
      # First time search, we use the selected item as the scopes
      @parsed_by_scopes = {}
      for item in this.items_as_array()
        in_scope = item.in_scope
        if not in_scope?
          in_scope = null
        if item.selected
          scope = item.in_scope
        @parsed_by_scopes[in_scope] ||= []
        @parsed_by_scopes[in_scope].push(item)
      scope
    else
      scopes = chosen.get_search_request().scopes
      if scopes.length
        scopes[scopes.length - 1]

    filter_scope = null if not filter_scope?
    results = @parsed_by_scopes[filter_scope]
    results = [] if not results?
    response_cb results

  items_as_array: () ->
    @select_parser.select_to_array()

DataSource.instantiate = (form_field, source) ->
  if not source?
    new DataSource(form_field)
  else if typeof source == "string"
    new URLDataSource(form_field, source)
  else if source.call?
    new CallbackDataSource(form_field, source)
  else if source.length?
    new ArrayDataSource(form_field, source)
  else
    throw new Error("Invalid source")
  