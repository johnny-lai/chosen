$ = jQuery

$.fn.extend({
  chosen: (options, value) ->
    # Do no harm and return as soon as possible for unsupported browsers, namely IE6 and IE7
    # Continue on if running IE document type but in compatibility mode
    return this unless AbstractChosen.browser_is_supported(options)
    this.each (input_field) ->
      $this = $ this
      chosen = $this.data('chosen')
      if options is 'destroy' && chosen
        chosen.destroy()
      else if options is 'searchValue' && chosen
        chosen.search_value(value)
      else unless chosen
        $this.data('chosen', new Chosen(this, options))

      return

})

class Chosen extends AbstractChosen

  setup: ->
    @form_field_jq = $ @form_field
    @current_selectedIndex = @form_field.selectedIndex
    @is_rtl = @form_field_jq.hasClass "chosen-rtl"
    @overflow_container = if typeof @overflow_container is "undefined" then @form_field_jq.parent() else @overflow_container

  set_up_html: ->
    container_base_classes = []
    container_base_classes.push "chosen-container-" + (if @is_multiple then "multi" else "single")
    container_base_classes.push @form_field.className if @inherit_select_classes && @form_field.className
    container_base_classes.push "chosen-rtl" if @is_rtl

    container_classes = ["chosen-container"].concat(container_base_classes)
    drop_classes = ["chosen-drop"].concat(container_base_classes)

    container_props =
      'class': container_classes.join ' '
      'style': "width: #{this.container_width()};"
      'title': @form_field.title

    container_props.id = @form_field.id.replace(/[^\w]/g, '_') + "_chosen" if @form_field.id.length

    @container = ($ "<div />", container_props)

    if @is_multiple
      choices_class = ['chosen-choices']
      @container.html '<ul class="' + 
        this.escape_html(choices_class.join(' ')) + 
        '"><li class="search-field"><input type="text" value="' +
        this.escape_html(@default_text) + '" class="default" autocomplete="off" style="width:25px;" /></li></ul><div class="' + 
        this.escape_html(drop_classes.join(' ')) + '"><ul class="chosen-results"></ul></div>'
    else
      a_classes = ['chosen-single', 'chosen-default']
      a_classes.push('chosen-single-with-scopes') if @options.show_scope_of_selected_item
      @container.html '<a class="' + 
        this.escape_html(a_classes.join(' ')) + '" tabindex="0"><span>' +
        this.escape_html(@default_text) + '</span><div><b></b></div></a><div class="' +
        this.escape_html(drop_classes.join(' ')) + '"><div class="chosen-search"><ul class="chosen-scopes"><li class="search-field"><input type="text" class="default" autocomplete="off" /></li></ul><div class="chosen-search-state"></div><div class="chosen-overflow"></div></div><ul class="chosen-results"></ul></div>'

    @form_field_jq.hide().after @container
    @dropdown = @container.find('div.chosen-drop').first()

    @containers = @container.add(@dropdown)

    if @overflow_container
      $(@overflow_container).scroll (evt) => @update_position(evt)

    @search_field = @container.find('input').first()
    @search_results = @container.find('ul.chosen-results').first()

    @search_no_results = @container.find('li.no-results').first()

    if @is_multiple
      @search_choices = @container.find('ul.chosen-choices').first()
      @search_container = @container.find('li.search-field').first()
    else
      @search_container = @container.find('li.search-field').first()
      @search_scroller = @container.find('ul.chosen-scopes')
      @selected_item = @container.find('.chosen-single').first()
    
    this.set_tab_index()
    this.set_label_behavior()

    this.results_build () ->
      @form_field_jq.trigger("chosen:ready", {chosen: this})


    $("body").append( @dropdown )

  register_observers: ->
    @form_field_jq.bind 'remove', (evt) => this.destroy()
    @container.bind 'mousedown.chosen', (evt) => this.container_mousedown(evt); return
    @container.bind 'mouseup.chosen', (evt) => this.container_mouseup(evt); return
    @container.bind 'mouseenter.chosen', (evt) => this.mouse_enter(evt); return
    @container.bind 'mouseleave.chosen', (evt) => this.mouse_leave(evt); return
    @dropdown.bind 'mouseenter.chosen', (evt) => this.mouse_enter(evt); return
    @dropdown.bind 'mouseleave.chosen', (evt) => this.mouse_leave(evt); return

    @search_results.bind 'mouseup.chosen', (evt) => this.search_results_mouseup(evt); return
    @search_results.bind 'mouseover.chosen', (evt) => this.search_results_mouseover(evt); return
    @search_results.bind 'mouseout.chosen', (evt) => this.search_results_mouseout(evt); return
    @search_results.bind 'mousewheel.chosen DOMMouseScroll.chosen', (evt) => this.search_results_mousewheel(evt); return

    @search_results.bind 'touchstart.chosen', (evt) => this.search_results_touchstart(evt); return
    @search_results.bind 'touchmove.chosen', (evt) => this.search_results_touchmove(evt); return
    @search_results.bind 'touchend.chosen', (evt) => this.search_results_touchend(evt); return


    @form_field_jq.bind "chosen:updated.chosen", (evt) => this.results_update_field(evt); return
    @form_field_jq.bind "chosen:activate.chosen", (evt) => this.activate_field(evt); return
    @form_field_jq.bind "chosen:open.chosen", (evt) => this.container_mousedown(evt); return
    @form_field_jq.bind "chosen:close.chosen", (evt) => this.input_blur(evt); return

    if @search_scroller
      @search_scroller.bind 'click.chosen', (evt) => this.activate_field(evt); return
    
    @search_field.bind 'blur.chosen', (evt) => this.input_blur(evt); return
    @search_field.bind 'keyup.chosen', (evt) => this.keyup_checker(evt); return
    @search_field.bind 'keydown.chosen', (evt) => this.keydown_checker(evt); return
    @search_field.bind 'focus.chosen', (evt) => this.input_focus(evt); return
    @search_field.bind 'click.chosen', (evt) => evt.stopPropagation(); return

    if @is_multiple
      @search_choices.bind 'click.chosen', (evt) => this.choices_click(evt); return
    else
      @container.bind 'click.chosen', (evt) -> evt.preventDefault(); return # gobble click of anchor

  destroy: ->
    $(document).unbind "click.chosen", @click_test_action
    if @search_field[0].tabIndex
      @form_field_jq[0].tabIndex = @search_field[0].tabIndex

    @container.remove()
    @dropdown.remove()
    @form_field_jq.removeData('chosen')
    @form_field_jq.show()

  search_field_disabled: ->
    @is_disabled = @form_field_jq[0].disabled
    if(@is_disabled)
      @container.addClass 'chosen-disabled'
      @search_field[0].disabled = true
      @selected_item.unbind "focus.chosen", @activate_action if !@is_multiple
      this.close_field()
    else
      @container.removeClass 'chosen-disabled'
      @search_field[0].disabled = false
      @selected_item.bind "focus.chosen", @activate_action if !@is_multiple

  container_mousedown: (evt) ->
    if !@is_disabled
      if evt and evt.type is "mousedown" and not @results_showing
        evt.stopPropagation()

      if not (evt? and ($ evt.target).hasClass "search-choice-close")
        if not @active_field
          @search_field.val "" if @is_multiple
          $(document).bind 'click.chosen', @click_test_action
          this.results_show()
        else if not @is_multiple and evt and (($(evt.target)[0] == @selected_item[0]) || $(evt.target).parents("a.chosen-single").length)
          evt.preventDefault()
          this.results_toggle()

        this.activate_field()

  container_mouseup: (evt) ->
    this.results_reset(evt) if evt.target.nodeName is "ABBR" and not @is_disabled

  search_results_mousewheel: (evt) ->
    delta = -evt.originalEvent.wheelDelta or evt.originalEvent.detail if evt.originalEvent
    if delta?
      evt.preventDefault()
      delta = delta * 40 if evt.type is 'DOMMouseScroll'
      @search_results.scrollTop(delta + @search_results.scrollTop())

  blur_test: (evt) ->
    this.close_field() if not @active_field and @container.hasClass "chosen-container-active"

  close_field: ->
    $(document).unbind "click.chosen", @click_test_action

    @active_field = false
    this.results_hide()

    @container.removeClass "chosen-container-active"
    this.clear_backstroke()

    this.result_scopes_build()
    
    this.show_search_field_default()
    this.search_field_scale()

  activate_field: ->
    @container.addClass "chosen-container-active"
    @active_field = true

    @search_field.focus()
    @search_field.val(@search_field.val())


  test_active_click: (evt) ->
    if @containers.is($(evt.target).closest('.chosen-container, .chosen-drop'))
      @active_field = true
    else
      this.close_field()

  results_build: (cb) ->
    @parsing = true
    @selected_option_count = null

    this.search () ->
      if @is_multiple
        @search_choices.find("li.search-choice").remove()
      else if not @is_multiple
        this.single_set_selected_text()
        if @disable_search or @results_data.length <= @disable_search_threshold
          @search_field[0].readOnly = true
          @containers.addClass "chosen-container-single-nosearch"
        else
          @search_field[0].readOnly = false
          @containers.removeClass "chosen-container-single-nosearch"

      this.update_results_content this.results_option_build({first:true})

      this.search_field_disabled()
      this.show_search_field_default()
      this.search_field_scale()

      @parsing = false
  
      cb.call(this) if cb?

  result_do_highlight: (el) ->
    if el.length
      this.result_clear_highlight()

      @result_highlight = el
      @result_highlight.addClass "highlighted"

      maxHeight = parseInt @search_results.css("maxHeight"), 10
      visible_top = @search_results.scrollTop()
      visible_bottom = maxHeight + visible_top

      high_top = @result_highlight.position().top + @search_results.scrollTop()
      high_bottom = high_top + @result_highlight.outerHeight()

      if high_bottom >= visible_bottom
        @search_results.scrollTop if (high_bottom - maxHeight) > 0 then (high_bottom - maxHeight) else 0
      else if high_top < visible_top
        @search_results.scrollTop high_top

  result_clear_highlight: ->
    @result_highlight.removeClass "highlighted" if @result_highlight
    @result_highlight = null

  results_show: ->
    if @is_multiple and @max_selected_options <= this.choices_count()
      @form_field_jq.trigger("chosen:maxselected", {chosen: this})
      return false

    @container.addClass "chosen-with-drop"

    @results_showing = true

    this.update_position()

    @search_field.focus()
    @search_field.val @search_field.val()
    this.search_field_scale()

    this.winnow_results()

  update_position: ->
    dd_top = if @is_multiple then @container.height() else (@container.height() - 1)
    offset = @container.offset()
    @dropdown.css {
      "top": (offset.top + dd_top) + "px",
      "left": offset.left + "px",
      "width": (this.container.outerWidth(true) - 2) + "px",  # Subtract border because we are *not* in border-box mode
      "maxHeight": "99999px"
    }
    if @results_showing
      @form_field_jq.trigger("chosen:showing_dropdown", {chosen: this})
      @dropdown.css {
        "left": offset.left + "px"
      }

      @search_results.css("maxHeight", "240px")

      # Fix maximum size
      # realDropdownTop = @dropdown.offset().top - $(window).scrollTop()
      # maxHeight = $(window).height() - realDropdownTop
      # maxHeight = 240 if maxHeight > 240
      # maxHeight = 100 if maxHeight < 100
      # @dropdown.css("maxHeight", maxHeight + "px")
      # @search_results.css("maxHeight", ( maxHeight - @search_container.height() - 10 ) + "px")
    else
      @dropdown.css {
        "left": "-9999px"
      }

  update_results_content: (content) ->
    @search_results.html content

  results_hide: ->
    # Note that we do not use display: none to hide the dropdown. This is because
    # we rely on events triggered from the input box inside the dropdown. If the
    # dropdown's display was set to none, the events will no longer fire. The
    # control will also no longer participate in the TAB events properly.
    if @results_showing
      @search_results.scrollTop(0);

      this.result_clear_highlight()

      @container.removeClass "chosen-with-drop"
      @form_field_jq.trigger("chosen:hiding_dropdown", {chosen: this})
      @dropdown.css {
        "left": "-9999px"
      }
    @results_showing = false


  set_tab_index: (el) ->
    if @form_field.tabIndex
      ti = @form_field.tabIndex
      @form_field.tabIndex = -1
      @search_field[0].tabIndex = ti

  set_label_behavior: ->
    @form_field_label = @form_field_jq.parents("label") # first check for a parent label
    if not @form_field_label.length and @form_field.id.length
      @form_field_label = $("label[for='#{@form_field.id}']") #next check for a for=#{id}

    if @form_field_label.length > 0
      @form_field_label.bind 'click.chosen', (evt) => if @is_multiple then this.container_mousedown(evt) else this.activate_field()

  show_search_field_default: ->
    if @is_multiple and this.choices_count() < 1 and not @active_field
      @search_field.val(@default_text)
      @search_field.addClass "default"
    else
      @search_field.val("")
      @search_field.removeClass "default"

  search_results_mouseup: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    if target.length
      @result_highlight = target
      this.result_select(evt)
      @search_field.focus()

  search_results_mouseover: (evt) ->
    target = if $(evt.target).hasClass "active-result" then $(evt.target) else $(evt.target).parents(".active-result").first()
    this.result_do_highlight( target ) if target

  search_results_mouseout: (evt) ->
    this.result_clear_highlight() if $(evt.target).hasClass "active-result" or $(evt.target).parents('.active-result').first()

  scope_build: (item) ->
    this.choice_build item
    this.result_narrow item
    
  choice_build: (item) ->
    choice = $('<li />', { class: "search-choice" }).html("<span>#{item.html}</span>")

    if item.disabled
      choice.addClass 'search-choice-disabled'
    else
      close_link = $('<a />', { class: 'search-choice-close', 'data-option-array-index': item.array_index })
      close_link.bind 'click.chosen', (evt) => this.choice_destroy_link_click(evt)
      choice.append close_link

    if item.is_scope
      choice.addClass 'is-scope'
      choice_arrow = $('<div><i /></div>')
      choice.append(choice_arrow)

    @search_container.before choice

  choice_destroy_link_click: (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    this.choice_destroy $(evt.target) unless @is_disabled

  choice_destroy: (link) ->
    array_index = link[0].getAttribute("data-option-array-index")
    item = @source.get_item(array_index)
    
    deselected = if item.is_scope then this.result_expand(item) else this.result_deselect(array_index)
    
    if deselected
      this.show_search_field_default()

      this.results_hide() if @is_multiple and this.choices_count() > 0 and @search_field.val().length < 1
      
      this.winnow_results() if item.is_scope

      link.parents('li').first().remove()
      
      this.search_field_scale()

  results_reset: ->
    this.reset_single_select_options()
    @form_field.options[0].selected = true
    this.single_set_selected_text()
    this.show_search_field_default()
    this.results_reset_cleanup()
    @form_field_jq.trigger "change"
    this.results_hide() if @active_field

  results_reset_cleanup: ->
    @current_selectedIndex = @form_field.selectedIndex
    @selected_item.find("abbr").remove()

  result_select: (evt) ->
    if @result_highlight
      high = @result_highlight

      this.result_clear_highlight()

      if @is_multiple and @max_selected_options <= this.choices_count()
        @form_field_jq.trigger("chosen:maxselected", {chosen: this})
        return false

      if @is_multiple
        high.removeClass("active-result")
      else
        this.reset_single_select_options()

      item = @source.get_item(high[0].getAttribute("data-option-array-index"))
      
      # Don't actually select anything if this is a refinement
      if item.is_scope
        this.scope_build item
      else
        item.selected = true

        @source.get_option_element(item.array_index).selected = true
        @selected_option_count = null

        if @is_multiple
          this.choice_build item
        else
          this.single_set_selected_text(item.text)
        
      @search_field.val ""
      this.search_field_scale()
      
      if item.is_scope
        @search_field.focus()

        this.result_clear_highlight()
        # Search for refinement
        this.winnow_results() if @results_showing
      else
        this.results_hide() unless (evt.metaKey or evt.ctrlKey) and @is_multiple

        @form_field_jq.trigger "change", {'selected': item.value} if @is_multiple || @form_field.selectedIndex != @current_selectedIndex
        @current_selectedIndex = @form_field.selectedIndex

  single_set_selected_text: (text=@default_text) ->
    if text is @default_text
      @selected_item.addClass("chosen-default")
    else
      this.single_deselect_control_build()
      @selected_item.removeClass("chosen-default")

    # Building the results scope will initialize @scopes
    this.result_scopes_build()

    if @options.show_scope_of_selected_item
      html = '<ul class="chosen-scopes">'
      for v in @scopes_of_selection
        html += '<li class="is-scope">'
        html += v.html  + '<div><i></i></div>'
        html += '</li>'
      html += '<li>' + this.escape_html(text) + '</li>'
      html += '</ul>'
      @selected_item.find("span").html(html)
    else
      @selected_item.find("span").text(text)

    this.search_field_scale()

  result_narrow: (item) ->
    @scopes.push(item.value)
  
  result_expand: (item) ->
    for v, i in @scopes by -1
      if v == item.value
        @scopes = @scopes.slice(0, i)
        return true
    return false

  result_clear_scope: ->
    @scopes = []
    @search_container.siblings("li.is-scope").remove()
    
  result_scopes_build: ->
    this.result_clear_scope()
    if not @is_multiple
      # @scopes_of_selection: This is the scopes of the current selection.
      # @scopes: This is the current search scope
      # Note that the scopes of the current selection may contain parents that are no
      # longer scopes. This is not true for the current search scope.
      @scopes_of_selection = []
      v = @source.get_item_by_value(@form_field_jq.val())
      while v? and v.in_scope? and (v = @source.get_item_by_value(v.in_scope))?
        @scopes_of_selection.push(v)
      @scopes_of_selection.reverse()

      # Set the current search scope up to the first non-scope
      for v in @scopes_of_selection
        break if !v.is_scope
        this.scope_build v

  result_deselect: (array_index) ->
    option = @source.get_option_element(array_index)

    if not option.disabled
      option_value = option.value

      @source.get_item(array_index).selected = false

      option.selected = false
      @selected_option_count = null

      this.result_clear_highlight()
      this.winnow_results() if @results_showing

      @form_field_jq.trigger "change", {deselected: option_value}
      this.search_field_scale()

      return true
    else
      return false

  single_deselect_control_build: ->
    return unless @allow_single_deselect
    @selected_item.find("span").first().after "<abbr class=\"search-choice-close\"></abbr>" unless @selected_item.find("abbr").length
    @selected_item.addClass("chosen-single-with-deselect")

  get_search_text: ->
    if @search_field.val() is @default_text then "" else $.trim(@search_field.val())

  escape_html: (text) ->
    $('<div/>').text(text).html()

  get_selected_items: ->
    val = @form_field_jq.val()
    if not @is_multiple
      val = if val == '' || val == null
        []
      else
        [ val ]

    if val?
      (@source.get_item_by_value(v) for v in val)
    else
      []

  winnow_results_set_highlight: ->

    selected_results = if not @is_multiple then @search_results.find(".result-selected.active-result") else []
    do_high = if selected_results.length then selected_results.first() else @search_results.find(".active-result").first()

    this.result_do_highlight do_high if do_high?

  no_results: (terms) ->
    no_results_html = $('<li class="no-results">' + this.escape_html(@results_none_found) + ' "<span></span>"</li>')
    no_results_html.find("span").first().html(this.escape_html(terms))

    @search_results.append no_results_html

  no_results_clear: ->
    @search_results.find(".no-results").remove()

  keydown_arrow: ->
    if @results_showing and @result_highlight
      next_sib = @result_highlight.nextAll("li.active-result").first()
      this.result_do_highlight next_sib if next_sib
    else
      this.results_show()

  keyup_arrow: ->
    if not @results_showing and not @is_multiple
      this.results_show()
    else if @result_highlight
      prev_sibs = @result_highlight.prevAll("li.active-result")

      if prev_sibs.length
        this.result_do_highlight prev_sibs.first()
      else
        this.results_hide() if this.choices_count() > 0
        this.result_clear_highlight()

  keydown_backstroke: ->
    if @pending_backstroke
      this.choice_destroy @pending_backstroke.find("a").first()
      this.clear_backstroke()
    else
      next_available_destroy = @search_container.siblings("li.search-choice").last()
      if next_available_destroy.length and not next_available_destroy.hasClass("search-choice-disabled")
        @pending_backstroke = next_available_destroy
        if @single_backstroke_delete
          @keydown_backstroke()
        else
          @pending_backstroke.addClass "search-choice-focus"

  clear_backstroke: ->
    @pending_backstroke.removeClass "search-choice-focus" if @pending_backstroke
    @pending_backstroke = null

  keydown_checker: (evt) ->
    stroke = evt.which ? evt.keyCode
    this.search_field_scale()

    this.clear_backstroke() if stroke != 8 and this.pending_backstroke

    switch stroke
      when 8
        @backstroke_length = this.search_field.val().length
        break
      when 9
        this.result_select(evt) if this.results_showing and not @is_multiple
        @mouse_on_container = false
        break
      when 13
        evt.preventDefault()
        break
      when 38
        evt.preventDefault()
        this.keyup_arrow()
        break
      when 40
        evt.preventDefault()
        this.keydown_arrow()
        break

  search_field_scale: ->
    if true #@is_multiple
      # Check if we need to re-calculate
      search_field_val = @search_field.val()
      w = if @last_seach_field_val != search_field_val
        # Calculate required width of the input box
        style_block = "position:absolute; left: -1000px; top: -1000px; display:none;"
        styles = ['font-size','font-style', 'font-weight', 'font-family','line-height', 'text-transform', 'letter-spacing']

        for style in styles
          style_block += style + ":" + @search_field.css(style) + ";"

        div = $('<div />', { 'style' : style_block })
        div.text search_field_val
        $('body').append div

        w = div.width() + 25
        div.remove()

        @last_seach_field_width = w
        @last_seach_field_val = search_field_val
      w = @last_seach_field_width

      # Calculate width of the search input box
      if @search_scroller
        # tw is width of all scopes
        tw = 0
        @search_field.parent().siblings().each () ->
          tw += $(this).outerWidth(true);

        # Calculate min/max
        inner_width = @search_scroller.innerWidth()
        min_width = inner_width - tw
        max_width = inner_width

        w = min_width if(min_width && w < min_width)
        w = max_width if(max_width && w > max_width)

        # Scroll to the right
        left = tw + w - inner_width
        @search_scroller.scrollLeft(left)

        # Use non-truncated input both width for overflow calculation
        overflowing = tw + @last_seach_field_width > inner_width
        this.overflowing(overflowing)
      else
        # Multiple select does not have search scope scrolling
        max_width = @container.outerWidth() - 10
        w = max_width if(w > max_width)

      # We subtract the padding. box-sizing model was not used because of IE7 support
      @search_field.width(w - 8)
      @update_position()

  loading: (loading) ->
    return @is_loading if not loading? or @is_loading == loading

    if loading
      @containers.addClass('chosen-loading')
    else
      @containers.removeClass('chosen-loading')

    @is_loading = loading

  overflowing: (overflowing) ->
    return @is_overflowing if not overflowing? or @is_overflowing == overflowing

    if overflowing
      @containers.addClass('chosen-overflowing')
    else
      @containers.removeClass('chosen-overflowing')

    @is_overflowing = overflowing

  search_value: (value) ->
    input_field = @dropdown.find('.search-field input:first')

    return input_field.val(value) if value?
    input_field.val()
