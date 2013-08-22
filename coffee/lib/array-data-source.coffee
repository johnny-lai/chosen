class ArrayDataSource extends DataSource

  search: (chosen, response_cb) ->
    if not @results?
      options = this.options_to_hash()
      @results = []
      this.add_option options, child for child in @source
    response_cb @results
  
  add_option: (options, child) ->
    value = child.value || child
    text = child.text || child.label || value
    option = options[value] || {}
    @results.push
      array_index: @results.length
      text: text,
      value: value,
      html: text,
      selected: child.selected || option.selected || false,
      disabled: child.disabled || option.disabled || false
      
  get_option_element: (array_index) ->
    this.get_option_element_by_value(this.get_item(array_index).value)

  get_item: (array_index) ->
    @results[array_index]