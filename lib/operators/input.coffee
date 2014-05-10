{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'

# The operation for text entered in input mode. This operator is not
# used as the user types, but is created when the user leaves insert mode,
# and is available for repeating with the . operator (Replace)
#
# Currently, limitations with Transaction (from the text-buffer package)
# prevent us from doing anything reasonable with text input if it is
# anything but straight-up typed characters. No backspacing. It won't match
# vim when using the substitution command. You'll regret using this code.
# Never use this code.
#
class Input extends Operator
  constructor: (@editor, @vimState, @transaction) ->
    @confirmTransaction(@transaction)

  confirmTransaction: (transaction) ->
    bundler = new TransactionBundler(transaction)
    @typedText = bundler.buildInsertText()

  execute: ->
    return undefined unless @typedText
    @undoTransaction =>
      @editor.getBuffer().insert(@editor.getCursorBufferPosition(), @typedText, true)

  inputOperator: -> true

#
# It changes everything selected by the following motion.
#
class Change extends Input
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
    operator.execute(count)
    # if we already have typed text, we've already been executed.
    return super if @typed

    @vimState.activateInsertMode(transactionStarted = true)
    @typed = true

# Takes a transaction and turns it into a string of what was typed.
class TransactionBundler
  constructor: (@transaction) ->

  buildInsertText: ->
    return undefined unless @isJustTyping()
    typedCharacters = (patch.newText for patch in @transaction.patches)
    typedCharacters.join("")

  isJustTyping: ->
    return undefined unless @transaction
    return true # required for subclasses like Change
    window.trans = @transaction
    typedSingleChars = (patch.oldText == "" && patch.newText != "" for patch in @transaction.patches)
    _.every(typedSingleChars)

module.exports = {Input, Change}
