class ArrayDataSource extends DataSource

  search: (chosen, response_cb) ->
    if not @results?
      @results = []
      this.add_option child for child in @source
    response_cb @results
  
  add_option: (child) ->
    value = child.value || child
    text = child.label || value
    @results.push
      array_index: @results.length
      text: text,
      value: value,
      html: text,
      selected: false,
      disabled: false
      
  get_option_element: (array_index) ->
    this.get_option_element_by_value(this.get_item(array_index).value)

  get_item: (array_index) ->
    @results[array_index]