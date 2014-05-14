{$,$$,EditorView, View, Range} = require 'atom'
_ = require 'underscore-plus'
MarkerView = require './marker-view'

module.exports =
class HighlightedAreaView extends View
  @content: ->
    @div class: 'highlight-selected'

  initialize: (editorView) ->
    @views = []
    @editorView = editorView

  attach: =>
    @editorView.underlayer.append(this)
    # @subscribe @editorView, "selection:changed", @handleSelection
    @subscribe @editorView, "selection:changed", @handleMove
    # atom.workspaceView.on 'pane:item-removed', @destroy

  destroy: =>
    found = false
    for editor in atom.workspaceView.getEditorViews()
      found = true if editor.id is @editorView.id
    return if found
    atom.workspaceView.off 'pane:item-removed', @destroy
    @unsubscribe()
    @remove()
    @detach()

  appendMarker: (marker) ->
    @append(marker.element)
    @views.push(marker)

  # handleSelection: =>
  #   @removeMarkers()
  #
  handleMove: =>
    if @views.length>0
      searcherReference = @views[0].searcher
      searcherReference.markAll()

  removeMarkers: =>
    return unless @views?
    return if @views.length is 0
    for view in @views
      view.element.remove()
      view = null
    @views = []
