{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'
settings = require '../settings'

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
        @editor.delete()

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
    text = @editor.getLastSelection().getText()
    @setTextRegister(@register, text)
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
    text = @editor.getLastSelection().getText()
    @setTextRegister(@register, text)
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
  constructor: (@transaction) ->
    @position = null
    @content = ""

  buildInsertText: ->
    @addPatch(patch) for patch in @transaction.patches ? []
    @content

  addPatch: (patch) ->
    return unless patch.newRange?
    if @isAppending(patch)
      @content += patch.newText
      @position = patch.newRange.end
    else if @isRemovingFromEnd(patch)
      @content = @content.substring(0, @content.length - patch.oldText.length)
      @position = patch.newRange.end

  isAppending: (patch) ->
    (patch.newText.length > 0) and
      (patch.oldText.length is 0) and
      ((not @position) or @position.isEqual(patch.newRange.start))

  isRemovingFromEnd: (patch) ->
    (patch.newText.length is 0) and
      (patch.oldText.length > 0) and
      (@position and @position?.isEqual(patch.oldRange.end))

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
