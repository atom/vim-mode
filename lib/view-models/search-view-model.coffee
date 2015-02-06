{ViewModel} = require './view-model'

module.exports =
class SearchViewModel extends ViewModel
  constructor: (@searchMotion) ->
    @prefixChar = if @searchMotion.initiallyReversed then '?' else '/'
    super(@searchMotion, class: 'search', prefixChar: @prefixChar)
    @historyIndex = -1

    @view.editor.on('core:move-up', @increaseHistorySearch)
    @view.editor.on('core:move-down', @decreaseHistorySearch)

  restoreHistory: (index) ->
    @view.editor.setText(@prefixChar + @history(index).value)

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
      @view.editor.setText(@prefixChar)
    else
      @historyIndex -= 1
      @restoreHistory(@historyIndex)

  confirm: (view) =>
    @vimState.pushSearchHistory(@)
    super(view)
