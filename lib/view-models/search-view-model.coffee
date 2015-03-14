{ViewModel} = require './view-model'

module.exports =
class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    super(@searchMotion, class: 'search')
    @historyIndex = -1

    atom.commands.add(@view.editorElement, 'core:move-up', @increaseHistorySearch)
    atom.commands.add(@view.editorElement, 'core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editorElement.getModel().setText(@history(index).value)

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
    @vimState.pushSearchHistory(@)
    super(view)
