{ViewModel} = require './view-model'

module.exports =
class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    super(@searchMotion, class: 'search')
    @historyIndex = -1

    atom.commands.add(@view.editorElement, 'core:move-up', @increaseHistorySearch)
    atom.commands.add(@view.editorElement, 'core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editorElement.getModel().setText(@history(index))

  history: (index) ->
    @vimState.getSearchHistoryItem(index)

  increaseHistorySearch: =>
    if @history(@historyIndex + 1)?
      @historyIndex += 1
      @restoreHistory(@historyIndex)

  decreaseHistorySearch: =>
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
    @vimState.pushSearchHistory(@view.value)

  update: (reverse) ->
    if reverse
      @view.classList.add('reverse-search-input')
      @view.classList.remove('search-input')
    else
      @view.classList.add('search-input')
      @view.classList.remove('reverse-search-input')
