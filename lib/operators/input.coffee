{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'

# The operation for text entered in input mode. This operator is not
# used as the user types, but is created when the user leaves insert mode,
# and is available for repeating with the . operator (Replace)
#
class Input extends Operator
  standalone: true

  isComplete: -> @standalone || super

  confirmTransaction: (transaction) ->
    bundler = new TransactionBundler(transaction)
    @typedText = bundler.buildInsertText()

  execute: ->
    if @typed
      @undoTransaction =>
        @editor.getBuffer().insert(@editor.getCursorBufferPosition(), @typedText, true)
    else
      @vimState.activateInsertMode()
      @typed = true

  inputOperator: -> true

#
# Delete the following motion and enter insert mode to replace it.
#
class Change extends Input
  standalone: false

  # Public: Changes the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    # If we've typed, we're being repeated. If we're being repeated,
    # undo transactions are already handled.
    @editor.beginTransaction() unless @typed
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

    return super if @typed

    @vimState.activateInsertMode(transactionStarted = true)
    @typed = true

  onLastRow: ->
    {row, column} = @editor.getCursorBufferPosition()
    row is @editor.getBuffer().getLastRow()

# Takes a transaction and turns it into a string of what was typed.
class TransactionBundler
  constructor: (@transaction) ->

  buildInsertText: ->
    chars = []
    for patch in @transaction.patches
      switch
        when @isTypedChar(patch) then chars.push(@isTypedChar(patch))
        when @isBackspacedChar(patch) then chars.pop()
    chars.join("")

  isTypedChar: (patch) ->
    return false unless patch.newText?.length >= 1 and patch.oldText?.length == 0
    patch.newText

  isBackspacedChar: (patch) ->
    patch.newText == "" and patch.oldText?.length == 1

module.exports = {Input, Change}
