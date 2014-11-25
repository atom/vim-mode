_ = require 'underscore-plus'
{Point, Range} = require 'atom'
{ViewModel} = require '../view-models/view-model'
Utils = require '../utils'

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

    # Take on the composed object's isLinewise function if this object
    # doesn't have one.
    motion.isLinewise ?= motion.composedObject?.isLinewise

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

  # Public: Preps text and sets the text register
  #
  # Returns nothing
  setTextRegister: (register, text) ->
    if @motion?.isLinewise?()
      type = 'linewise'
      if text[-1..] isnt '\n'
        text += '\n'
    else
      type = Utils.copyType(text)
    @vimState.setRegister(register, {text, type})

# Public: Generic class for an operator that requires extra input
class OperatorWithInput extends Operator
  constructor: (@editor, @vimState) ->
    @editor = @editor
    @complete = false

  canComposeWith: (operation) -> operation.characters? or operation.select?

  compose: (operation) ->
    if operation.select?
      @motion = operation
    if operation.characters?
      @input = operation
      @complete = true

#
# It deletes everything selected by the following motion.
#
class Delete extends Operator
  register: '"'
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
  execute: (count) ->
    cursor = @editor.getLastCursor()

    if _.contains(@motion.select(count, @selectOptions), true)
      validSelection = true

    if validSelection?
      text = @editor.getSelectedText()
      @setTextRegister(@register, text)

      @editor.delete()
      if !@allowEOL and cursor.isAtEndOfLine() and !@motion.isLinewise?()
        @editor.moveLeft()

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
    lastCharIndex = @editor.lineTextForBufferRow(pos.row).length - 1
    count = Math.min count, @editor.lineTextForBufferRow(pos.row).length - pos.column

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
          @editor.moveRight()

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
  execute: (count) ->
    originalPosition = @editor.getCursorScreenPosition()
    if _.contains(@motion.select(count), true)
      selectedPosition = @editor.getCursorScreenPosition()
      text = @editor.getLastSelection().getText()
      originalPosition = Point.min(originalPosition, selectedPosition)
    else
      text = ''

    @setTextRegister(@register, text)

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
  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    super(@editor, @vimState)
    @viewModel = new ViewModel(@, class: 'mark', singleChar: true, hidden: true)

  # Public: Creates the mark in the specified mark register (from user input)
  # at the current position
  #
  # Returns nothing.
  execute: () ->
    @vimState.setMark(@input.characters, @editor.getCursorBufferPosition())
    @vimState.activateCommandMode()

module.exports = {
  Operator, OperatorWithInput, OperatorError, Delete, ToggleCase,
  Yank, Join, Repeat, Mark
}
