_ = require 'underscore-plus'
{$$, Point, Range} = require 'atom'
{ViewModel} = require '../view-models/view-model'

class OperatorError
  constructor: (@message) ->
    @name = 'Operator Error'

class Operator
  vimState: null
  motion: null
  complete: null
  selectOptions: null

  # selectOptions - The options object to pass through to the motion when
  #                 selecting.
  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @complete = false

  # Public: Determines when the command can be executed.
  #
  # Returns true if ready to execute and false otherwise.
  isComplete: -> @complete

  # Public: Determines if this command should be recorded in the command
  # history for repeats.
  #
  # Returns true if this command should be recorded.
  isRecordable: -> true

  # Public: Marks this as ready to execute and saves the motion.
  #
  # motion - The motion used to select what to operate on.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError('Must compose with a motion')

    @motion = motion
    @complete = true

  canComposeWith: (operation) -> operation.select?

  # Protected: Wraps the function within an single undo step.
  #
  # fn - The function to wrap.
  #
  # Returns nothing.
  undoTransaction: (fn) ->
    @editor.getBuffer().transact(fn)

# Public: Generic class for an operator that requires extra input
class OperatorWithInput extends Operator
  constructor: (@editorView, @vimState) ->
    @editor = @editorView.editor
    @complete = false

  canComposeWith: (operation) -> operation.characters?

  compose: (input) ->
    if not input.characters
      throw new OperatorError('Must compose with an Input')

    @input = input
    @complete = true

#
# It deletes everything selected by the following motion.
#
class Delete extends Operator
  allowEOL: null

  # allowEOL - Determines whether the cursor should be allowed to rest on the
  #            end of line character or not.
  constructor: (@editor, @vimState, {@allowEOL, @selectOptions}={}) ->
    @complete = false
    @selectOptions ?= {}
    @selectOptions.requireEOL ?= true

  # Public: Deletes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    cursor = @editor.getCursor()

    if _.contains(@motion.select(count, @selectOptions), true)
      validSelection = true

    if validSelection?
      @editor.delete()
      if !@allowEOL and cursor.isAtEndOfLine() and !@motion.isLinewise?()
        @editor.moveCursorLeft()

    if @motion.isLinewise?()
      @editor.setCursorScreenPosition([cursor.getScreenRow(), 0])

    @vimState.activateCommandMode()
#
# It toggles the case of everything selected by the following motion
#
class ToggleCase extends Operator

  constructor: (@editor, @vimState, {@selectOptions}={}) -> @complete = true

  execute: (count=1) ->
    pos = @editor.getCursorBufferPosition()
    lastCharIndex = @editor.lineLengthForBufferRow(pos.row) - 1
    count = Math.min count, @editor.lineLengthForBufferRow(pos.row) - pos.column

    # Do nothing on an empty line
    return if @editor.getBuffer().isRowBlank(pos.row)

    @undoTransaction =>
      _.times count, =>
        point = @editor.getCursorBufferPosition()
        range = Range.fromPointWithDelta(point, 0, 1)
        char = @editor.getTextInBufferRange(range)

        if char is char.toLowerCase()
          @editor.setTextInBufferRange(range, char.toUpperCase())
        else
          @editor.setTextInBufferRange(range, char.toLowerCase())

        unless point.column >= lastCharIndex
          @editor.moveCursorRight()

    @vimState.activateCommandMode()

#
# It copies everything selected by the following motion.
#
class Yank extends Operator
  register: '"'

  # Public: Copies the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    originalPosition = @editor.getCursorScreenPosition()
    if _.contains(@motion.select(count), true)
      selectedPosition = @editor.getCursorScreenPosition()
      text = @editor.getSelection().getText()
      originalPosition = Point.min(originalPosition, selectedPosition)
    else
      text = ''
    type = if @motion.isLinewise?() then 'linewise' else 'character'

    if @motion.isLinewise?() and text[-1..] isnt '\n'
      text += '\n'

    @vimState.setRegister(@register, {text, type})

    @editor.setCursorScreenPosition(originalPosition)
    @vimState.activateCommandMode()

#
# It combines the current line with the following line.
#
class Join extends Operator
  constructor: (@editor, @vimState, {@selectOptions}={}) -> @complete = true

  # Public: Combines the current with the following lines
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @undoTransaction =>
      _.times count, =>
        @editor.joinLines()
    @vimState.activateCommandMode()

#
# Repeat the last operation
#
class Repeat extends Operator
  constructor: (@editor, @vimState, {@selectOptions}={}) -> @complete = true

  isRecordable: -> false

  execute: (count=1) ->
    @undoTransaction =>
      _.times count, =>
        cmd = @vimState.history[0]
        cmd?.execute()
#
# It creates a mark at the current cursor position
#
class Mark extends OperatorWithInput
  constructor: (@editorView, @vimState, {@selectOptions}={}) ->
    super(@editorView, @vimState)
    @viewModel = new ViewModel(@, class: 'mark', singleChar: true, hidden: true)

  # Public: Creates the mark in the specified mark register (from user input)
  # at the current position
  #
  # Returns nothing.
  execute: () ->
    @vimState.setMark(@input.characters, @editorView.editor.getCursorBufferPosition())
    @vimState.activateCommandMode()

module.exports = {
  Operator, OperatorWithInput, OperatorError, Delete, ToggleCase,
  Yank, Join, Repeat, Mark
}
