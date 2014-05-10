{Operator} = require './general-operators'
_ = require 'underscore-plus'

module.exports =
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
    bundler = new TransactionBundler(@transaction)
    @typedText = bundler.buildInsertText()

  # 'Executes' this input operation. Input operations are synthetic; typing
  # is done natively in insert mode. So we just insert the typed text.
  # But first, if the operator above us in the history enters input mode,
  # such as `cw`, repeat that operation too.
  execute: ->
    return undefined unless @typedText
    @undoTransaction =>
      @editor.getBuffer().insert(@editor.getCursorBufferPosition(), @typedText, true)

  composesWithRepeat: true

# Takes a transaction and turns it into a string of what was typed.
class TransactionBundler
  constructor: (@transaction) ->

  buildInsertText: ->
    console.log "building inserted text, just typing: #{@justTyping} trans #{@transaction}"
    return undefined unless @isJustTyping()
    typedCharacters = (patch.newText for patch in @transaction.patches)
    typedCharacters.join("")

  isJustTyping: ->
    return undefined unless @transaction
    window.trans = @transaction
    console.log "set window.trans"
    typedSingleChars = (patch.oldText == "" && patch.newText != "" for patch in @transaction.patches)
    _.every(typedSingleChars)
