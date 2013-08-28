class SelectParser

  constructor: (form_field) ->
    @form_field = form_field

  add_node: (child) ->
    if child.nodeName.toUpperCase() is "OPTGROUP"
      this.add_group child
    else
      this.add_option child

  add_group: (group) ->
    group_position = @parsed.length
    @parsed.push
      array_index: group_position
      group: true
      label: this.escapeExpression(group.label)
      children: 0
      disabled: group.disabled
    this.add_option( option, group_position, group.disabled ) for option in group.childNodes

  add_option: (option, group_position, group_disabled) ->
    if option.nodeName.toUpperCase() is "OPTION"
      if option.text != ""
        if group_position?
          @parsed[group_position].children += 1
        item = this.option_to_item option, group_disabled
        item.array_index = @parsed.length
        item.options_index = @options_index
        item.disabled = group_disabled if group_disabled is true
        item.group_array_index = group_position
        
        @parsed.push item
      else
        @parsed.push
          array_index: @parsed.length
          options_index: @options_index
          empty: true
      @options_index += 1

  escapeExpression: (text) ->
    if not text? or text is false
      return ""
    unless /[\&\<\>\"\'\`]/.test(text)
      return text
    map =
      "<": "&lt;"
      ">": "&gt;"
      '"': "&quot;"
      "'": "&#x27;"
      "`": "&#x60;"
    unsafe_chars = /&(?!\w+;)|[\<\>\"\'\`]/g
    text.replace unsafe_chars, (chr) ->
      map[chr] || "&amp;"
  
  search: (chosen, response_cb) ->
    response_cb this.select_to_array()

  select_to_array: ->
    if not @parsed?
      @options_index = 0
      @parsed = []
      this.add_node( child ) for child in @form_field.childNodes
    @parsed
  
  select_to_hash: (key) ->
    hash = {}
    for child in @form_field.options
      item = this.option_to_item(child)
      hash[item[key]] = item
    hash
  
  option_to_item: (option) ->
    item =
      value: option.value
      text: option.text
      html: option.innerHTML
      selected: option.selected
      disabled: option.disabled
      classes: option.className
      style: option.style.cssText
    
    data = option.attributes.getNamedItem('data')
    if data?
      data = JSON.parse(data.value)
      item[k] = v for k, v of data
    
    item
  
  get_option_element: (array_index) ->
    @form_field.options[array_index]

  get_item: (array_index) ->
    @parsed[array_index]
