{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'

# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class Insert extends Operator
  standalone: true

  isComplete: -> @standalone || super

  confirmTransaction: (transaction) ->
    bundler = new TransactionBundler(transaction)
    @typedText = bundler.buildInsertText()

  execute: ->
    if @typingCompleted
      return unless @typedText? and @typedText.length > 0
      @undoTransaction =>
        @editor.getBuffer().insert(@editor.getCursorBufferPosition(), @typedText, true)
    else
      @vimState.activateInsertMode()
      @typingCompleted = true

  inputOperator: -> true

class InsertAfter extends Insert
  execute: ->
    @editor.moveCursorRight() unless @editor.getCursor().isAtEndOfLine()
    super

class InsertAboveWithNewline extends Insert
  execute: (count=1) ->
    @editor.beginTransaction() unless @typingCompleted
    @editor.insertNewlineAbove()
    @editor.getCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode(transactionStarted = true)
    @typingCompleted = true

class InsertBelowWithNewline extends Insert
  execute: (count=1) ->
    @editor.beginTransaction() unless @typingCompleted
    @editor.insertNewlineBelow()
    @editor.getCursor().skipLeadingWhitespace()

    if @typingCompleted
      # We'll have captured the inserted newline, but we want to do that
      # over again by hand, or differing indentations will be wrong.
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode(transactionStarted = true)
    @typingCompleted = true

#
# Delete the following motion and enter insert mode to replace it.
#
class Change extends Insert
  standalone: false

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @editor.beginTransaction() unless @typingCompleted
    operator = new Delete(@editor, @vimState, allowEOL: true, selectOptions: {excludeWhitespace: true})
    operator.compose(@motion)

    lastRow = @onLastRow()
    onlyRow = @editor.getBuffer().getLineCount() is 1
    operator.execute(count)
    if @motion.isLinewise?() and not onlyRow
      if lastRow
        @editor.insertNewlineBelow()
      else
        @editor.insertNewlineAbove()

    return super if @typingCompleted

    @vimState.activateInsertMode(transactionStarted = true)
    @typingCompleted = true

  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row is @editor.getBuffer().getLastRow()

class Substitute extends Insert
  execute: (count=1) ->
    @editor.beginTransaction() unless @typingCompleted
    _.times count, =>
      @editor.selectRight()
    @editor.delete()

    if @typingCompleted
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode(transactionStarated = true)
    @typingCompleted = true

class SubstituteLine extends Insert
  execute: (count=1) ->
    @editor.beginTransaction() unless @typingCompleted
    @editor.moveCursorToBeginningOfLine()
    _.times count, =>
      @editor.selectDown()
    @editor.delete()
    @editor.insertNewlineAbove()
    @editor.getCursor().skipLeadingWhitespace()

    if @typingCompleted
      @typedText = @typedText.trimLeft()
      return super

    @vimState.activateInsertMode(transactionStarated = true)
    @typingCompleted = true

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of Insert
class TransactionBundler
  constructor: (@transaction) ->

  buildInsertText: ->
    return "" unless @transaction.patches
    chars = []
    for patch in @transaction.patches
      switch
        when @isTypedChar(patch) then chars.push(@isTypedChar(patch))
        when @isBackspacedChar(patch) then chars.pop()
    chars.join("")

  isTypedChar: (patch) ->
    # Technically speaking, a typed char will be of length 1, but >= 1
    # happens to let us test with editor.setText, so we'll look the other way.
    return false unless patch.newText?.length >= 1 and patch.oldText?.length == 0
    patch.newText

  isBackspacedChar: (patch) ->
    patch.newText == "" and patch.oldText?.length == 1

module.exports = {
  Insert,
  InsertAfter,
  InsertAboveWithNewline,
  InsertBelowWithNewline,
  Change,
  Substitute,
  SubstituteLine
}
