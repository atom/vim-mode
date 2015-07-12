{ViewModel} = require './view-model'

module.exports =
class ViewModelWithHistory extends ViewModel
  constructor: (@searchMotion, @historyName) ->
    super(@searchMotion, class: 'search')
    @historyIndex = -1

    atom.commands.add(@view.editorElement, 'core:move-up', @increaseHistory)
    atom.commands.add(@view.editorElement, 'core:move-down', @decreaseHistory)

  restoreHistory: (index) ->
    @view.editorElement.getModel().setText(@history(index))

  history: (index) ->
    @vimState.getCustomHistoryItem(@historyName, index)

  increaseHistory: =>
    if @history(@historyIndex + 1)?
      @historyIndex += 1
      @restoreHistory(@historyIndex)

  decreaseHistory: =>
    if @historyIndex <= 0
      # get us back to a clean slate
      @historyIndex = -1
      @view.editorElement.getModel().setText('')
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  confirm: (view) =>
    repeatChar = if @searchMotion.initiallyReversed then '?' else '/'
    if @view.value is '' or @view.value is repeatChar
      lastSearch = @history(0)
      if lastSearch?
        @view.value = lastSearch
      else
        @view.value = ''
        atom.beep()
    super(view)
    @vimState.pushCustomHistory(@historyName, @view.value) unless @view.value is ''
