class ArrayDataSource

  constructor: (form_field, source) ->
    @form_field = form_field
    @source = source
    #@options_index = 0
    @parsed = []
    
  add_node: (child) ->
    this.add_option child

  add_option: (option) ->
    value = option.value || option
    text = option.label || value
    innerHTML = text
    @parsed.push
      array_index: @parsed.length
      #options_index: @options_index
      value: value
      text: text
      html: innerHTML
      selected: false
      disabled: false
      #group_array_index: group_position
      #classes: option.className
      #style: option.style.cssText
    #@options_index += 1

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

  to_array: ->
    @options_index = 0
    @parsed = []
    this.add_node (child) for child in @source
    @parsed

  option: (item) ->
    # Check if option already exists
    e = $(@form_field)
    option = e.find('option[value="' + item.value + '"]')
    if !option.length
      e.append('<option value="' + item.value + '"></option>')
      option = e.find('option[value="' + item.value + '"]')
    option[0]