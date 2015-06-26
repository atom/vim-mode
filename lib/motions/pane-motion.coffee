module.exports =
class Pane
  constructor: (@editor, @vimState) ->

  execute: (count) ->
    if count
      atom.workspace.getActivePane().activateItemAtIndex(count-1)
    else
      activeEditor = atom.workspace.getActiveTextEditor()
      editors = atom.workspace.getTextEditors()
      editors = (editor for editor in editors when editor isnt activeEditor)
      editors = editors.sort (a, b) -> b.lastOpened - a.lastOpened
      @activateEditor(editors[0])

  activateEditor: (item) ->
    for pane in atom.workspace.getPanes()
      index = pane.getItems().indexOf(item)
      pane.activateItemAtIndex(index) if index?

  isComplete: -> true
  isRecordable: -> false
