_ = require 'underscore-plus'
{Point, Range} = require 'atom'
{ViewModel} = require '../view-models/view-model'
Utils = require '../utils'
settings = require '../settings'

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
    @vimState.setRegister(register, {text, type}) unless text is ''

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
  register: null
  allowEOL: null

  # allowEOL - Determines whether the cursor should be allowed to rest on the
  #            end of line character or not.
  constructor: (@editor, @vimState, {@allowEOL, @selectOptions}={}) ->
    @complete = false
    @selectOptions ?= {}
    @selectOptions.requireEOL ?= true
    @register = settings.defaultRegister()

  # Public: Deletes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count) ->
    if _.contains(@motion.select(count, @selectOptions), true)
      @setTextRegister(@register, @editor.getSelectedText())
      for selection in @editor.getSelections()
        selection.deleteSelectedText()
      for cursor in @editor.getCursors()
        if @motion.isLinewise?()
          cursor.skipLeadingWhitespace()
        else
          cursor.moveLeft() if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()

    @vimState.activateCommandMode()

#
# It toggles the case of everything selected by the following motion
#
class ToggleCase extends Operator
  constructor: (@editor, @vimState, {@complete, @selectOptions}={}) ->

  execute: (count=1) ->
    if @motion?
      if _.contains(@motion.select(count, @selectOptions), true)
        @editor.replaceSelectedText {}, (text) ->
          text.split('').map((char) ->
            lower = char.toLowerCase()
            if char is lower
              char.toUpperCase()
            else
              lower
          ).join('')
    else
      @editor.transact =>
        for cursor in @editor.getCursors()
          point = cursor.getBufferPosition()
          lineLength = @editor.lineTextForBufferRow(point.row).length
          cursorCount = Math.min(count, lineLength - point.column)

          _.times cursorCount, =>
            point = cursor.getBufferPosition()
            range = Range.fromPointWithDelta(point, 0, 1)
            char = @editor.getTextInBufferRange(range)

            if char is char.toLowerCase()
              @editor.setTextInBufferRange(range, char.toUpperCase())
            else
              @editor.setTextInBufferRange(range, char.toLowerCase())

            cursor.moveRight() unless point.column >= lineLength - 1

    @vimState.activateCommandMode()

#
# In visual mode or after `g` with a motion, it makes the selection uppercase
#
class UpperCase extends Operator
  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @complete = false

  execute: (count=1) ->
    if _.contains(@motion.select(count, @selectOptions), true)
      @editor.replaceSelectedText {}, (text) ->
        text.toUpperCase()

    @vimState.activateCommandMode()

#
# In visual mode or after `g` with a motion, it makes the selection lowercase
#
class LowerCase extends Operator
  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @complete = false

  execute: (count=1) ->
    if _.contains(@motion.select(count, @selectOptions), true)
      @editor.replaceSelectedText {}, (text) ->
        text.toLowerCase()

    @vimState.activateCommandMode()

#
# It copies everything selected by the following motion.
#
class Yank extends Operator
  register: null

  constructor: (@editor, @vimState, {@allowEOL, @selectOptions}={}) ->
    @register = settings.defaultRegister()

  # Public: Copies the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count) ->
    originalPositions = @editor.getCursorBufferPositions()
    if _.contains(@motion.select(count), true)
      text = @editor.getSelectedText()
      startPositions = _.pluck(@editor.getSelectedBufferRanges(), "start")
      newPositions = for originalPosition, i in originalPositions
        if startPositions[i] and (@vimState.mode is 'visual' or not @motion.isLinewise?())
          Point.min(startPositions[i], originalPositions[i])
        else
          originalPosition
    else
      text = ''
      newPositions = originalPositions

    @setTextRegister(@register, text)

    @editor.setSelectedBufferRanges(newPositions.map (p) -> new Range(p, p))
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
    @editor.transact =>
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
    @editor.transact =>
      _.times count, =>
        cmd = @vimState.history[0]
        cmd?.execute()
#
# It creates a mark at the current cursor position
#
class Mark extends OperatorWithInput
  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    super(@editor, @vimState)
    @viewModel = new ViewModel(this, class: 'mark', singleChar: true, hidden: true)

  # Public: Creates the mark in the specified mark register (from user input)
  # at the current position
  #
  # Returns nothing.
  execute: ->
    @vimState.setMark(@input.characters, @editor.getCursorBufferPosition())
    @vimState.activateCommandMode()

module.exports = {
  Operator, OperatorWithInput, OperatorError, Delete, ToggleCase,
  UpperCase, LowerCase, Yank, Join, Repeat, Mark
}
