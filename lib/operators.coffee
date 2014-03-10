_ = require 'underscore-plus'
{$$, Range} = require 'atom'
ReplaceViewModel = require './replace-view-model'

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

  # Protected: Wraps the function within an single undo step.
  #
  # fn - The function to wrap.
  #
  # Returns nothing.
  undoTransaction: (fn) ->
    @editor.getBuffer().transact(fn)
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

#
# It changes everything selected by the following motion.
#
class Change extends Operator
  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    operator = new Delete(@editor, @vimState, allowEOL: true, selectOptions: {excludeWhitespace: true})
    operator.compose(@motion)
    operator.execute(count)

    @vimState.activateInsertMode()

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
      text = @editor.getSelection().getText()
    else
      text = ''
    type = if @motion.isLinewise?() then 'linewise' else 'character'

    @vimState.setRegister(@register, {text, type})

    if @motion.isLinewise?()
      @editor.setCursorScreenPosition(originalPosition)
    else
      @editor.clearSelections()

#
# It indents everything selected by the following motion.
#
class Indent extends Operator
  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count)

  # Protected: Indents or outdents the text selected by the given motion.
  #
  # count  - The number of times to execute.
  # direction - Either 'indent' or 'outdent'
  #
  # Returns nothing.
  indent: (count, direction='indent') ->
    row = @editor.getCursorScreenRow()

    @motion.select(count)
    if direction == 'indent'
      @editor.indentSelectedRows()
    else if direction == 'outdent'
      @editor.outdentSelectedRows()
    else if direction == 'auto'
      @editor.autoIndentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

#
# It outdents everything selected by the following motion.
#
class Outdent extends Indent
  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count, 'outdent')

#
# It autoindents everything selected by the following motion.
#
class Autoindent extends Indent
  # Public: Autoindents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count, 'auto')

#
# It pastes everything contained within the specifed register
#
class Put extends Operator
  register: '"'

  constructor: (@editor, @vimState, {@location, @selectOptions}={}) ->
    @location ?= 'after'
    @complete = true

  # Public: Pastes the text in the given register.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    {text, type} = @vimState.getRegister(@register) || {}
    return unless text

    if @location == 'after'
      if type == 'linewise'
        if @onLastRow()
          @editor.moveCursorToEndOfLine()

          originalPosition = @editor.getCursorScreenPosition()
          originalPosition.row += 1
        else
          @editor.moveCursorDown()
      else
        unless @onLastColumn()
          @editor.moveCursorRight()

    if type == 'linewise' and !originalPosition?
      @editor.moveCursorToBeginningOfLine()
      originalPosition = @editor.getCursorScreenPosition()

    textToInsert = _.times(count, -> text).join('')
    if @location == 'after' and type == 'linewise' and @onLastRow()
      textToInsert = "\n#{textToInsert.substring(0, textToInsert.length - 1)}"
    @editor.insertText(textToInsert)

    if originalPosition?
      @editor.setCursorScreenPosition(originalPosition)
      @editor.moveCursorToFirstCharacterOfLine()

  # Private: Helper to determine if the editor is currently on the last row.
  #
  # Returns true on the last row and false otherwise.
  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row == @editor.getBuffer().getLastRow()

  onLastColumn: ->
    @editor.getCursor().isAtEndOfLine()
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
# Replace the character under the cursor
#
class Replace extends Operator
  constructor: (@editorView, @vimState, {@selectOptions}={}) ->
    @editor = @editorView.editor
    @complete = true
    @viewModel = new ReplaceViewModel(@)

  execute: (count=1) ->
    editor = @editorView.editor
    pos = editor.getCursorBufferPosition()
    currentRowLength = editor.lineLengthForBufferRow(pos.row)

    # Do nothing on an empty line
    return unless currentRowLength > 0
    # Do nothing if asked to replace more characters than there are on a line
    return unless currentRowLength - pos.column >= count

    @undoTransaction =>
      start = editor.getCursorBufferPosition()
      _.times count, =>
        point = editor.getCursorBufferPosition()
        editor.setTextInBufferRange(Range.fromPointWithDelta(point, 0, 1), @viewModel.char)
        editor.moveCursorRight()
      editor.setCursorBufferPosition(start)

module.exports = { Operator, OperatorError, Delete, Change, Yank, Indent,
  Outdent, Autoindent, Put, Join, Repeat, Replace }
