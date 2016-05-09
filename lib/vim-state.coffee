Grim  = require 'grim'
_ = require 'underscore-plus'
{Point, Range} = require 'atom'
{Emitter, Disposable, CompositeDisposable} = require 'event-kit'
settings = require './settings'

Operators = require './operators/index'
Prefixes = require './prefixes'
Motions = require './motions/index'
InsertMode = require './insert-mode'

TextObjects = require './text-objects'
Utils = require './utils'
Scroll = require './scroll'

module.exports =
class VimState
  editor: null
  opStack: null
  mode: null
  submode: null
  destroyed: false
  replaceModeListener: null

  constructor: (@editorElement, @statusBarManager, @globalVimState) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @editor = @editorElement.getModel()
    @opStack = []
    @history = []
    @marks = {}
    @subscriptions.add @editor.onDidDestroy => @destroy()

    @editorElement.addEventListener 'mouseup', @checkSelections
    if atom.commands.onDidDispatch?
      @subscriptions.add atom.commands.onDidDispatch (e) =>
        if e.target is @editorElement
          @checkSelections()

    @editorElement.classList.add("vim-mode")
    @setupNormalMode()
    if settings.startInInsertMode()
      @activateInsertMode()
    else
      @activateNormalMode()

  destroy: ->
    unless @destroyed
      @destroyed = true
      @subscriptions.dispose()
      if @editor.isAlive()
        @deactivateInsertMode()
        @editorElement.component?.setInputEnabled(true)
        @editorElement.classList.remove("vim-mode")
        @editorElement.classList.remove("normal-mode")
      @editorElement.removeEventListener 'mouseup', @checkSelections
      @editor = null
      @editorElement = null
      @emitter.emit 'did-destroy'

  # Private: Creates the plugin's bindings
  #
  # Returns nothing.
  setupNormalMode: ->
    @registerCommands
      'activate-normal-mode': => @activateNormalMode()
      'activate-linewise-visual-mode': => @activateVisualMode('linewise')
      'activate-characterwise-visual-mode': => @activateVisualMode('characterwise')
      'activate-blockwise-visual-mode': => @activateVisualMode('blockwise')
      'reset-normal-mode': => @resetNormalMode()
      'repeat-prefix': (e) => @repeatPrefix(e)
      'reverse-selections': (e) => @reverseSelections(e)
      'undo': (e) => @undo(e)
      'replace-mode-backspace': => @replaceModeUndo()
      'insert-mode-put': (e) => @insertRegister(@registerName(e))
      'copy-from-line-above': => InsertMode.copyCharacterFromAbove(@editor, this)
      'copy-from-line-below': => InsertMode.copyCharacterFromBelow(@editor, this)

    @registerOperationCommands
      'activate-insert-mode': => new Operators.Insert(@editor, this)
      'activate-replace-mode': => new Operators.ReplaceMode(@editor, this)
      'substitute': => [new Operators.Change(@editor, this), new Motions.MoveRight(@editor, this)]
      'substitute-line': => [new Operators.Change(@editor, this), new Motions.MoveToRelativeLine(@editor, this)]
      'insert-after': => new Operators.InsertAfter(@editor, this)
      'insert-after-end-of-line': => new Operators.InsertAfterEndOfLine(@editor, this)
      'insert-at-beginning-of-line': => new Operators.InsertAtBeginningOfLine(@editor, this)
      'insert-above-with-newline': => new Operators.InsertAboveWithNewline(@editor, this)
      'insert-below-with-newline': => new Operators.InsertBelowWithNewline(@editor, this)
      'delete': => @linewiseAliasedOperator(Operators.Delete)
      'change': => @linewiseAliasedOperator(Operators.Change)
      'change-to-last-character-of-line': => [new Operators.Change(@editor, this), new Motions.MoveToLastCharacterOfLine(@editor, this)]
      'delete-right': => [new Operators.Delete(@editor, this), new Motions.MoveRight(@editor, this)]
      'delete-left': => [new Operators.Delete(@editor, this), new Motions.MoveLeft(@editor, this)]
      'delete-to-last-character-of-line': => [new Operators.Delete(@editor, this), new Motions.MoveToLastCharacterOfLine(@editor, this)]
      'toggle-case': => new Operators.ToggleCase(@editor, this)
      'upper-case': => new Operators.UpperCase(@editor, this)
      'lower-case': => new Operators.LowerCase(@editor, this)
      'toggle-case-now': => new Operators.ToggleCase(@editor, this, complete: true)
      'yank': => @linewiseAliasedOperator(Operators.Yank)
      'yank-line': => [new Operators.Yank(@editor, this), new Motions.MoveToRelativeLine(@editor, this)]
      'put-before': => new Operators.Put(@editor, this, location: 'before')
      'put-after': => new Operators.Put(@editor, this, location: 'after')
      'join': => new Operators.Join(@editor, this)
      'indent': => @linewiseAliasedOperator(Operators.Indent)
      'outdent': => @linewiseAliasedOperator(Operators.Outdent)
      'auto-indent': => @linewiseAliasedOperator(Operators.Autoindent)
      'increase': => new Operators.Increase(@editor, this)
      'decrease': => new Operators.Decrease(@editor, this)
      'move-left': => new Motions.MoveLeft(@editor, this)
      'move-up': => new Motions.MoveUp(@editor, this)
      'move-down': => new Motions.MoveDown(@editor, this)
      'move-right': => new Motions.MoveRight(@editor, this)
      'move-to-next-word': => new Motions.MoveToNextWord(@editor, this)
      'move-to-next-whole-word': => new Motions.MoveToNextWholeWord(@editor, this)
      'move-to-end-of-word': => new Motions.MoveToEndOfWord(@editor, this)
      'move-to-end-of-whole-word': => new Motions.MoveToEndOfWholeWord(@editor, this)
      'move-to-previous-word': => new Motions.MoveToPreviousWord(@editor, this)
      'move-to-previous-whole-word': => new Motions.MoveToPreviousWholeWord(@editor, this)
      'move-to-next-paragraph': => new Motions.MoveToNextParagraph(@editor, this)
      'move-to-next-sentence': => new Motions.MoveToNextSentence(@editor, this)
      'move-to-previous-sentence': => new Motions.MoveToPreviousSentence(@editor, this)
      'move-to-previous-paragraph': => new Motions.MoveToPreviousParagraph(@editor, this)
      'move-to-first-character-of-line': => new Motions.MoveToFirstCharacterOfLine(@editor, this)
      'move-to-first-character-of-line-and-down': => new Motions.MoveToFirstCharacterOfLineAndDown(@editor, this)
      'move-to-last-character-of-line': => new Motions.MoveToLastCharacterOfLine(@editor, this)
      'move-to-last-nonblank-character-of-line-and-down': => new Motions.MoveToLastNonblankCharacterOfLineAndDown(@editor, this)
      'move-to-beginning-of-line': (e) => @moveOrRepeat(e)
      'move-to-first-character-of-line-up': => new Motions.MoveToFirstCharacterOfLineUp(@editor, this)
      'move-to-first-character-of-line-down': => new Motions.MoveToFirstCharacterOfLineDown(@editor, this)
      'move-to-start-of-file': => new Motions.MoveToStartOfFile(@editor, this)
      'move-to-line': => new Motions.MoveToAbsoluteLine(@editor, this)
      'move-to-top-of-screen': => new Motions.MoveToTopOfScreen(@editorElement, this)
      'move-to-bottom-of-screen': => new Motions.MoveToBottomOfScreen(@editorElement, this)
      'move-to-middle-of-screen': => new Motions.MoveToMiddleOfScreen(@editorElement, this)
      'scroll-down': => new Scroll.ScrollDown(@editorElement)
      'scroll-up': => new Scroll.ScrollUp(@editorElement)
      'scroll-cursor-to-top': => new Scroll.ScrollCursorToTop(@editorElement)
      'scroll-cursor-to-top-leave': => new Scroll.ScrollCursorToTop(@editorElement, {leaveCursor: true})
      'scroll-cursor-to-middle': => new Scroll.ScrollCursorToMiddle(@editorElement)
      'scroll-cursor-to-middle-leave': => new Scroll.ScrollCursorToMiddle(@editorElement, {leaveCursor: true})
      'scroll-cursor-to-bottom': => new Scroll.ScrollCursorToBottom(@editorElement)
      'scroll-cursor-to-bottom-leave': => new Scroll.ScrollCursorToBottom(@editorElement, {leaveCursor: true})
      'scroll-half-screen-up': => new Motions.ScrollHalfUpKeepCursor(@editorElement, this)
      'scroll-full-screen-up': => new Motions.ScrollFullUpKeepCursor(@editorElement, this)
      'scroll-half-screen-down': => new Motions.ScrollHalfDownKeepCursor(@editorElement, this)
      'scroll-full-screen-down': => new Motions.ScrollFullDownKeepCursor(@editorElement, this)
      'scroll-cursor-to-left': => new Scroll.ScrollCursorToLeft(@editorElement)
      'scroll-cursor-to-right': => new Scroll.ScrollCursorToRight(@editorElement)
      'select-inside-word': => new TextObjects.SelectInsideWord(@editor)
      'select-inside-whole-word': => new TextObjects.SelectInsideWholeWord(@editor)
      'select-inside-double-quotes': => new TextObjects.SelectInsideQuotes(@editor, '"', false)
      'select-inside-single-quotes': => new TextObjects.SelectInsideQuotes(@editor, '\'', false)
      'select-inside-back-ticks': => new TextObjects.SelectInsideQuotes(@editor, '`', false)
      'select-inside-curly-brackets': => new TextObjects.SelectInsideBrackets(@editor, '{', '}', false)
      'select-inside-angle-brackets': => new TextObjects.SelectInsideBrackets(@editor, '<', '>', false)
      'select-inside-tags': => new TextObjects.SelectInsideBrackets(@editor, '>', '<', false)
      'select-inside-square-brackets': => new TextObjects.SelectInsideBrackets(@editor, '[', ']', false)
      'select-inside-parentheses': => new TextObjects.SelectInsideBrackets(@editor, '(', ')', false)
      'select-inside-paragraph': => new TextObjects.SelectInsideParagraph(@editor, false)
      'select-a-word': => new TextObjects.SelectAWord(@editor)
      'select-a-whole-word': => new TextObjects.SelectAWholeWord(@editor)
      'select-around-double-quotes': => new TextObjects.SelectInsideQuotes(@editor, '"', true)
      'select-around-single-quotes': => new TextObjects.SelectInsideQuotes(@editor, '\'', true)
      'select-around-back-ticks': => new TextObjects.SelectInsideQuotes(@editor, '`', true)
      'select-around-curly-brackets': => new TextObjects.SelectInsideBrackets(@editor, '{', '}', true)
      'select-around-angle-brackets': => new TextObjects.SelectInsideBrackets(@editor, '<', '>', true)
      'select-around-square-brackets': => new TextObjects.SelectInsideBrackets(@editor, '[', ']', true)
      'select-around-parentheses': => new TextObjects.SelectInsideBrackets(@editor, '(', ')', true)
      'select-around-paragraph': => new TextObjects.SelectAParagraph(@editor, true)
      'register-prefix': (e) => @registerPrefix(e)
      'repeat': (e) => new Operators.Repeat(@editor, this)
      'repeat-search': (e) => new Motions.RepeatSearch(@editor, this)
      'repeat-search-backwards': (e) => new Motions.RepeatSearch(@editor, this).reversed()
      'move-to-mark': (e) => new Motions.MoveToMark(@editor, this)
      'move-to-mark-literal': (e) => new Motions.MoveToMark(@editor, this, false)
      'mark': (e) => new Operators.Mark(@editor, this)
      'find': (e) => new Motions.Find(@editor, this)
      'find-backwards': (e) => new Motions.Find(@editor, this).reverse()
      'till': (e) => new Motions.Till(@editor, this)
      'till-backwards': (e) => new Motions.Till(@editor, this).reverse()
      'repeat-find': (e) => new @globalVimState.currentFind.constructor(@editor, this, repeated: true) if @globalVimState.currentFind
      'repeat-find-reverse': (e) => new @globalVimState.currentFind.constructor(@editor, this, repeated: true, reverse: true) if @globalVimState.currentFind
      'replace': (e) => new Operators.Replace(@editor, this)
      'search': (e) => new Motions.Search(@editor, this)
      'reverse-search': (e) => (new Motions.Search(@editor, this)).reversed()
      'search-current-word': (e) => new Motions.SearchCurrentWord(@editor, this)
      'bracket-matching-motion': (e) => new Motions.BracketMatchingMotion(@editor, this)
      'reverse-search-current-word': (e) => (new Motions.SearchCurrentWord(@editor, this)).reversed()

  # Private: Register multiple command handlers via an {Object} that maps
  # command names to command handler functions.
  #
  # Prefixes the given command names with 'vim-mode:' to reduce redundancy in
  # the provided object.
  registerCommands: (commands) ->
    for commandName, fn of commands
      do (fn) =>
        @subscriptions.add(atom.commands.add(@editorElement, "vim-mode:#{commandName}", fn))

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
        @resetNormalMode()
        @emitter.emit('failed-to-compose')
        break

      @opStack.push(operation)

      # If we've received an operator in visual mode, mark the current
      # selection as the motion to operate on.
      if @mode is 'visual' and operation instanceof Operators.Operator
        @opStack.push(new Motions.CurrentSelection(@editor, this))

      @processOpStack()

  onDidFailToCompose: (fn) ->
    @emitter.on('failed-to-compose', fn)

  onDidDestroy: (fn) ->
    @emitter.on('did-destroy', fn)

  # Private: Removes all operations from the stack.
  #
  # Returns nothing.
  clearOpStack: ->
    @opStack = []

  undo: ->
    @editor.undo()
    @activateNormalMode()

  # Private: Processes the command if the last operation is complete.
  #
  # Returns nothing.
  processOpStack: ->
    unless @opStack.length > 0
      return

    unless @topOperation().isComplete()
      if @mode is 'normal' and @topOperation() instanceof Operators.Operator
        @activateOperatorPendingMode()
      return

    poppedOperation = @opStack.pop()
    if @opStack.length
      try
        @topOperation().compose(poppedOperation)
        @processOpStack()
      catch e
        if (e instanceof Operators.OperatorError) or (e instanceof Motions.MotionError)
          @resetNormalMode()
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
    if name is '"'
      name = settings.defaultRegister()
    if name in ['*', '+']
      text = atom.clipboard.read()
      type = Utils.copyType(text)
      {text, type}
    else if name is '%'
      text = @editor.getURI()
      type = Utils.copyType(text)
      {text, type}
    else if name is "_" # Blackhole always returns nothing
      text = ''
      type = Utils.copyType(text)
      {text, type}
    else
      @globalVimState.registers[name.toLowerCase()]

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
    if name is '"'
      name = settings.defaultRegister()
    if name in ['*', '+']
      atom.clipboard.write(value.text)
    else if name is '_'
      # Blackhole register, nothing to do
    else if /^[A-Z]$/.test(name)
      @appendRegister(name.toLowerCase(), value)
    else
      @globalVimState.registers[name] = value


  # Private: append a value into a given register
  # like setRegister, but appends the value
  appendRegister: (name, value) ->
    register = @globalVimState.registers[name] ?=
      type: 'character'
      text: ""
    if register.type is 'linewise' and value.type isnt 'linewise'
      register.text += value.text + '\n'
    else if register.type isnt 'linewise' and value.type is 'linewise'
      register.text += '\n' + value.text
      register.type = 'linewise'
    else
      register.text += value.text

  # Private: Sets the value of a given mark.
  #
  # name  - The name of the mark to fetch.
  # pos {Point} - The value to set the mark to.
  #
  # Returns nothing.
  setMark: (name, pos) ->
    # check to make sure name is in [a-z] or is `
    if (charCode = name.charCodeAt(0)) >= 96 and charCode <= 122
      marker = @editor.markBufferRange(new Range(pos, pos), {invalidate: 'never', persistent: false})
      @marks[name] = marker

  # Public: Append a search to the search history.
  #
  # Motions.Search - The confirmed search motion to append
  #
  # Returns nothing
  pushSearchHistory: (search) ->
    @globalVimState.searchHistory.unshift search

  # Public: Get the search history item at the given index.
  #
  # index - the index of the search history item
  #
  # Returns a search motion
  getSearchHistoryItem: (index = 0) ->
    @globalVimState.searchHistory[index]

  ##############################################################################
  # Mode Switching
  ##############################################################################

  # Private: Used to enable normal mode.
  #
  # Returns nothing.
  activateNormalMode: ->
    @deactivateInsertMode()
    @deactivateVisualMode()

    @mode = 'normal'
    @submode = null

    @changeModeClass('normal-mode')

    @clearOpStack()
    selection.clear(autoscroll: false) for selection in @editor.getSelections()
    @ensureCursorsWithinLine()

    @updateStatusBar()

  # TODO: remove this method and bump the `vim-mode` service version number.
  activateCommandMode: ->
    Grim.deprecate("Use ::activateNormalMode instead")
    @activateNormalMode()

  # Private: Used to enable insert mode.
  #
  # Returns nothing.
  activateInsertMode: (subtype = null) ->
    @mode = 'insert'
    @editorElement.component.setInputEnabled(true)
    @setInsertionCheckpoint()
    @submode = subtype
    @changeModeClass('insert-mode')
    @updateStatusBar()

  activateReplaceMode: ->
    @activateInsertMode('replace')
    @replaceModeCounter = 0
    @editorElement.classList.add('replace-mode')
    @subscriptions.add @replaceModeListener = @editor.onWillInsertText @replaceModeInsertHandler
    @subscriptions.add @replaceModeUndoListener = @editor.onDidInsertText @replaceModeUndoHandler

  replaceModeInsertHandler: (event) =>
    chars = event.text?.split('') or []
    selections = @editor.getSelections()
    for char in chars
      continue if char is '\n'
      for selection in selections
        selection.delete() unless selection.cursor.isAtEndOfLine()
    return

  replaceModeUndoHandler: (event) =>
    @replaceModeCounter++

  replaceModeUndo: ->
    if @replaceModeCounter > 0
      @editor.undo()
      @editor.undo()
      @editor.moveLeft()
      @replaceModeCounter--

  setInsertionCheckpoint: ->
    @insertionCheckpoint = @editor.createCheckpoint() unless @insertionCheckpoint?

  deactivateInsertMode: ->
    return unless @mode in [null, 'insert']
    @editorElement.component.setInputEnabled(false)
    @editorElement.classList.remove('replace-mode')
    @editor.groupChangesSinceCheckpoint(@insertionCheckpoint)
    changes = @editor.buffer.getChangesSinceCheckpoint(@insertionCheckpoint)
    item = @inputOperator(@history[0])
    @insertionCheckpoint = null
    if item?
      item.confirmChanges(changes)
    for cursor in @editor.getCursors()
      cursor.moveLeft() unless cursor.isAtBeginningOfLine()
    if @replaceModeListener?
      @replaceModeListener.dispose()
      @subscriptions.remove @replaceModeListener
      @replaceModeListener = null
      @replaceModeUndoListener.dispose()
      @subscriptions.remove @replaceModeUndoListener
      @replaceModeUndoListener = null

  deactivateVisualMode: ->
    return unless @mode is 'visual'
    for selection in @editor.getSelections()
      selection.cursor.moveLeft() unless (selection.isEmpty() or selection.isReversed())

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
    # Already in 'visual', this means one of following command is
    # executed within `vim-mode.visual-mode`
    #  * activate-blockwise-visual-mode
    #  * activate-characterwise-visual-mode
    #  * activate-linewise-visual-mode
    if @mode is 'visual'
      if @submode is type
        @activateNormalMode()
        return

      @submode = type
      if @submode is 'linewise'
        for selection in @editor.getSelections()
          # Keep original range as marker's property to get back
          # to characterwise.
          # Since selectLine lost original cursor column.
          originalRange = selection.getBufferRange()
          selection.marker.setProperties({originalRange})
          [start, end] = selection.getBufferRowRange()
          selection.selectLine(row) for row in [start..end]

      else if @submode in ['characterwise', 'blockwise']
        # Currently, 'blockwise' is not yet implemented.
        # So treat it as characterwise.
        # Recover original range.
        for selection in @editor.getSelections()
          {originalRange} = selection.marker.getProperties()
          if originalRange
            [startRow, endRow] = selection.getBufferRowRange()
            originalRange.start.row = startRow
            originalRange.end.row   = endRow
            selection.setBufferRange(originalRange)
    else
      @deactivateInsertMode()
      @mode = 'visual'
      @submode = type
      @changeModeClass('visual-mode')

      if @submode is 'linewise'
        @editor.selectLinesContainingCursors()
      else if @editor.getSelectedText() is ''
        @editor.selectRight()

    @updateStatusBar()

  # Private: Used to re-enable visual mode
  resetVisualMode: ->
    @activateVisualMode(@submode)

  # Private: Used to enable operator-pending mode.
  activateOperatorPendingMode: ->
    @deactivateInsertMode()
    @mode = 'operator-pending'
    @submode = null
    @changeModeClass('operator-pending-mode')

    @updateStatusBar()

  changeModeClass: (targetMode) ->
    for mode in ['normal-mode', 'insert-mode', 'visual-mode', 'operator-pending-mode']
      if mode is targetMode
        @editorElement.classList.add(mode)
      else
        @editorElement.classList.remove(mode)

  # Private: Resets the normal mode back to it's initial state.
  #
  # Returns nothing.
  resetNormalMode: ->
    @clearOpStack()
    @editor.clearSelections()
    @activateNormalMode()

  # Private: A generic way to create a Register prefix based on the event.
  #
  # e - The event that triggered the Register prefix.
  #
  # Returns nothing.
  registerPrefix: (e) ->
    new Prefixes.Register(@registerName(e))

  # Private: Gets a register name from a keyboard event
  #
  # e - The event
  #
  # Returns the name of the register
  registerName: (e) ->
    keyboardEvent = e.originalEvent?.originalEvent ? e.originalEvent
    name = atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent)
    if name.lastIndexOf('shift-', 0) is 0
      name = name.slice(6)
    name

  # Private: A generic way to create a Number prefix based on the event.
  #
  # e - The event that triggered the Number prefix.
  #
  # Returns nothing.
  repeatPrefix: (e) ->
    keyboardEvent = e.originalEvent?.originalEvent ? e.originalEvent
    num = parseInt(atom.keymaps.keystrokeForKeyboardEvent(keyboardEvent))
    if @topOperation() instanceof Prefixes.Repeat
      @topOperation().addDigit(num)
    else
      if num is 0
        e.abortKeyBinding()
      else
        @pushOperations(new Prefixes.Repeat(num))

  reverseSelections: ->
    reversed = not @editor.getLastSelection().isReversed()
    for selection in @editor.getSelections()
      selection.setBufferRange(selection.getBufferRange(), {reversed})

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
      new Motions.MoveToBeginningOfLine(@editor, this)

  # Private: A generic way to handle Operators that can be repeated for
  # their linewise form.
  #
  # constructor - The constructor of the operator.
  #
  # Returns nothing.
  linewiseAliasedOperator: (constructor) ->
    if @isOperatorPending(constructor)
      new Motions.MoveToRelativeLine(@editor, this)
    else
      new constructor(@editor, this)

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
    @statusBarManager.update(@mode, @submode)

  # Private: insert the contents of the register in the editor
  #
  # name - the name of the register to insert
  #
  # Returns nothing.
  insertRegister: (name) ->
    text = @getRegister(name)?.text
    @editor.insertText(text) if text?

  # Private: ensure the mode follows the state of selections
  checkSelections: =>
    return unless @editor?
    if @editor.getSelections().every((selection) -> selection.isEmpty())
      @ensureCursorsWithinLine() if @mode is 'normal'
      @activateNormalMode() if @mode is 'visual'
    else
      @activateVisualMode('characterwise') if @mode is 'normal'

  # Private: ensure the cursor stays within the line as appropriate
  ensureCursorsWithinLine: =>
    for cursor in @editor.getCursors()
      {goalColumn} = cursor
      if cursor.isAtEndOfLine() and not cursor.isAtBeginningOfLine()
        cursor.moveLeft()
      cursor.goalColumn = goalColumn

    @editor.mergeCursors()
