$ = require 'jquery'
_ = require 'underscore'

operators = require './operators'
prefixes = require './prefixes'
commands = require './commands'
motions = require './motions'

module.exports =
class VimState
  editor: null
  opStack: null
  mode: null
  submode: null
  registers: null

  constructor: (@editor) ->
    @opStack = []
    @registers = {}
    @mode = 'command'

    @setupCommandMode()
    @registerInsertIntercept()
    @activateCommandMode()

    project.eachBuffer (buffer) =>
      @registerChangeHandler(buffer)

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

  # Private: Watches for any deletes on the current buffer and places it in the
  # last deleted buffer.
  #
  # Returns nothing.
  registerChangeHandler: (buffer) ->
    buffer.on 'changed', ({newRange, newText, oldRange, oldText}) =>
      return unless @setRegister?

      if newText == ''
        type = if oldText.lastIndexOf("\n") == oldText.length - 1 then 'linewise' else 'character'
        @setRegister('"', text: oldText, type: type)

  # Private: Creates the plugin's commands
  #
  # Returns nothing.
  setupCommandMode: ->
    @handleCommands
      'activate-command-mode': => @activateCommandMode()
      'activate-insert-mode': => @activateInsertMode()
      'activate-linewise-visual-mode': => @activateVisualMode('linewise')
      'activate-characterwise-visual-mode': => @activateVisualMode('characterwise')
      'activate-blockwise-visual-mode': => @activateVisualMode('blockwise')
      'reset-command-mode': => @resetCommandMode()
      'substitute': => new commands.Substitute(@editor, @)
      'substitute-line': => new commands.SubstituteLine(@editor, @)
      'insert-after': => new commands.InsertAfter(@editor, @)
      'insert-after-eol': => [new motions.MoveToLastCharacterOfLine(@editor), new commands.InsertAfter(@editor, @)]
      'insert-above-with-newline': => new commands.InsertAboveWithNewline(@editor, @)
      'insert-below-with-newline': => new commands.InsertBelowWithNewline(@editor, @)
      'delete': => @linewiseAliasedOperator(operators.Delete)
      'change': => @linewiseAliasedOperator(operators.Change)
      'change-to-last-character-of-line': => [new operators.Change(@editor, @), new motions.MoveToLastCharacterOfLine(@editor)]
      'delete-right': => [new operators.Delete(@editor), new motions.MoveRight(@editor)]
      'delete-to-last-character-of-line': => [new operators.Delete(@editor), new motions.MoveToLastCharacterOfLine(@editor)]
      'yank': => @linewiseAliasedOperator(operators.Yank)
      'yank-line': => [new operators.Yank(@editor, @), new motions.MoveToLine(@editor)]
      'put-before': => new operators.Put(@editor, @, location: 'before')
      'put-after': => new operators.Put(@editor, @, location: 'after')
      'join': => new operators.Join(@editor)
      'indent': => @linewiseAliasedOperator(operators.Indent)
      'outdent': => @linewiseAliasedOperator(operators.Outdent)
      'select-left': => new motions.SelectLeft(@editor)
      'select-right': => new motions.SelectRight(@editor)
      'move-left': => new motions.MoveLeft(@editor)
      'move-up': => new motions.MoveUp(@editor)
      'move-down': => new motions.MoveDown(@editor)
      'move-right': => new motions.MoveRight(@editor)
      'move-to-next-word': => new motions.MoveToNextWord(@editor)
      'move-to-end-of-word': => new motions.MoveToEndOfWord(@editor)
      'move-to-previous-word': => new motions.MoveToPreviousWord(@editor)
      'move-to-next-paragraph': => new motions.MoveToNextParagraph(@editor)
      'move-to-first-character-of-line': => new motions.MoveToFirstCharacterOfLine(@editor)
      'move-to-last-character-of-line': => new motions.MoveToLastCharacterOfLine(@editor)
      'move-to-beginning-of-line': => new motions.MoveToBeginningOfLine(@editor)
      'move-to-start-of-file': => new motions.MoveToStartOfFile(@editor)
      'move-to-line': => new motions.MoveToLine(@editor)
      'register-prefix': (e) => @registerPrefix(e)
      'repeat-prefix': (e) => @repeatPrefix(e)

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
          # Motions in visual mode perform their selections.
          if @mode == 'visual' and possibleOperator instanceof motions.Motion
            possibleOperator.origExecute = possibleOperator.execute
            possibleOperator.execute = possibleOperator.select

          @pushOperator(possibleOperator) if possibleOperator?.execute

          # If we've received an operator in visual mode, mark the current
          # selection as the motion to operate on.
          if @mode == 'visual' and possibleOperator instanceof operators.Operator
            @pushOperator(new motions.CurrentSelection(@))
            @activateCommandMode() if @mode == 'visual'

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

  ##############################################################################
  # Commands
  ##############################################################################

  # Private: Used to enable command mode.
  #
  # Returns nothing.
  activateCommandMode: ->
    @mode = 'command'
    @submode = null
    @editor.removeClass('insert-mode visual-mode')
    @editor.addClass('command-mode')

    @editor.on 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: ->
    @mode = 'insert'
    @submode = null
    @editor.removeClass('command-mode visual-mode')
    @editor.addClass('insert-mode')

    @editor.off 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Used to enable visual mode.
  #
  # type - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (type) ->
    @mode = 'visual'
    @submode = type
    @editor.removeClass('command-mode insert-mode')
    @editor.addClass('visual-mode')

    @editor.off 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Resets the command mode back to it's initial state.
  #
  # Returns nothing.
  resetCommandMode: ->
    @clearOpStack()

  # Private: A generic way to create a Register prefix based on the event.
  #
  # e - The event that triggered the Register prefix.
  #
  # Returns nothing.
  registerPrefix: (e) ->
    name = e.keyEvent.keystrokes.split(' ')[1]
    @pushOperator(new prefixes.Register(name))

  # Private: A generic way to create a Number prefix based on the event.
  #
  # e - The event that triggered the Number prefix.
  #
  # Returns nothing.
  repeatPrefix: (e) ->
    num = parseInt(e.keyEvent.keystrokes)
    if @topOperator() instanceof prefixes.Repeat
      @topOperator().addDigit(num)
    else
      @pushOperator(new prefixes.Repeat(num))

  # Private: A generic way to handle operators that can be repeated for
  # their linewise form.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  linewiseAliasedOperator: (constructor) ->
    if @isOperatorPending(constructor)
      new motions.MoveToLine(@editor)
    else
      new constructor(@editor, @)

  # Private: Check if there is a pending operation of a certain type
  #
  # constructor - The constructor of the object type you're looking for.
  #
  # Returns nothing.
  isOperatorPending: (constructor) ->
    for op in @opStack
      return op if op instanceof constructor
    false
