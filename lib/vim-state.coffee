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
  registers: null

  constructor: (@editor) ->
    @opStack = []
    @registers = {}
    @mode = 'command'

    @setupCommandMode()
    @registerInsertIntercept()
    @activateCommandMode()

  # Private: Creates a handle to block insertion while in command mode.
  #
  # This is currently a bit of a hack. If a user is in command mode they
  # won't be able to type in any of Atom's dialogs (such as the command
  # palette). This also doesn't block non-printable characters such as
  # backspace.
  #
  # There should probably be a better API on the editor to handle this
  # but the requirements aren't clear yet, so this will have to suffice
  # for now.
  #
  # Returns nothing.
  registerInsertIntercept: ->
    @editor.preempt 'textInput', (e) =>
      return if $(e.currentTarget).hasClass('mini')

      if @mode == 'insert'
        true
      else
        @clearOpStack()
        false

  # Private: Creates the plugin's commands
  #
  # Returns nothing.
  setupCommandMode: ->
    @handleCommands
      'activate-command-mode': => @activateCommandMode()
      'reset-command-mode': => @resetCommandMode()
      'insert': => new commands.Insert(@editor, @)
      'insert-after': => new commands.InsertAfter(@editor, @)
      'insert-above-with-newline': => new commands.InsertAboveWithNewline(@editor, @)
      'insert-below-with-newline': => new commands.InsertBelowWithNewline(@editor, @)
      'delete': => @linewiseAliasedOperator(operators.Delete)
      'change': => new operators.Change(@editor, @)
      'delete-right': => [new operators.Delete(@editor), new motions.MoveRight(@editor)]
      'delete-to-last-character-of-line': => [new operators.Delete(@editor), new motions.MoveToLastCharacterOfLine(@editor)]
      'yank': => @linewiseAliasedOperator(operators.Yank)
      'put-before': => new operators.Put(@editor, @, location: 'before')
      'put-after': => new operators.Put(@editor, @, location: 'after')
      'join': => new operators.Join(@editor)
      'indent': => @linewiseAliasedOperator(operators.Indent)
      'outdent': => @linewiseAliasedOperator(operators.Outdent)
      'move-left': => new motions.MoveLeft(@editor)
      'move-up': => new motions.MoveUp(@editor)
      'move-down': => new motions.MoveDown @editor
      'move-right': => new motions.MoveRight @editor
      'move-to-next-word': => new motions.MoveToNextWord(@editor)
      'move-to-previous-word': => new motions.MoveToPreviousWord(@editor)
      'move-to-next-paragraph': => new motions.MoveToNextParagraph(@editor)
      'move-to-first-character-of-line': => new motions.MoveToFirstCharacterOfLine(@editor)
      'move-to-last-character-of-line': => new motions.MoveToLastCharacterOfLine(@editor)
      'move-to-beginning-of-line': => new motions.MoveToBeginningOfLine(@editor)
      'register-prefix': (e) => @registerPrefix(e)
      'numeric-prefix': (e) => @numericPrefix(e)

  # Private: A helper to actually register the given commands with the
  # editor.
  #
  # commands - An object whose keys will be registered within the plugin's
  #            namespace and whose values are functions that returns the
  #            operation to push onto the stack or nothing at all.
  #
  # Returns nothing.
  handleCommands: (commands) ->
    _.each commands, (fn, commandName) =>
      eventName = "vim-mode:#{commandName}"
      @editor.command eventName, (e) =>
        possibleOperators = fn(e)
        possibleOperators = if _.isArray(possibleOperators) then possibleOperators else [possibleOperators]
        for possibleOperator in possibleOperators
          @pushOperator(possibleOperator) if possibleOperator?.execute

  # Private: Attempts to prevent the cursor from selecting the newline
  # while in command mode.
  #
  # FIXME: This doesn't work.
  #
  # Returns nothing.
  moveCursorBeforeNewline: =>
    if not @editor.getSelection().modifyingSelection and @editor.cursor.isOnEOL() and @editor.getCurrentBufferLine().length > 0
      @editor.setCursorBufferColumn(@editor.getCurrentBufferLine().length - 1)

  # Private: Adds an operator to the operation stack.
  #
  # operation - The operation to add.
  #
  # Returns nothing.
  pushOperator: (operation) ->
    @opStack.push(operation)
    @processOpStack()

  # Private: Removes all operations from the stack.
  #
  # Returns nothing.
  clearOpStack: ->
    @opStack = []

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
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

  # Private: Fetches the last operation.
  #
  # Returns the last operation.
  topOperator: ->
    _.last @opStack

  # Private: Fetches the value of a given register.
  #
  # name - The name of the register to fetch.
  #
  # Returns the value of the given register or undefined if it hasn't
  # been set.
  getRegister: (name) ->
    @registers[name]

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to.
  #
  # Returns nothing.
  setRegister: (name, value) ->
    @registers[name] = value

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: ->
    @mode = 'insert'
    @editor.removeClass('command-mode')
    @editor.addClass('insert-mode')

    @editor.off 'cursor:position-changed', @moveCursorBeforeNewline

  ##############################################################################
  # Commands
  ##############################################################################

  # Private: Used to enable command mode.
  #
  # Returns nothing.
  activateCommandMode: ->
    @mode = 'command'
    @editor.removeClass('insert-mode')
    @editor.addClass('command-mode')

    @editor.on 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Resets the command mode back to it's initial state.
  #
  # Returns nothing.
  resetCommandMode: ->
    @clearOpStack()

  # Private: A generic way to create RegisterPrefix operations based on the event.
  #
  # e - The event that triggered the RegisterPrefix operation.
  #
  # Returns nothing.
  registerPrefix: (e) ->
    name = e.keyEvent.keystrokes.split(' ')[1]
    @pushOperator(new operators.RegisterPrefix(name))

  # Private: A generic way to create NumberPrefix operations based on the event.
  #
  # e - The event that triggered the NumberPrefix operation.
  #
  # Returns nothing.
  numericPrefix: (e) ->
    num = parseInt(e.keyEvent.keystrokes)
    if @topOperator() instanceof operators.NumericPrefix
      @topOperator().addDigit(num)
    else
      @pushOperator(new operators.NumericPrefix(num))

  # Private: A generic way to handle operators that can be repeated for
  # their linewise form.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  linewiseAliasedOperator: (constructor) ->
    if @isOperatorPending(constructor)
      op = new motions.MoveToLine(@editor)
    else
      op = new constructor(@editor, @)

    @pushOperator(op)

  # Private: Check if there is a pending operation of a certain type
  #
  # constructor - The constructor of the object type you're looking for.
  #
  # Returns nothing.
  isOperatorPending: (constructor) ->
    for op in @opStack
      return op if op instanceof constructor
    false
