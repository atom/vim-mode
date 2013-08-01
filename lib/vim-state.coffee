$ = require 'jquery'
_ = require 'underscore'

operators = require './operators'
commands = require './commands'
motions = require './motions'

module.exports =
class VimState
  editor: null
  opStack: null
  mode: null

  constructor: (@editor) ->
    @opStack = []
    @mode = 'command'
    @activateCommandMode()
    @setupCommandMode()

  setupCommandMode: ->
    @editor.preempt 'textInput', (e) =>
      if @mode == 'insert'
        true
      else
        @resetCommandMode()
        false

    @handleCommands
      'activate-command-mode': => @activateCommandMode()
      'reset-command-mode': => @resetCommandMode()
      'insert': => @activateInsertMode()
      'delete': => @delete()
      'delete-right': => new commands.DeleteRight(@editor)
      'move-left': => new motions.MoveLeft(@editor)
      'move-up': => new motions.MoveUp(@editor)
      'move-down': => new motions.MoveDown @editor
      'move-right': => new motions.MoveRight @editor
      'move-to-next-word': => new motions.MoveToNextWord(@editor)
      'move-to-previous-word': => new motions.MoveToPreviousWord(@editor)
      'move-to-next-paragraph': => new motions.MoveToNextParagraph(@editor)
      'numeric-prefix': (e) => @numericPrefix(e)

  handleCommands: (commands) ->
    _.each commands, (fn, commandName) =>
      eventName = "vim-mode:#{commandName}"
      @editor.command eventName, (e) =>
        possibleOperator = fn(e)
        @pushOperator(possibleOperator) if possibleOperator?.execute

  activateInsertMode: ->
    @mode = 'insert'
    @editor.removeClass('command-mode')
    @editor.addClass('insert-mode')

    @editor.off 'cursor:position-changed', @moveCursorBeforeNewline

  activateCommandMode: ->
    @mode = 'command'
    @editor.removeClass('insert-mode')
    @editor.addClass('command-mode')

    @editor.on 'cursor:position-changed', @moveCursorBeforeNewline

  resetCommandMode: ->
    @opStack = []

  moveCursorBeforeNewline: =>
    if not @editor.getSelection().modifyingSelection and @editor.cursor.isOnEOL() and @editor.getCurrentBufferLine().length > 0
      @editor.setCursorBufferColumn(@editor.getCurrentBufferLine().length - 1)

  numericPrefix: (e) ->
    num = parseInt(e.keyEvent.keystrokes)
    if @topOperator() instanceof operators.NumericPrefix
      @topOperator().addDigit(num)
    else
      @pushOperator(new operators.NumericPrefix(num))

  delete: () ->
    if deleteOperation = @isDeletePending()
      deleteOperation.complete = true
      @processOpStack()
    else
      @pushOperator(new operators.Delete(@editor))

  isDeletePending: () ->
    for op in @opStack
      return op if op instanceof operators.Delete
    false

  pushOperator: (op) ->
    @opStack.push(op)
    @processOpStack()

  processOpStack: ->
    return unless @topOperator().isComplete()

    poppedOperator = @opStack.pop()
    if @opStack.length
      try
        @topOperator().compose(poppedOperator)
        @processOpStack()
      catch e
        (e instanceof operators.OperatorError) and @resetCommandMode() or throw e
    else
      poppedOperator.execute()

  topOperator: ->
    _.last @opStack
