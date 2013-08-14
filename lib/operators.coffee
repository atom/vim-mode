_ = require 'underscore'

class OperatorError
  constructor: (@message) ->
    @name = "Operator Error"

#
# It deletes everything selected by the following motion.
#
class Delete
  motion: null
  complete: null
  vimState: null
  allowEOL: null
  selectOptions: null

  constructor: (@editor, @vimState, {@motion, @allowEOL, @selectOptions}={}) ->
    @complete = false

  isComplete: -> @complete

  # Public: Deletes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    cursor = @editor.getCursor()
    buffer = @editor.getBuffer()

    buffer.transact =>
      _.times count, =>
        if _.last(@motion.select(1, @selectOptions))
          @editor.getSelection().delete()

        @editor.moveCursorLeft() if !@allowEOL and cursor.isAtEndOfLine() and !@motion.isLinewise?()

      if @motion.isLinewise?()
        @editor.setCursorScreenPosition([cursor.getScreenRow(), 0])

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to delete.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Delete must compose with a motion")

    @motion = motion
    @complete = true

#
# It changes everything selected by the following motion.
#
class Change
  motion: null
  complete: null
  vimState: null

  constructor: (@editor, @vimState) ->
    @complete = false

  isComplete: -> @complete

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    operator = new Delete(@editor, @vimState,
      motion: @motion, allowEOL: true, selectOptions: {excludeWhitespace: true})
    operator.execute(count)

    @vimState.activateInsertMode()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to change.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Change must compose with a motion")

    @motion = motion
    @complete = true

#
# It copies everything selected by the following motion.
#
class Yank
  motion: null
  complete: null
  register: null
  vimState: null

  constructor: (@editor, @vimState) ->
    @complete = false
    @register ?= '"'

  isComplete: -> @complete

  # Public: Copies the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    text = ""
    type = if @motion.isLinewise then 'linewise' else 'character'

    originalPosition = @editor.getCursorScreenPosition()
    _.times count, =>
      if _.last(@motion.select())
        text += @editor.getSelection().getText()

    @vimState.setRegister(@register, {text, type})

    if @motion.isLinewise?()
      @editor.setCursorScreenPosition(originalPosition)
    else
      @editor.clearSelections()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to copy.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Yank must compose with a motion")

    @motion = motion
    @complete = true

#
# It indents everything selected by the following motion.
#
class Indent
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    row = @editor.getCursorScreenRow()

    @motion.select(count)
    @editor.indentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to indent.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Indent must compose with a motion")

    @motion = motion
    @complete = true

#
# It outdents everything selected by the following motion.
#
class Outdent
  motion: null
  complete: null

  constructor: (@editor) ->
    @complete = false

  isComplete: -> @complete

  # Public: Outdents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    row = @editor.getCursorScreenRow()

    @motion.select(count)
    @editor.outdentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

  # Public: Marks this as complete and saves the motion.
  #
  # motion - The motion used to select what to outdent.
  #
  # Returns nothing.
  compose: (motion) ->
    if not motion.select
      throw new OperatorError("Outdent must compose with a motion")

    @motion = motion
    @complete = true

#
# It pastes everything contained within the specifed register
#
class Put
  motion: null
  direction: null
  register: null

  constructor: (@editor, @vimState, {@location}={}) ->
    @direction ?= 'after'
    @register ?= '"'

  isComplete: -> true

  # Public: Pastes the text in the given register.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    {text, type} = @vimState.getRegister(@register) || {}
    return unless text
    buffer = @editor.getBuffer()

    buffer.transact =>
      _.times count, =>
        if type == 'linewise' and @location == 'after'
          @editor.moveCursorDown()
        else if @location == 'after'
          @editor.moveCursorRight()

        @editor.moveCursorToBeginningOfLine() if type == 'linewise'
        @editor.insertText(text)

        if type == 'linewise'
          @editor.moveCursorUp()
          @editor.moveCursorToFirstCharacterOfLine()

  # Public: Not implemented.
  #
  # Returns nothing.
  compose: (register) ->
    throw new OperatorError("Not Implemented")

#
# It combines the current line with the following line.
#
class Join
  constructor: (@editor) ->

  isComplete: -> true

  # Public: Combines the current with the following lines
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    buffer = @editor.getBuffer()

    buffer.transact =>
      _.times count, =>
        @editor.joinLine()

  # Public: Not implemented.
  #
  # Returns nothing.
  compose: (register) ->
    throw new OperatorError("Not Implemented")

module.exports = { OperatorError, Delete, Yank, Put, Join, Indent, Outdent, Change }
