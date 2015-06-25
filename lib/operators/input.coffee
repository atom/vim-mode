{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'
settings = require '../settings'

# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class Insert extends Operator
  standalone: true

  isComplete: -> @standalone or super

  confirmChanges: (changes) ->
    bundler = new TransactionBundler(changes, @editor)
    @typedText = bundler.buildInsertText()

  execute: ->
    if @typingCompleted
      return unless @typedText? and @typedText.length > 0
      @editor.insertText(@typedText, normalizeLineEndings: true)
      for cursor in @editor.getCursors()
        cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    else
      @vimState.activateInsertMode()
      @typingCompleted = true
    return

  inputOperator: -> true

class InsertAfter extends Insert
  execute: ->
    @editor.moveRight() unless @editor.getLastCursor().isAtEndOfLine()
    super

class InsertAfterEndOfLine extends Insert
  execute: ->
    @editor.moveToEndOfLine()
    super

class InsertAtBeginningOfLine extends Insert
  execute: ->
    @editor.moveToBeginningOfLine()
    @editor.moveToFirstCharacterOfLine()
    super

class InsertAboveWithNewline extends Insert
  execute: (count=1) ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    @editor.insertNewlineAbove()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

class InsertBelowWithNewline extends Insert
  execute: (count=1) ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    @editor.insertNewlineBelow()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

#
# Delete the following motion and enter insert mode to replace it.
#
class Change extends Insert
  standalone: false
  register: null

  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @register = settings.defaultRegister()

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count) ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @vimState.setInsertionCheckpoint() unless @typingCompleted

    if _.contains(@motion.select(count, excludeWhitespace: true), true)
      @setTextRegister(@register, @editor.getSelectedText())
      if @motion.isLinewise?()
        @editor.insertNewline()
        @editor.moveLeft()
      else
        for selection in @editor.getSelections()
          selection.deleteSelectedText()

    return super if @typingCompleted

    @vimState.activateInsertMode()
    @typingCompleted = true

class Substitute extends Insert
  register: null

  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @register = settings.defaultRegister()

  execute: (count=1) ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    _.times count, =>
      @editor.selectRight()
    @setTextRegister(@register, @editor.getSelectedText())
    @editor.delete()

    if @typingCompleted
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

class SubstituteLine extends Insert
  register: null

  constructor: (@editor, @vimState, {@selectOptions}={}) ->
    @register = settings.defaultRegister()

  execute: (count=1) ->
    @vimState.setInsertionCheckpoint() unless @typingCompleted
    @editor.moveToBeginningOfLine()
    _.times count, =>
      @editor.selectToEndOfLine()
      @editor.selectRight()
    @setTextRegister(@register, @editor.getSelectedText())
    @editor.delete()
    @editor.insertNewlineAbove()
    @editor.getLastCursor().skipLeadingWhitespace()

    if @typingCompleted
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode()
    @typingCompleted = true

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of Insert
class TransactionBundler
  constructor: (@changes, @editor) ->
    @start = null
    @end = null

  buildInsertText: ->
    @addChange(change) for change in @changes
    if @start?
      @editor.getTextInBufferRange [@start, @end]
    else
      ""

  addChange: (change) ->
    return unless change.newRange?
    if @isRemovingFromPrevious(change)
      @subtractRange change.oldRange
    if @isAddingWithinPrevious(change)
      @addRange change.newRange

  isAddingWithinPrevious: (change) ->
    return false unless @isAdding(change)

    return true if @start is null

    @start.isLessThanOrEqual(change.newRange.start) and
      @end.isGreaterThanOrEqual(change.newRange.start)

  isRemovingFromPrevious: (change) ->
    return false unless @isRemoving(change) and @start?

    @start.isLessThanOrEqual(change.oldRange.start) and
      @end.isGreaterThanOrEqual(change.oldRange.end)

  isAdding: (change) ->
    change.newText.length > 0

  isRemoving: (change) ->
    change.oldText.length > 0

  addRange: (range) ->
    if @start is null
      {@start, @end} = range
      return

    rows = range.end.row - range.start.row

    if (range.start.row is @end.row)
      cols = range.end.column - range.start.column
    else
      cols = 0

    @end = @end.translate [rows, cols]

  subtractRange: (range) ->
    rows = range.end.row - range.start.row

    if (range.end.row is @end.row)
      cols = range.end.column - range.start.column
    else
      cols = 0

    @end = @end.translate [-rows, -cols]


module.exports = {
  Insert,
  InsertAfter,
  InsertAfterEndOfLine,
  InsertAtBeginningOfLine,
  InsertAboveWithNewline,
  InsertBelowWithNewline,
  Change,
  Substitute,
  SubstituteLine
}
