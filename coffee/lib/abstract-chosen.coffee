class AbstractChosen

  constructor: (@form_field, @options={}) ->
    return unless AbstractChosen.browser_is_supported(@options)
    @search_count = 0
    @scopes = []
    @scopes_of_selection = []
    @is_multiple = @form_field.multiple
    this.set_default_text()
    this.set_default_values()

    this.setup()

    this.set_up_html()
    this.register_observers()

  set_default_values: ->
    @click_test_action = (evt) =>
      this.test_active_click(evt)
      true
    @activate_action = (evt) => this.activate_field(evt)
    @active_field = false
    @mouse_on_container = false
    @results_showing = false
    @delete_option = false
    @result_highlighted = null
    @allow_single_deselect = if @options.allow_single_deselect? and @form_field.options[0]? and @form_field.options[0].text is "" then @options.allow_single_deselect else false
    @show_scope_of_selected_item = @options.show_scope_of_selected_item || false
    @disable_search_threshold = @options.disable_search_threshold || 0
    @disable_search = @options.disable_search || false
    @enable_split_word_search = if @options.enable_split_word_search? then @options.enable_split_word_search else true
    @group_search = if @options.group_search? then @options.group_search else true
    @search_contains = @options.search_contains || false
    @single_backstroke_delete = if @options.single_backstroke_delete? then @options.single_backstroke_delete else true
    @max_selected_options = @options.max_selected_options || Infinity
    @overflow_container = @options.overflow_container
    @inherit_select_classes = @options.inherit_select_classes || false
    @display_selected_options = if @options.display_selected_options? then @options.display_selected_options else true
    @display_disabled_options = if @options.display_disabled_options? then @options.display_disabled_options else true
    @source = DataSource.instantiate @form_field, @options.source

  set_default_text: ->
    if @form_field.getAttribute("data-placeholder")
      @default_text = @form_field.getAttribute("data-placeholder")
    else if @is_multiple
      @default_text = @options.placeholder_text_multiple || @options.placeholder_text || AbstractChosen.default_multiple_text
    else
      @default_text = @options.placeholder_text_single || @options.placeholder_text || AbstractChosen.default_single_text

    @results_none_found = @form_field.getAttribute("data-no_results_text") || @options.no_results_text || AbstractChosen.default_no_result_text
    @remove_option_text = @options.remove_option_text || AbstractChosen.default_remove_option_text
    @removed_text = @options.removed_text || AbstractChosen.default_removed_text
    @default_single_select_field_hint = @options.single_select_field_hint || AbstractChosen.default_single_select_field_hint
    @default_single_select_result_singular_hint = @options.single_select_result_singular_hint || AbstractChosen.default_single_select_result_singular_hint
    @default_single_select_results_plural_hint = @options.single_select_results_plural_hint || AbstractChosen.default_single_select_results_plural_hint
    @default_single_select_highlighted_result_hint = @options.single_select_highlighted_result_hint || AbstractChosen.default_single_select_highlighted_result_hint
    @default_selected_option_hint = @options.default_selected_option_hint || AbstractChosen.default_selected_option_hint;
    @default_multi_select_selected_options_hint = @options.default_multi_select_selected_options_hint || AbstractChosen.default_multi_select_selected_options_hint;
    @default_multi_select_selected_option_hint = @options.default_multi_select_selected_option_hint || AbstractChosen.default_multi_select_selected_option_hint;
    @default_multi_select_no_options_selected_hint = @options.default_multi_select_no_options_selected_hint || AbstractChosen.default_multi_select_no_options_selected_hint;

  mouse_enter: -> @mouse_on_container = true
  mouse_leave: -> @mouse_on_container = false

  input_focus: (evt) ->
    if @is_multiple
      setTimeout (=> this.container_mousedown()), 50 unless @active_field
    else
      @activate_field() unless @active_field

  input_blur: (evt) ->
    if not @mouse_on_container
      @active_field = false
      setTimeout (=> this.blur_test()), 100

  results_option_build: (options) ->
    content = ''
    ref_this = this
    visible_options_counter = 0

    @results_data.forEach (element) ->
      if !element.group and element.search_match and ref_this.include_option_in_results(element)
        visible_options_counter += 1
        element.aria_posinset = visible_options_counter

    for data in @results_data
      if data.group
        content += this.result_add_group data
      else
        content += this.result_add_option data, visible_options_counter

    # this select logic pins on an awkward flag
    # we can make it better
    if options?.first
      for data in this.get_selected_items()
        if @is_multiple
          this.choice_build data
        else
          this.single_set_selected_text(data.text)

    content

  result_add_option: (option, options_length) ->
    return '' unless option.search_match
    return '' unless this.include_option_in_results(option)

    classes = []
    classes.push "active-result" if !option.disabled and !(option.selected and @is_multiple)
    classes.push "disabled-result" if option.disabled and !(option.selected and @is_multiple)
    classes.push "result-selected" if option.selected
    classes.push "group-option" if @source.get_group(option)?
    classes.push "is-scope" if option.is_scope
    classes.push option.classes if option.classes != ""

    option_el = document.createElement("li")
    option_el.className = classes.join(" ")
    option_el.style.cssText = option.style
    option_el.setAttribute("data-option-array-index", option.array_index)
    option_el.setAttribute("role", "option")
    option_el.setAttribute("aria-posinset", option.aria_posinset)
    option_el.setAttribute("aria-setsize", options_length)
    option_el.setAttribute("id", this.search_results.attr('id') + '_option_' + option.array_index)
    option_el.innerHTML = if option.is_scope
      option.search_html + '<div><i /></div>'
    else
      option.search_html

    this.outerHTML(option_el)

  result_add_group: (group) ->
    return '' unless group.search_match || group.group_match
    return '' unless group.active_options > 0

    group_el = document.createElement("li")
    group_el.className = "group-result"
    group_el.innerHTML = group.search_html

    this.outerHTML(group_el)

  results_update_field: ->
    this.set_default_text()
    this.results_reset_cleanup() if not @is_multiple
    this.result_clear_highlight()
    this.results_build () ->
      this.winnow_results() if @results_showing

  reset_single_select_options: () ->
    for result in @results_data
      result.selected = false if result.selected

  results_toggle: ->
    if @results_showing
      this.results_hide()
    else
      this.results_show()

  results_search: (evt) ->
    if @results_showing
      this.winnow_results()
    else
      this.results_show()

  winnow_results: (cb) ->
    this.no_results_clear()

    results = 0

    searchText = this.get_search_text()
    searchHTML = this.escape_html(searchText)
    escapedSearchHTML = searchHTML.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")
    regexAnchor = if @search_contains then "" else "^"
    regex = new RegExp(regexAnchor + escapedSearchHTML, 'i')
    zregex = new RegExp(escapedSearchHTML, 'i')

    this.search () ->
      for option in @results_data

        option.search_match = false
        results_group = null

        if this.include_option_in_results(option)

          if option.group
            option.group_match = false
            option.active_options = 0

          results_group = @source.get_group(option)
          if results_group
            results += 1 if results_group.active_options is 0 and results_group.search_match
            results_group.active_options += 1
                  
          unless option.group and not @group_search

            option.search_html = if option.group then this.escape_html(option.label) else option.html
            option.search_match = this.search_string_match(option.search_html, regex)
            results += 1 if option.search_match and not option.group

            if option.always_show
              option.search_match = true
            else if option.search_match
              if searchText.length
                startpos = option.search_html.search zregex
                html = option.search_html.substr(0, startpos + searchHTML.length) + '</em>' + option.search_html.substr(startpos + searchHTML.length)
                option.search_html = html.substr(0, startpos) + '<em>' + html.substr(startpos)

              results_group.group_match = true if results_group?
            
            else if results_group and results_group.search_match
              option.search_match = true

      this.result_clear_highlight()

      if results < 1 and searchText.length
        this.update_results_content ""
        this.no_results searchText
        this.set_text_for_screen_reader(this.results_none_found)
      else
        this.update_results_content this.results_option_build()
        this.winnow_results_set_highlight()
  
      cb.call(this) if cb?

  search_string_match: (search_string, regex) ->
    if regex.test search_string
      return true
    else if @enable_split_word_search and (search_string.indexOf(" ") >= 0 or search_string.indexOf("[") == 0)
      #TODO: replace this substitution of /\[\]/ with a list of characters to skip.
      parts = search_string.replace(/\[|\]/g, "").split(" ")
      if parts.length
        for part in parts
          if regex.test part
            return true

  choices: ->
    result = []
    for option in @form_field.options
      result.push option.value if option.value && option.selected
    result
    
  choices_count: ->
    return @selected_option_count if @selected_option_count?

    @selected_option_count = 0
    for option in @form_field.options
      @selected_option_count += 1 if option.selected
    
    return @selected_option_count

  choices_click: (evt) ->
    evt.preventDefault()
    this.results_show() unless @results_showing or @is_disabled

  keyup_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    switch stroke
      when 8
        if @backstroke_length < 1 and this.choices_count() > 0
          this.keydown_backstroke()
        else if not @pending_backstroke
          this.result_clear_highlight()
          this.results_search()
      when 13
        evt.preventDefault()
        if this.results_showing
          if @result_highlight and not @delete_option
              item = @source.get_item(@result_highlight[0].getAttribute("data-option-array-index"))
              if not item.is_scope and not @is_multiple
                if item.text == null or item.text == @default_text
                  @search_field.attr("aria-label", @input_aria_label);
                else
                  @search_field.attr("aria-label", @input_aria_label + ". " + item.text)
          this.result_select(evt)
      when 27
        if @results_showing
          this.results_hide()
          if not @is_multiple and @selected_item.find("span").first().text().trim()
            this.set_text_for_screen_reader(@default_selected_option_hint.replace("option_value", @selected_item.find("span").first().text()))
        return true
      when 9, 38, 40, 16, 91, 17
        # don't do anything on these keys
      else this.results_search()

  container_width: ->
    return if @options.width? then @options.width else "#{@form_field.offsetWidth}px"

  include_option_in_results: (option) ->
    return false if @is_multiple and (not @display_selected_options and option.selected)
    return false if not @display_disabled_options and option.disabled
    return false if option.empty

    return true

  get_search_request: ->
    term: this.get_search_text()
    scopes: @scopes
  
  search: (cb) ->
    # TODO: Consider notifying data sources when their search requests are no
    # longer necessary
    that = this
    this_request = ++@search_count
    @source.search this, (data) ->
      # Ignore callbacks with data that are not the last search request
      if that.search_count == this_request
        that.results_data = data
        cb.call(that) if cb?
  
  search_results_touchstart: (evt) ->
    @touch_started = true
    this.search_results_mouseover(evt)

  search_results_touchmove: (evt) ->
    @touch_started = false
    this.search_results_mouseout(evt)

  search_results_touchend: (evt) ->
    this.search_results_mouseup(evt) if @touch_started

  outerHTML: (element) ->
    return element.outerHTML if element.outerHTML
    tmp = document.createElement("div")
    tmp.appendChild(element)
    tmp.innerHTML

  # class methods and variables ============================================================ 

  @browser_is_supported: (options = {}) ->
    return true if options.disable_browser_check
    if window.navigator.appName == "Microsoft Internet Explorer"
      if document.documentMode
        # IE 7 does not provide document.documentMode
        return document.documentMode >= 8
      else
        # Parse userAgent string
        re = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})")
        if re.exec(navigator.userAgent)
          return parseFloat(RegExp.$1) >= 7.0
      return false
    if /iP(od|hone)/i.test(window.navigator.userAgent)
      return false
    if /Android/i.test(window.navigator.userAgent)
      return false if /Mobile/i.test(window.navigator.userAgent)
    return true

  @default_multiple_text: "Select Some Options"
  @default_single_text: "Select an Option"
  @default_no_result_text: "No results match"
  @default_remove_option_text: "Remove Option"
  @default_removed_text: "Removed"
  @default_single_select_field_hint = "Use space or down arrow key to open the combobox."
  @default_single_select_result_singular_hint = "aria_setsize result is available."
  @default_single_select_results_plural_hint = "aria_setsize results are available."
  @default_single_select_highlighted_result_hint = "result_highlight_text. aria_posinset of aria_setsize is highlighted."
  @default_selected_option_hint = "option_value selected."
  @default_multi_select_selected_options_hint = "aria_label multiselect combobox has selected_options_size options selected."
  @default_multi_select_selected_option_hint = "aria_label multiselect combobox has selected_options_size option selected."
  @default_multi_select_no_options_selected_hint = "aria_label multiselect combobox has no options selected."
