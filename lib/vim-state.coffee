_ = require 'underscore-plus'
{$} = require 'atom'
{Disposable, CompositeDisposable} = require 'event-kit'

Operators = require './operators/index'
Prefixes = require './prefixes'
Motions = require './motions/index'

TextObjects = require './text-objects'
Utils = require './utils'
Panes = require './panes'
Scroll = require './scroll'
{$$, Point, Range} = require 'atom'
Marker = require 'atom'

module.exports =
class VimState
  editor: null
  opStack: null
  mode: null
  submode: null

  constructor: (@editorView) ->
    @subscriptions = new CompositeDisposable
    @editor = @editorView.editor
    @opStack = []
    @history = []
    @marks = {}
    @desiredCursorColumn = null
    params = {}
    params.manager = this;
    params.id = 0;

    @setupCommandMode()
    @registerUndoIntercept()
    if atom.config.get 'vim-mode.startInInsertMode'
      @activateInsertMode()
    else
      @activateCommandMode()

  destroy: ->
    @subscriptions.dispose()
    @deactivateInsertMode()
    @editorView.setInputEnabled(true)
    @editorView.removeClass("command-mode")
    @editorView.off('.vim-mode')

  # Private: Intercept undo in insert mode.
  #
  # Undo in insert mode will blow up the previous transaction, but not
  # put it into the redo stack anywhere correctly, as it hasn't been
  # completed. As a workaround, we exit insert mode first and then
  # bubble the event up
  registerUndoIntercept: ->
    preempt = @editorView.preempt 'core:undo', (e) =>
      return true unless @mode == 'insert'
      @activateCommandMode()
      return true
    @subscriptions.add(new Disposable -> preempt.off())

  # Private: Creates the plugin's bindings
  #
  # Returns nothing.
  setupCommandMode: ->
    @registerCommands
      'activate-command-mode': => @activateCommandMode()
      'activate-linewise-visual-mode': => @activateVisualMode('linewise')
      'activate-characterwise-visual-mode': => @activateVisualMode('characterwise')
      'activate-blockwise-visual-mode': => @activateVisualMode('blockwise')
      'reset-command-mode': => @resetCommandMode()
      'repeat-prefix': (e) => @repeatPrefix(e)

    @registerOperationCommands
      'activate-insert-mode': => new Operators.Insert(@editor, @)
      'substitute': => new Operators.Substitute(@editor, @)
      'substitute-line': => new Operators.SubstituteLine(@editor, @)
      'insert-after': => new Operators.InsertAfter(@editor, @)
      'insert-after-end-of-line': => [new Motions.MoveToLastCharacterOfLine(@editor, @), new Operators.InsertAfter(@editor, @)]
      'insert-at-beginning-of-line': => [new Motions.MoveToFirstCharacterOfLine(@editor, @), new Operators.Insert(@editor, @)]
      'insert-above-with-newline': => new Operators.InsertAboveWithNewline(@editor, @)
      'insert-below-with-newline': => new Operators.InsertBelowWithNewline(@editor, @)
      'delete': => @linewiseAliasedOperator(Operators.Delete)
      'change': => @linewiseAliasedOperator(Operators.Change)
      'change-to-last-character-of-line': => [new Operators.Change(@editor, @), new Motions.MoveToLastCharacterOfLine(@editor, @)]
      'delete-right': => [new Operators.Delete(@editor, @), new Motions.MoveRight(@editor, @)]
      'delete-left': => [new Operators.Delete(@editor, @), new Motions.MoveLeft(@editor, @)]
      'delete-to-last-character-of-line': => [new Operators.Delete(@editor, @), new Motions.MoveToLastCharacterOfLine(@editor, @)]
      'toggle-case': => new Operators.ToggleCase(@editor, @)
      'yank': => @linewiseAliasedOperator(Operators.Yank)
      'yank-line': => [new Operators.Yank(@editor, @), new Motions.MoveToRelativeLine(@editor, @)]
      'put-before': => new Operators.Put(@editor, @, location: 'before')
      'put-after': => new Operators.Put(@editor, @, location: 'after')
      'join': => new Operators.Join(@editor, @)
      'indent': => @linewiseAliasedOperator(Operators.Indent)
      'outdent': => @linewiseAliasedOperator(Operators.Outdent)
      'auto-indent': => @linewiseAliasedOperator(Operators.Autoindent)
      'move-left': => new Motions.MoveLeft(@editor, @)
      'move-up': => new Motions.MoveUp(@editor, @)
      'move-down': => new Motions.MoveDown(@editor, @)
      'move-right': => new Motions.MoveRight(@editor, @)
      'move-to-next-word': => new Motions.MoveToNextWord(@editor, @)
      'move-to-next-whole-word': => new Motions.MoveToNextWholeWord(@editor, @)
      'move-to-end-of-word': => new Motions.MoveToEndOfWord(@editor, @)
      'move-to-end-of-whole-word': => new Motions.MoveToEndOfWholeWord(@editor, @)
      'move-to-previous-word': => new Motions.MoveToPreviousWord(@editor, @)
      'move-to-previous-whole-word': => new Motions.MoveToPreviousWholeWord(@editor, @)
      'move-to-next-paragraph': => new Motions.MoveToNextParagraph(@editor, @)
      'move-to-previous-paragraph': => new Motions.MoveToPreviousParagraph(@editor, @)
      'move-to-first-character-of-line': => new Motions.MoveToFirstCharacterOfLine(@editor, @)
      'move-to-last-character-of-line': => new Motions.MoveToLastCharacterOfLine(@editor, @)
      'move-to-beginning-of-line': (e) => @moveOrRepeat(e)
      'move-to-first-character-of-line-up': => new Motions.MoveToFirstCharacterOfLineUp(@editor, @)
      'move-to-first-character-of-line-down': => new Motions.MoveToFirstCharacterOfLineDown(@editor, @)
      'move-to-start-of-file': => new Motions.MoveToStartOfFile(@editor, @)
      'move-to-line': => new Motions.MoveToLine(@editor, @)
      'move-to-top-of-screen': => new Motions.MoveToTopOfScreen(@editor, @, @editorView)
      'move-to-bottom-of-screen': => new Motions.MoveToBottomOfScreen(@editor, @, @editorView)
      'move-to-middle-of-screen': => new Motions.MoveToMiddleOfScreen(@editor, @, @editorView)
      'scroll-down': => new Scroll.ScrollDown(@editorView, @editor)
      'scroll-up': => new Scroll.ScrollUp(@editorView, @editor)
      'scroll-cursor-to-top': => new Scroll.ScrollCursorToTop(@editorView, @editor)
      'scroll-cursor-to-top-leave': => new Scroll.ScrollCursorToTop(@editorView, @editor, {leaveCursor: true})
      'scroll-cursor-to-middle': => new Scroll.ScrollCursorToMiddle(@editorView, @editor)
      'scroll-cursor-to-middle-leave': => new Scroll.ScrollCursorToMiddle(@editorView, @editor, {leaveCursor: true})
      'scroll-cursor-to-bottom': => new Scroll.ScrollCursorToBottom(@editorView, @editor)
      'scroll-cursor-to-bottom-leave': => new Scroll.ScrollCursorToBottom(@editorView, @editor, {leaveCursor: true})
      'scroll-half-screen-up': => new Scroll.ScrollHalfScreenUp(@editorView, @editor)
      'scroll-half-screen-down': => new Scroll.ScrollHalfScreenDown(@editorView, @editor)
      'select-inside-word': => new TextObjects.SelectInsideWord(@editor)
      'select-inside-double-quotes': => new TextObjects.SelectInsideQuotes(@editor, '"', false)
      'select-inside-single-quotes': => new TextObjects.SelectInsideQuotes(@editor, '\'', false)
      'select-inside-back-ticks': => new TextObjects.SelectInsideQuotes(@editor, '`', false)
      'select-inside-curly-brackets': => new TextObjects.SelectInsideBrackets(@editor, '{', '}', false)
      'select-inside-angle-brackets': => new TextObjects.SelectInsideBrackets(@editor, '<', '>', false)
      'select-inside-square-brackets': => new TextObjects.SelectInsideBrackets(@editor, '[', ']', false)
      'select-inside-parentheses': => new TextObjects.SelectInsideBrackets(@editor, '(', ')', false)
      'select-a-word': => new TextObjects.SelectAWord(@editor)
      'select-around-double-quotes': => new TextObjects.SelectInsideQuotes(@editor, '"', true)
      'select-around-single-quotes': => new TextObjects.SelectInsideQuotes(@editor, '\'', true)
      'select-around-back-ticks': => new TextObjects.SelectInsideQuotes(@editor, '`', true)
      'select-around-curly-brackets': => new TextObjects.SelectInsideBrackets(@editor, '{', '}', true)
      'select-around-angle-brackets': => new TextObjects.SelectInsideBrackets(@editor, '<', '>', true)
      'select-around-square-brackets': => new TextObjects.SelectInsideBrackets(@editor, '[', ']', true)
      'select-around-parentheses': => new TextObjects.SelectInsideBrackets(@editor, '(', ')', true)
      'register-prefix': (e) => @registerPrefix(e)
      'repeat': (e) => new Operators.Repeat(@editor, @)
      'repeat-search': (e) => currentSearch.repeat() if (currentSearch = Motions.Search.currentSearch)?
      'repeat-search-backwards': (e) => currentSearch.repeat(backwards: true) if (currentSearch = Motions.Search.currentSearch)?
      'focus-pane-view-on-left': => new Panes.FocusPaneViewOnLeft()
      'focus-pane-view-on-right': => new Panes.FocusPaneViewOnRight()
      'focus-pane-view-above': => new Panes.FocusPaneViewAbove()
      'focus-pane-view-below': => new Panes.FocusPaneViewBelow()
      'focus-previous-pane-view': => new Panes.FocusPreviousPaneView()
      'jump-older-pos': (e) => new Motions.MoveToOlderJumpPos(@editor, @)
      'jump-newer-pos': (e) => new Motions.MoveToNewerJumpPos(@editor, @)
      'move-to-mark': (e) => new Motions.MoveToMark(@editorView, @)
      'move-to-mark-literal': (e) => new Motions.MoveToMark(@editorView, @, false)
      'mark': (e) => new Operators.Mark(@editorView, @)
      'find': (e) => new Motions.Find(@editorView, @)
      'find-backwards': (e) => new Motions.Find(@editorView, @).reverse()
      'till': (e) => new Motions.Till(@editorView, @)
      'till-backwards': (e) => new Motions.Till(@editorView, @).reverse()
      'repeat-find': (e) => @currentFind.repeat() if @currentFind?
      'repeat-find-reverse': (e) => @currentFind.repeat(reverse: true) if @currentFind?
      'replace': (e) => new Operators.Replace(@editorView, @)
      'search': (e) => new Motions.Search(@editorView, @)
      'reverse-search': (e) => (new Motions.Search(@editorView, @)).reversed()
      'search-current-word': (e) => new Motions.SearchCurrentWord(@editorView, @)
      'bracket-matching-motion': (e) => new Motions.BracketMatchingMotion(@editorView,@)
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

  # Private: Register multiple Operators via an {Object} that
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
        @opStack.push(new Motions.CurrentSelection(@editor, @))

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
        if (e instanceof Operators.OperatorError) or (e instanceof Motions.MotionError)
          @resetCommandMode()
        else
          throw e
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
  getMark: (name) ->
    if @marks[name]
      @marks[name].getBufferRange().start
    else
      undefined


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
      marker = @editor.markBufferRange(new Range(pos,pos),{invalidate:'never',persistent:false})
      @marks[name] = marker

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
  # Mode Switching
  ##############################################################################

  # Private: Used to enable command mode.
  #
  # Returns nothing.
  activateCommandMode: ->
    @deactivateInsertMode()
    @mode = 'command'
    @submode = null

    if @editorView.is(".insert-mode")
      cursor = @editor.getLastCursor()
      cursor.moveLeft() unless cursor.isAtBeginningOfLine()

    @changeModeClass('command-mode')

    @clearOpStack()
    @editor.clearSelections()

    @updateStatusBar()

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: (transactionStarted = false)->
    @mode = 'insert'
    @editorView.setInputEnabled?(true)
    @editor.beginTransaction() unless transactionStarted
    @submode = null
    @changeModeClass('insert-mode')
    @updateStatusBar()

  deactivateInsertMode: ->
    @editorView.setInputEnabled?(false)
    return unless @mode == 'insert'
    @editor.commitTransaction()
    transaction = _.last(@editor.buffer.history.undoStack)
    item = @inputOperator(@history[0])
    if item? and transaction?
      item.confirmTransaction(transaction)

  # Private: Get the input operator that needs to be told about about the
  # typed undo transaction in a recently completed operation, if there
  # is one.
  inputOperator: (item) ->
    return item unless item?
    return item if item.inputOperator?()
    return item.composedObject if item.composedObject?.inputOperator?()


  # Private: Used to enable visual mode.
  #
  # type - One of 'characterwise', 'linewise' or 'blockwise'
  #
  # Returns nothing.
  activateVisualMode: (type) ->
    @deactivateInsertMode()
    @mode = 'visual'
    @submode = type
    @changeModeClass('visual-mode')

    if @submode == 'linewise'
      @editor.selectLinesContainingCursors()

    @updateStatusBar()

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @deactivateInsertMode()
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
    @clearOpStack()
    @activateCommandMode()

  # Private: A generic way to create a Register prefix based on the event.
  #
  # e - The event that triggered the Register prefix.
  #
  # Returns nothing.
  registerPrefix: (e) ->
    keyboardEvent = e.originalEvent?.originalEvent ? e.originalEvent
    name = atom.keymap.keystrokeForKeyboardEvent(keyboardEvent)
    new Prefixes.Register(name)

  # Private: A generic way to create a Number prefix based on the event.
  #
  # e - The event that triggered the Number prefix.
  #
  # Returns nothing.
  repeatPrefix: (e) ->
    keyboardEvent = e.originalEvent?.originalEvent ? e.originalEvent
    num = parseInt(atom.keymap.keystrokeForKeyboardEvent(keyboardEvent))
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
      new Motions.MoveToBeginningOfLine(@editor, @)

  # Private: A generic way to handle Operators that can be repeated for
  # their linewise form.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  linewiseAliasedOperator: (constructor) ->
    if @isOperatorPending(constructor)
      new Motions.MoveToRelativeLine(@editor, @)
    else
      new constructor(@editor, @)

  # Private: Check if there is a pending operation of a certain type, or
  # if there is any pending operation, if no type given.
  #
  # constructor - The constructor of the object type you're looking for.
  #
  isOperatorPending: (constructor) ->
    if constructor?
      for op in @opStack
        return op if op instanceof constructor
      false
    else
      @opStack.length > 0

  updateStatusBar: ->
    atom.packages.onDidActivateAll =>
      if !$('#status-bar-vim-mode').length
        atom.workspaceView.statusBar?.prependRight("<div id='status-bar-vim-mode' class='inline-block'>Command</div>")
        @updateStatusBar()

    @removeStatusBarClass()
    switch @mode
      when 'insert'  then $('#status-bar-vim-mode').addClass('status-bar-vim-mode-insert').html("Insert")
      when 'command' then $('#status-bar-vim-mode').addClass('status-bar-vim-mode-command').html("Command")
      when 'visual'  then $('#status-bar-vim-mode').addClass('status-bar-vim-mode-visual').html("Visual")

  removeStatusBarClass: -> $('#status-bar-vim-mode').removeClass('status-bar-vim-mode-insert status-bar-vim-mode-command status-bar-vim-mode-visual')
