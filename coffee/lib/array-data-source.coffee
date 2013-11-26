class ArrayDataSource extends DataSource

  add_option: (options, child) ->
    value = child.value || child
    item = options[value] || {}
    item[k] = v for k, v of child

    item.text = item.label || item if not item.text?
    item.html = item.text if not item.html?
    item.value = value if not item.value
    item.array_index = @results.length
    item.selected = item.selected || false
    item.disabled = item.disabled || false

    @results.push(item)
    
  get_option_element: (array_index) ->
    this.get_option_element_by_value(this.get_item(array_index).value)

  get_item: (array_index) ->
    this.items_as_array()[array_index]
    
  get_item_by_value: (value) ->
    return obj for obj in @results when ""+obj.value == ""+value
    null

  items_as_array: () ->
    if not @results?
      options = @select_parser.select_to_hash('value')
      @results = @results = []
      this.add_option options, child for child in @source
    @results