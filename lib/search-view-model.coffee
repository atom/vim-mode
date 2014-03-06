_ = require 'underscore-plus'
VimCommandModeInputView = require './vim-command-mode-input-view'

module.exports =

# This is the view model for a Search motion. It is an implementation
# detail of the same, and is tested via the use of the `/` keybinding
# in motions-spec.coffee.
class SearchViewModel
  constructor: (@searchMotion) ->
    @historyIndex = -1
    @editorView = @searchMotion.editorView
    @editor     = @searchMotion.editor
    @vimState   = @searchMotion.state

    @view = new VimCommandModeInputView(@, class: 'search')
    @editorView.editor.commandModeInputView = @view
    @view.editor.on('core:move-up', @increaseHistorySearch)
    @view.editor.on('core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editor.setText(@history(index).searchTerm)

  history: (index) ->
    @vimState.getSearchHistoryItem(index)

  increaseHistorySearch: =>
    if @history(@historyIndex + 1)?
      @historyIndex += 1
      @restoreHistory(@historyIndex)

  decreaseHistorySearch: =>
    if @historyIndex <= 0
      # get us back to a clean slate
      @historyIndex = -1
      @view.editor.setText('')
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  reversed: =>
    @initiallyReversed = @reverse = true

  confirm: (view) =>
    @searchTerm = view.value
    @vimState.pushSearchHistory(@)
    @editorView.trigger('vim-mode:search-complete')

  repeat: (opts) =>
    reverse = opts.backwards
    if @initiallyReversed and reverse
      @reverse = false
    else
      @reverse = reverse or @initiallyReversed

  execute: (count) =>
    @scan()
    @match count, (pos) =>
      @editor.setCursorBufferPosition(pos)

  select: (count) =>
    @scan()
    cur = @editor.getCursorBufferPosition()
    @match count, (pos) =>
      @editor.setSelectedBufferRange([cur, pos])
    [true]

  match: (count, callback) ->
    pos = @matches[(count - 1) % @matches.length]
    if pos?
      callback(pos)
    else
      atom.beep()

  scan: ->
    term = @searchTerm
    regexp = new RegExp(term, 'g')
    cur = @editor.getCursorBufferPosition()
    matchPoints = []
    iterator = (item) =>
      matchPoints.push(item.range.start)

    @editor.scan(regexp, iterator)

    previous = _.filter matchPoints, (point) =>
      if @reverse
        point.compare(cur) < 0
      else
        point.compare(cur) <= 0

    after = _.difference(matchPoints, previous)
    after.push(previous...)
    after = after.reverse() if @reverse

    @matches = after
