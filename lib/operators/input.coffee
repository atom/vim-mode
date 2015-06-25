{Operator, Delete} = require './general-operators'
_ = require 'underscore-plus'
settings = require '../settings'

# The operation for text entered in input mode. Broadly speaking, input
# operators manage an undo transaction and set a @typingCompleted variable when
# it's done. When the input operation is completed, the typingCompleted variable
# tells the operation to repeat itself instead of enter insert mode.
class Insert extends Operator
  standalone: true
  count: 1

  isComplete: -> @standalone or super

  confirmChanges: (changes, insertionCheckpoint, options) ->
    interrupted = options?.interrupted
    bundler = new TransactionBundler(changes)
    @typedText = bundler.buildInsertText()
    if @count > 1 and not interrupted
      @editor.insertText(@typedText) for i in [2..@count]

  execute: (count) ->
    @count = count if count?
    if @typingCompleted
      return unless @typedText? and @typedText.length > 0
      @editor.transact =>
        @editor.insertText(@typedText, normalizeLineEndings: true) for i in [1..@count]
      for cursor in @editor.getCursors()
        cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    else
      @vimState.activateInsertMode()
      @typingCompleted = true
    return

  inputOperator: -> true

# an insert operation following cursor motion in insert mode can be cancelled
# and forgotten like it never happened
class InsertCancellable extends Insert

  confirmTransaction: (transaction) ->
    super
    if @typedText?.length is 0
      @vimState.history.shift() if @vimState.history[0] is this

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

    return super(1) if @typingCompleted

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
      return super(1)

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
      return super(1)

    @vimState.activateInsertMode()
    @typingCompleted = true

# Takes a transaction and turns it into a string of what was typed.
# This class is an implementation detail of Insert
class TransactionBundler
  constructor: (@changes) ->
    @position = null
    @content = ""

  buildInsertText: ->
    @addChange(change) for change in @changes
    @content

  addChange: (change) ->
    return unless change.newRange?
    if @isAppending(change)
      @content += change.newText
      @position = change.newRange.end
    else if @isRemovingFromEnd(change)
      @content = @content.substring(0, @content.length - change.oldText.length)
      @position = change.newRange.end

  isAppending: (change) ->
    (change.newText.length > 0) and
      (change.oldText.length is 0) and
      ((not @position) or @position.isEqual(change.newRange.start))

  isRemovingFromEnd: (change) ->
    (change.newText.length is 0) and
      (change.oldText.length > 0) and
      (@position and @position?.isEqual(change.oldRange.end))

module.exports = {
  Insert,
  InsertAfter,
  InsertAfterEndOfLine,
  InsertAtBeginningOfLine,
  InsertAboveWithNewline,
  InsertBelowWithNewline,
  InsertCancellable,
  Change,
  Substitute,
  SubstituteLine
}
