_ = require 'underscore-plus'
{$} = require 'atom'

operators = require './operators'
prefixes = require './prefixes'
commands = require './commands'
motions = require './motions'
textObjects = require './text-objects'
utils = require './utils'
panes = require './panes'
scroll = require './scroll'

module.exports =
class VimState
  editor: null
  # The opStack is a stack of operations that are being executed. Think of it as
  # an internal representation of something like "3dw"
  opStack: null
  mode: null
  submode: null

  constructor: (@editorView) ->
    @editor = @editorView.editor
    @opStack = []
    @history = []
    @mode = 'command'

    @setupCommandMode()
    @registerInsertIntercept()
    @activateCommandMode()

    atom.project.eachBuffer (buffer) =>
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
    @editorView.preempt 'textInput', (e) =>
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
        @setRegister('"', text: oldText, type: utils.copyType(oldText))

  # Private: Creates the plugin's commands
  #
  # Returns nothing.
  setupCommandMode: ->
    # Commands here start a new mode instead of popping the operator stack
    # immediately.
    @editorView.command 'vim-mode:search', =>
      @currentSearch = new motions.Search(@editorView, @)
    @editorView.command 'vim-mode:reverse-search', =>
      @currentSearch = new motions.Search(@editorView, @)
      @currentSearch.reversed()

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
      'insert-at-bol': => [new motions.MoveToFirstCharacterOfLine(@editor), new commands.Insert(@editor, @)]
      'insert-above-with-newline': => new commands.InsertAboveWithNewline(@editor, @)
      'insert-below-with-newline': => new commands.InsertBelowWithNewline(@editor, @)
      'change-to-last-character-of-line': => [new operators.Change(@editor, @), new motions.MoveToLastCharacterOfLine(@editor)]
      'delete-right': => [new operators.Delete(@editor), new motions.MoveRight(@editor)]
      'delete-left': => [new operators.Delete(@editor), new motions.MoveLeft(@editor)]
      'delete-to-last-character-of-line': => [new operators.Delete(@editor), new motions.MoveToLastCharacterOfLine(@editor)]
      'yank-line': => [new operators.Yank(@editor, @), new motions.MoveToLine(@editor)]
      'put-before': => new operators.Put(@editor, @, location: 'before')
      'put-after': => new operators.Put(@editor, @, location: 'after')
      'join': => new operators.Join(@editor)
      'select-left': => new motions.SelectLeft(@editor)
      'select-right': => new motions.SelectRight(@editor)
      'move-left': => new motions.MoveLeft(@editor)
      'move-up': => new motions.MoveUp(@editor)
      'move-down': => new motions.MoveDown(@editor)
      'move-right': => new motions.MoveRight(@editor)
      'move-to-next-word': => new motions.MoveToNextWord(@editor)
      'move-to-next-whole-word': => new motions.MoveToNextWholeWord(@editor)
      'move-to-end-of-word': => new motions.MoveToEndOfWord(@editor)
      'move-to-previous-word': => new motions.MoveToPreviousWord(@editor)
      'move-to-previous-whole-word': => new motions.MoveToPreviousWholeWord(@editor)
      'move-to-next-paragraph': => new motions.MoveToNextParagraph(@editor)
      'move-to-previous-paragraph': => new motions.MoveToPreviousParagraph(@editor)
      'move-to-first-character-of-line': => new motions.MoveToFirstCharacterOfLine(@editor)
      'move-to-last-character-of-line': => new motions.MoveToLastCharacterOfLine(@editor)
      'move-to-beginning-of-line': (e) => @moveOrRepeat(e)
      'move-to-start-of-file': => new motions.MoveToStartOfFile(@editor)
      'move-to-line': => new motions.MoveToLine(@editor)
      'move-to-top-of-screen': => new motions.MoveToTopOfScreen(@editor, @editorView)
      'move-to-bottom-of-screen': => new motions.MoveToBottomOfScreen(@editor, @editorView)
      'move-to-middle-of-screen': => new motions.MoveToMiddleOfScreen(@editor, @editorView)
      'scroll-down': => new scroll.ScrollDown(@editorView, @editor)
      'scroll-up': => new scroll.ScrollUp(@editorView, @editor)
      'register-prefix': (e) => @registerPrefix(e)
      'repeat-prefix': (e) => @repeatPrefix(e)
      'repeat': (e) => new operators.Repeat(@editor, @)
      'search-complete': (e) => @currentSearch
      'repeat-search': (e) => @currentSearch.repeat() if @currentSearch?
      'repeat-search-backwards': (e) => @currentSearch.repeat(backwards: true) if @currentSearch?
      'focus-pane-view-on-left': => new panes.FocusPaneViewOnLeft()
      'focus-pane-view-on-right': => new panes.FocusPaneViewOnRight()
      'focus-pane-view-above': => new panes.FocusPaneViewAbove()
      'focus-pane-view-below': => new panes.FocusPaneViewBelow()
      'focus-previous-pane-view': => new panes.FocusPreviousPaneView()
      'delete': => @operatorPending(operators.Delete)
      'change': => @operatorPending(operators.Change)
      'yank': => @operatorPending(operators.Yank)
      'indent': => @operatorPending(operators.Indent)
      'outdent': => @operatorPending(operators.Outdent)
      'inner-word': => new textObjects.InnerWord(@editor)

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
      @editorView.command eventName, (e) =>
        operations = fn(e)
        operations = if _.isArray(operations) then operations else [operations]
        for operation in operations
          # Motions in visual mode perform their selections.
          if @mode == 'visual' and operation instanceof motions.Motion
            operation.origExecute = operation.execute
            operation.execute = operation.select

          @pushOperation(operation) if operation?.execute

          # If we've received an operation in visual mode, mark the current
          # selection as the motion to operate on.
          if @mode == 'visual' and operation instanceof operators.Operator
            @pushOperation(new motions.CurrentSelection(@))
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

  # Private: Adds an operation to the operation stack.
  #
  # operation - The operation to add.
  #
  # Returns nothing.
  pushOperation: (operation) ->
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
    return unless @topOperation().isComplete()

    poppedOperation = @opStack.pop()
    if @opStack.length
      try
        @topOperation().compose(poppedOperation)
        @processOpStack()
      catch e
        (e instanceof operators.OperatorError) and @resetCommandMode() or throw e
    else
      @history.unshift(poppedOperation) if poppedOperation.isRecordable()
      poppedOperation.execute()

  # Private: Fetches the last operation.
  #
  # Returns the last operation.
  topOperation: ->
    _.last @opStack

  # Private: Fetches the value of a given register.
  #
  # name - The name of the register to fetch.
  #
  # Returns the value of the given register or undefined if it hasn't
  # been set.
  getRegister: (name) ->
    if name == '*'
      text = atom.clipboard.read()
      type = utils.copyType(text)
      {text, type}
    else
      atom.workspace.vimState.registers[name]

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to.
  #
  # Returns nothing.
  setRegister: (name, value) ->
    if name == '*'
      atom.clipboard.write(value.text)
    else
      atom.workspace.vimState.registers[name] = value

  # Public: Append a search to the search history.
  #
  # motions.Search - The confirmed search motion to append
  #
  # Returns nothing
  pushSearchHistory: (search) ->
    atom.workspace.vimState.searchHistory.unshift search

  # Public: Get the search history item at the given index.
  #
  # index - the index of the search history item
  #
  # Returns a search motion
  getSearchHistoryItem: (index) ->
    atom.workspace.vimState.searchHistory[index]

  ##############################################################################
  # Commands
  ##############################################################################

  # Private: Used to enable command mode.
  #
  # Returns nothing.
  activateCommandMode: ->
    @mode = 'command'
    @submode = null

    if @editorView.is(".insert-mode")
      cursor = @editor.getCursor()
      cursor.moveLeft() unless cursor.isAtBeginningOfLine()

    @editorView.removeClass('insert-mode visual-mode operator-pending-mode')
    @editorView.addClass('command-mode')
    @editor.clearSelections()

    @editorView.on 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: ->
    @mode = 'insert'
    @submode = null
    @editorView.removeClass('command-mode visual-mode operator-pending-mode')
    @editorView.addClass('insert-mode')

    @editorView.off 'cursor:position-changed', @moveCursorBeforeNewline

  # Private: Used to enable visual mode.
  #
  # type - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (type) ->
    @mode = 'visual'
    @submode = type
    @editorView.removeClass('command-mode insert-mode operator-pending-mode')
    @editorView.addClass('visual-mode')
    @editor.off 'cursor:position-changed', @moveCursorBeforeNewline

    if @submode == 'linewise'
      @editor.selectLine()

  # Private: Used to enable operator pending mode.
  #
  # Returns nothing.
  activateOperatorPendingMode: ->
    @mode = 'operator-pending'
    @submode = null
    @editorView.removeClass('command-mode insert-mode visual-mode')
    @editorView.addClass('operator-pending-mode')

    @editorView.off 'cursor:position-changed', @moveCursorBeforeNewline

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
    name = atom.keymap.keystrokeStringForEvent(e.originalEvent)
    @pushOperation(new prefixes.Register(name))

  # Private: A generic way to create a Number prefix based on the event.
  #
  # e - The event that triggered the Number prefix.
  #
  # Returns nothing.
  repeatPrefix: (e) ->
    num = parseInt(atom.keymap.keystrokeStringForEvent(e.originalEvent))
    if @topOperation() instanceof prefixes.Repeat
      @topOperation().addDigit(num)
    else
      @pushOperation(new prefixes.Repeat(num))

  # Private: Figure out whether or not we are in a repeat sequence or we just
  # want to move to the beginning of the line. If we are within a repeat
  # sequence, we pass control over to @repeatPrefix.
  #
  # e - The triggered event.
  #
  # Returns nothing.
  moveOrRepeat: (e) ->
    if @topOperation() instanceof prefixes.Repeat
      @repeatPrefix(e)
    else
      new motions.MoveToBeginningOfLine(@editor)

  # Private: Put us into operator pending mode with the given operator.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  operatorPending: (constructor) ->
    if @isOperationPending(constructor)
      new motions.MoveToLine(@editor)
    else
      new constructor(@editor, @)

  # Private: Check if there is a pending operation of a certain type
  #
  # constructor - The constructor of the object type you're looking for.
  #
  # Returns nothing.
  isOperationPending: (constructor) ->
    for op in @opStack
      return op if op instanceof constructor
    false
