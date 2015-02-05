{ViewModel} = require './view-model'

module.exports =
class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    super(@searchMotion, class: 'search')
    @historyIndex = -1

    @view.editor.on('core:move-up', @increaseHistorySearch)
    @view.editor.on('core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editor.setText(@history(index).value)

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
      @view.editor.setText('')
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  confirm: (view) =>
    @vimState.pushSearchHistory(@)
    super(view)
