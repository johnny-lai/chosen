class DataSource extends SelectParser

  # search_cb should be a function that accepts two arguments:
  # * A request object, with a single term property.
  # * A response callback. You must call this function and pass it an array
  #   with the results.
  constructor: (form_field, source) ->
    super(form_field)
    @source = source
      
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
    null
  
  # Should return the item data associated with the array_index
  get_item: (array_index) ->
    null
    
  get_item_by_value: (value) ->
    null
    
DataSource.instantiate = (form_field, source) ->
  if not source?
    new SelectParser(form_field)
  else if typeof source == "string"
    new URLDataSource(form_field, source)
  else if source.call?
    new CallbackDataSource(form_field, source)
  else if source.length?
    new ArrayDataSource(form_field, source)
  else
    throw new Error("Invalid source")
  