VimCommandModeInputView = require './vim-command-mode-input-view'
{Point, Range} = require 'atom'
_ = require 'underscore-plus'

# Public: Base class for all view models; a view model
#         is the model attached to a VimCommandModeInputView
#         which is used when a given operator, motion, etc
#         needs extra keystroke.
#
# Ivars:
#
#   @completionCommand - if set will automatically be triggered on the editorView
#                        when the `confirm` method is called on the view model
#
#   @value - automatically set to the value of typed into the `VimCommandModeInputView`
#            when the `confirm` method is called
#
class ViewModel
  # Public: Override this in subclasses for custom initialization
  #
  # operator - An operator, motion, prefix, etc with `@editorView` and `@state` set
  #
  # opts - the options to be passed to `VimCommandModeInputView`
  #
  constructor: (@operator, opts = {}) ->
    @editorView        = @operator.editorView
    @vimState          = @operator.state

    @view = new VimCommandModeInputView(@, opts)
    @editorView.editor.commandModeInputView = @view

  # Public: Override this in subclasses for custom behavior when the `VimCommandModeInputView`
  #         has called `confirm`, optionally call super to get the default behavior of setting
  #         `@value` and triggering `@completionCommand`, if set
  #
  # view - the `VimCommandModeInputView` that called this method
  #
  confirm: (view) ->
    @value = @view.value
    @editorView.trigger(@completionCommand) if @completionCommand?

class ReplaceViewModel extends ViewModel
  constructor: (@replaceOperator) ->
    super(@replaceOperator, class: 'replace', hidden: true, singleChar: true)
    @completionCommand = 'vim-mode:replace-complete'


class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    super(@searchMotion, class: 'search')
    @completionCommand = 'vim-mode:search-complete'
    @historyIndex = -1
    @editor = @searchMotion.editor

    @view.editor.on('core:move-up', @increaseHistorySearch)
    @view.editor.on('core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editor.setText(@history(index).value)

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
    super(view)
    @vimState.pushSearchHistory(@)

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
    term = @value
    regexp =
      try
        new RegExp(term, 'g')
      catch
        new RegExp(_.escapeRegExp(term), 'g')

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

class MarkViewModel extends ViewModel
  constructor: (@markOperator) ->
    super(@markOperator, class: 'mark', hidden: true, singleChar: true)
    @completionCommand = 'vim-mode:mark-complete'

class MoveToMarkViewModel extends ViewModel
  constructor: (@moveToMarkOperator) ->
    super(@moveToMarkOperator, class: 'move-to-mark', hidden: true, singleChar: true)
    @editor = @moveToMarkOperator.editor
    @completionCommand = 'vim-mode:move-to-mark-complete'

  select: (requireEOL) ->
    markPosition = @vimState.getMark(@value)
    currentPosition = @editor.getCursorBufferPosition()
    selectionRange = null
    if currentPosition.isGreaterThan(markPosition)
      if @moveToMarkOperator.linewise
        currentPosition = @editor.clipBufferPosition([currentPosition.row, Infinity])
        markPosition = new Point(markPosition.row, 0)
      selectionRange = new Range(markPosition, currentPosition)
    else
      if @moveToMarkOperator.linewise
        markPosition = @editor.clipBufferPosition([markPosition.row, Infinity])
        currentPosition = new Point(currentPosition.row, 0)
      selectionRange = new Range(currentPosition, markPosition)
    @editor.setSelectedBufferRange(selectionRange, requireEOL: requireEOL)

  execute: ->
    markPosition = @vimState.getMark(@value)
    @editor.setCursorBufferPosition(markPosition) if markPosition?

module.exports = { ReplaceViewModel, SearchViewModel, MarkViewModel, MoveToMarkViewModel }
