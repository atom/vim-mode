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
      @disposables.add atom.packages.onDidActivateInitialPackages => @attach()
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
    statusBar = document.querySelector("status-bar")
    if statusBar?
      tile = statusBar.addRightTile(item: @element, priority: 20)
      @disposables.add new Disposable => tile.destroy()
      true
    else
      false
