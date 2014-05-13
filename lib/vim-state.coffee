_ = require 'underscore-plus'
{$} = require 'atom'

Operators = require './operators/index'
Prefixes = require './prefixes'
Commands = require './commands'
Motions = require './motions/index'
TextObjects = require './text-objects'
Utils = require './utils'
Panes = require './panes'
Scroll = require './scroll'

module.exports =
class VimState
  editor: null
  opStack: null
  mode: null
  submode: null

  constructor: (@editorView) ->
    @editor = @editorView.editor
    @opStack = []
    @history = []
    @marks = {}

    @setupCommandMode()
    @registerInsertIntercept()
    if atom.config.get 'vim-mode.startInInsertMode'
      @activateInsertMode()
    else
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
        @setRegister('"', text: oldText, type: Utils.copyType(oldText))

  # Private: Creates the plugin's Commands
  #
  # Returns nothing.
  setupCommandMode: ->
    @registerCommands
      'activate-command-mode': => @activateCommandMode()
      'activate-insert-mode': => @activateInsertMode()
      'activate-linewise-visual-mode': => @activateVisualMode('linewise')
      'activate-characterwise-visual-mode': => @activateVisualMode('characterwise')
      'activate-blockwise-visual-mode': => @activateVisualMode('blockwise')
      'reset-command-mode': => @resetCommandMode()
      'repeat-prefix': (e) => @repeatPrefix(e)

    @registerOperationCommands
      'substitute': => new Commands.Substitute(@editor, @)
      'substitute-line': => new Commands.SubstituteLine(@editor, @)
      'insert-after': => new Commands.InsertAfter(@editor, @)
      'insert-after-end-of-line': => [new Motions.MoveToLastCharacterOfLine(@editor), new Commands.InsertAfter(@editor, @)]
      'insert-at-beginning-of-line': => [new Motions.MoveToFirstCharacterOfLine(@editor), new Commands.Insert(@editor, @)]
      'insert-above-with-newline': => new Commands.InsertAboveWithNewline(@editor, @)
      'insert-below-with-newline': => new Commands.InsertBelowWithNewline(@editor, @)
      'delete': => @linewiseAliasedOperator(Operators.Delete)
      'change': => @linewiseAliasedOperator(Operators.Change)
      'change-to-last-character-of-line': => [new Operators.Change(@editor, @), new Motions.MoveToLastCharacterOfLine(@editor)]
      'delete-right': => [new Operators.Delete(@editor, @), new Motions.MoveRight(@editor)]
      'delete-left': => [new Operators.Delete(@editor, @), new Motions.MoveLeft(@editor)]
      'delete-to-last-character-of-line': => [new Operators.Delete(@editor, @), new Motions.MoveToLastCharacterOfLine(@editor)]
      'toggle-case': => new Operators.ToggleCase(@editor, @)
      'yank': => @linewiseAliasedOperator(Operators.Yank)
      'yank-line': => [new Operators.Yank(@editor, @), new Motions.MoveToLine(@editor)]
      'put-before': => new Operators.Put(@editor, @, location: 'before')
      'put-after': => new Operators.Put(@editor, @, location: 'after')
      'join': => new Operators.Join(@editor, @)
      'indent': => @linewiseAliasedOperator(Operators.Indent)
      'outdent': => @linewiseAliasedOperator(Operators.Outdent)
      'auto-indent': => @linewiseAliasedOperator(Operators.Autoindent)
      'move-left': => new Motions.MoveLeft(@editor)
      'move-up': => new Motions.MoveUp(@editor)
      'move-down': => new Motions.MoveDown(@editor)
      'move-right': => new Motions.MoveRight(@editor)
      'move-to-next-word': => new Motions.MoveToNextWord(@editor)
      'move-to-next-whole-word': => new Motions.MoveToNextWholeWord(@editor)
      'move-to-end-of-word': => new Motions.MoveToEndOfWord(@editor)
      'move-to-end-of-whole-word': => new Motions.MoveToEndOfWholeWord(@editor)
      'move-to-previous-word': => new Motions.MoveToPreviousWord(@editor)
      'move-to-previous-whole-word': => new Motions.MoveToPreviousWholeWord(@editor)
      'move-to-next-paragraph': => new Motions.MoveToNextParagraph(@editor)
      'move-to-previous-paragraph': => new Motions.MoveToPreviousParagraph(@editor)
      'move-to-first-character-of-line': => new Motions.MoveToFirstCharacterOfLine(@editor)
      'move-to-last-character-of-line': => new Motions.MoveToLastCharacterOfLine(@editor)
      'move-to-beginning-of-line': (e) => @moveOrRepeat(e)
      'move-to-start-of-file': => new Motions.MoveToStartOfFile(@editor)
      'move-to-line': => new Motions.MoveToLine(@editor)
      'move-to-top-of-screen': => new Motions.MoveToTopOfScreen(@editor, @editorView)
      'move-to-bottom-of-screen': => new Motions.MoveToBottomOfScreen(@editor, @editorView)
      'move-to-middle-of-screen': => new Motions.MoveToMiddleOfScreen(@editor, @editorView)
      'scroll-down': => new Scroll.ScrollDown(@editorView, @editor)
      'scroll-up': => new Scroll.ScrollUp(@editorView, @editor)
      'select-inside-word': => new TextObjects.SelectInsideWord(@editor)
      'register-prefix': (e) => @registerPrefix(e)
      'repeat': (e) => new Operators.Repeat(@editor, @)
      'repeat-search': (e) => currentSearch.repeat() if (currentSearch = Motions.Search.currentSearch)?
      'repeat-search-backwards': (e) => currentSearch.repeat(backwards: true) if (currentSearch = Motions.Search.currentSearch)?
      'focus-pane-view-on-left': => new Panes.FocusPaneViewOnLeft()
      'focus-pane-view-on-right': => new Panes.FocusPaneViewOnRight()
      'focus-pane-view-above': => new Panes.FocusPaneViewAbove()
      'focus-pane-view-below': => new Panes.FocusPaneViewBelow()
      'focus-previous-pane-view': => new Panes.FocusPreviousPaneView()
      'move-to-mark': (e) => new Motions.MoveToMark(@editorView, @)
      'move-to-mark-literal': (e) => new Motions.MoveToMark(@editorView, @, false)
      'mark': (e) => new Operators.Mark(@editorView, @)
      'find': (e) => new Motions.Find(@editorView, @)
      'find-backwards': (e) => new Motions.Find(@editorView, @).reverse()
      'till': (e) => new Motions.Till(@editorView, @)
      'till-backwards': (e) => new Motions.Till(@editorView, @).reverse()
      'replace': (e) => new Operators.Replace(@editorView, @)
      'search': (e) => new Motions.Search(@editorView, @)
      'reverse-search': (e) => (new Motions.Search(@editorView, @)).reversed()
      'search-current-word': (e) => new Motions.SearchCurrentWord(@editorView, @)
      'reverse-search-current-word': (e) => (new Motions.SearchCurrentWord(@editorView, @)).reversed()

  # Private: Register multiple command handlers via an {Object} that maps
  # command names to command handler functions.
  #
  # Prefixes the given command names with 'vim-mode:' to reduce redundancy in
  # the provided object.
  registerCommands: (commands) ->
    for commandName, fn of commands
      do (fn) =>
        @editorView.command "vim-mode:#{commandName}.vim-mode", fn

  # Private: Register multiple operation-pushing Commands via an {Object} that
  # maps command names to functions that return operations to push.
  #
  # Prefixes the given command names with 'vim-mode:' to reduce redundancy in
  # the given object.
  registerOperationCommands: (operationCommands) ->
    commands = {}
    for commandName, operationFn of operationCommands
      do (operationFn) =>
        commands[commandName] = (event) => @pushOperations(operationFn(event))
    @registerCommands(commands)

  # Private: Push the given operations onto the operation stack, then process
  # it.
  pushOperations: (operations) ->
    return unless operations?
    operations = [operations] unless _.isArray(operations)

    for operation in operations
      # Motions in visual mode perform their selections.
      if @mode is 'visual' and (operation instanceof Motions.Motion or operation instanceof TextObjects.TextObject)
        operation.execute = operation.select

      # if we have started an operation that responds to canComposeWith check if it can compose
      # with the operation we're going to push onto the stack
      if (topOp = @topOperation())? and topOp.canComposeWith? and not topOp.canComposeWith(operation)
        @editorView.trigger 'vim-mode:compose-failure'
        @resetCommandMode()
        break

      @opStack.push(operation)

      # If we've received an operator in visual mode, mark the current
      # selection as the motion to operate on.
      if @mode is 'visual' and operation instanceof Operators.Operator
        @opStack.push(new Motions.CurrentSelection(@))

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
    unless @opStack.length > 0
      return

    unless @topOperation().isComplete()
      if @mode is 'command' and @topOperation() instanceof Operators.Operator
        @activateOperatorPendingMode()
      return

    poppedOperation = @opStack.pop()
    if @opStack.length
      try
        @topOperation().compose(poppedOperation)
        @processOpStack()
      catch e
        ((e instanceof Operators.OperatorError) or (e instanceof Motions.MotionError)) and @resetCommandMode() or throw e
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
    if name in ['*', '+']
      text = atom.clipboard.read()
      type = Utils.copyType(text)
      {text, type}
    else if name == '%'
      text = @editor.getUri()
      type = Utils.copyType(text)
      {text, type}
    else if name == "_" # Blackhole always returns nothing
      text = ''
      type = Utils.copyType(text)
      {text, type}
    else
      atom.workspace.vimState.registers[name]

  # Private: Fetches the value of a given mark.
  #
  # name - The name of the mark to fetch.
  #
  # Returns the value of the given mark or undefined if it hasn't
  # been set.
  getMark: (name) -> @marks[name]

  # Private: Sets the value of a given register.
  #
  # name  - The name of the register to fetch.
  # value - The value to set the register to.
  #
  # Returns nothing.
  setRegister: (name, value) ->
    if name in ['*', '+']
      atom.clipboard.write(value.text)
    else if name == '_'
      # Blackhole register, nothing to do
    else
      atom.workspace.vimState.registers[name] = value

  # Private: Sets the value of a given mark.
  #
  # name  - The name of the mark to fetch.
  # pos {Point} - The value to set the mark to.
  #
  # Returns nothing.
  setMark: (name, pos) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      @marks[name] = pos

  # Public: Append a search to the search history.
  #
  # Motions.Search - The confirmed search motion to append
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

    @changeModeClass('command-mode')

    @clearOpStack()
    @editor.clearSelections()

    @updateStatusBar()

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: ->
    @mode = 'insert'
    @submode = null
    @changeModeClass('insert-mode')

    @updateStatusBar()

  # Private: Used to enable visual mode.
  #
  # type - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (type) ->
    @mode = 'visual'
    @submode = type
    @changeModeClass('visual-mode')

    if @submode == 'linewise'
      @editor.selectLine()

    @updateStatusBar()

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @mode = 'operator-pending'
    @submodule = null
    @changeModeClass('operator-pending-mode')

    @updateStatusBar()

  changeModeClass: (targetMode) ->
    for mode in ['command-mode', 'insert-mode', 'visual-mode', 'operator-pending-mode']
      if mode is targetMode
        @editorView.addClass(mode)
      else
        @editorView.removeClass(mode)

  # Private: Resets the command mode back to it's initial state.
  #
  # Returns nothing.
  resetCommandMode: ->
    @activateCommandMode()

  # Private: A generic way to create a Register prefix based on the event.
  #
  # e - The event that triggered the Register prefix.
  #
  # Returns nothing.
  registerPrefix: (e) ->
    name = atom.keymap.keystrokeStringForEvent(e.originalEvent)
    new Prefixes.Register(name)

  # Private: A generic way to create a Number prefix based on the event.
  #
  # e - The event that triggered the Number prefix.
  #
  # Returns nothing.
  repeatPrefix: (e) ->
    num = parseInt(atom.keymap.keystrokeStringForEvent(e.originalEvent))
    if @topOperation() instanceof Prefixes.Repeat
      @topOperation().addDigit(num)
    else
      if num is 0
        e.abortKeyBinding()
      else
        @pushOperations(new Prefixes.Repeat(num))

  # Private: Figure out whether or not we are in a repeat sequence or we just
  # want to move to the beginning of the line. If we are within a repeat
  # sequence, we pass control over to @repeatPrefix.
  #
  # e - The triggered event.
  #
  # Returns new motion or nothing.
  moveOrRepeat: (e) ->
    if @topOperation() instanceof Prefixes.Repeat
      @repeatPrefix(e)
      null
    else
      new Motions.MoveToBeginningOfLine(@editor)

  # Private: A generic way to handle Operators that can be repeated for
  # their linewise form.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  linewiseAliasedOperator: (constructor) ->
    if @isOperatorPending(constructor)
      new Motions.MoveToLine(@editor)
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

  updateStatusBar: ->
    if !$('#status-bar-vim-mode').length
      atom.packages.once 'activated', ->
        atom.workspaceView.statusBar?.prependRight("<div id='status-bar-vim-mode' class='inline-block'>Command</div>")

    if @mode is "insert"
      $('#status-bar-vim-mode').html("Insert")
    else if @mode is "command"
      $('#status-bar-vim-mode').html("Command")
    else if @mode is "visual"
      $('#status-bar-vim-mode').html("Visual")
