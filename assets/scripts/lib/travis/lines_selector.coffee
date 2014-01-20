class Travis.LinesSelector
  Location:
    getHash: ->
      window.location.hash

    setHash: (hash) ->
      path = "#{window.location.pathname}#{hash}"
      window.history.pushState({ path: path }, null, path);

  element: null
  scroll: null
  location: null
  last_selected_line: null

  constructor: (@element, @scroll, location) ->
    @location = location || (new @Location)
    Ember.run.scheduleOnce 'afterRender', this, ->
      @last_selected_line = @getSelectedLines()?.first
      @highlightLines()

    @element.on 'click', 'a', (event) =>
      element = $(event.target).parent('p')
      @loadLineNumbers(element, event.shiftKey)

      event.preventDefault()
      false

  willDestroy: ->
    @location.setHash('')

  loadLineNumbers: (element, multiple) ->
    @setHashValueWithLine(element, multiple)
    @highlightLines()

  highlightLines: ->
    @removeAllHighlights()

    if lines = @getSelectedLines()
      @element.find('p:visible').slice(lines.first - 1, lines.last).addClass('highlight')
    @scroll.tryScroll()

  setHashValueWithLine: (line, multiple) ->
    line_number = @getLineNumberFromElement(line)

    if multiple && @last_selected_line?
      lines = [line_number, @last_selected_line].sort (a,b) -> a - b
      hash = "#L#{lines[0]}-L#{lines[1]}"
    else
      hash = "#L#{line_number}"

    @last_selected_line = line_number
    @location.setHash(hash)

  getLineNumberFromElement: (element) ->
    @element.find('p:visible').index(element) + 1

  removeAllHighlights: ->
    @element.find('p.highlight').removeClass('highlight')

  getSelectedLines: ->
    if match = @location.getHash().match(/#L(\d+)(-L(\d+))?$/)
      first = match[1]
      last = match[3] || match[1]
      {first: first, last: last}
