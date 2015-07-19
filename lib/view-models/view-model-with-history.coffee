{ViewModel} = require './view-model'

class ViewModelWithHistory extends ViewModel
  constructor: (@searchMotion, @historyName) ->
    super(@searchMotion, class: @historyName)
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

  checkForRepeatSearch: (term, reversed=@searchMotion.initiallyReversed) ->
    repeatChar = if reversed then '?' else '/'
    if term is '' or term[0] is repeatChar
      lastSearch = @vimState.getCustomHistoryItem('search', 0)
      if lastSearch?
        term = lastSearch
      else
        term = ''
        atom.beep()
    term

  confirm: (view) =>
    super(view)
    @vimState.pushCustomHistory(@historyName, @view.value) unless @view.value in ['', @history(0)]

class SearchViewModel extends ViewModelWithHistory
  constructor: (@searchMotion) ->
    super(@searchMotion, 'search')

  confirm: (view) =>
    @view.value = @checkForRepeatSearch(@view.value)
    super(view)

module.exports =
  ViewModelWithHistory: ViewModelWithHistory
  SearchViewModel: SearchViewModel
