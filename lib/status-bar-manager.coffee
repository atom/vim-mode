{Disposable, CompositeDisposable} = require 'event-kit'

ContentsByMode =
  insert:  ["status-bar-vim-mode-insert", "Insert"]
  command: ["status-bar-vim-mode-command", "Command"]
  visual:  ["status-bar-vim-mode-visual", "Visual"]

module.exports =
class StatusBarManager
  constructor: ->
    @element = document.createElement("div")
    @element.id = "status-bar-vim-mode"
    @element.classList.add("inline-block")

  initialize: ->
    @disposables = new CompositeDisposable
    unless @attach()
      @disposables.add atom.packages.onDidActivateAll => @attach()
    @disposables

  update: (currentMode) ->
    for mode, [klass, html] of ContentsByMode
      if mode is currentMode
        @element.classList.add(klass)
        @element.innerHTML = html
      else
        @element.classList.remove(klass)

  # Private

  attach: ->
    statusBar = atom.workspaceView?.statusBar
    if statusBar?
      statusBar.prependRight(@element)
      @disposables.add new Disposable =>
        @element.parentNode?.removeChild(@element)
      true
    else
      false
