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