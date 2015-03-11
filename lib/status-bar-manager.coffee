{Disposable, CompositeDisposable} = require 'event-kit'

# mode names can be combined with submode names with the `$` character
# the order matters - the last matching entry wins
ContentsByMode =
  insert:           ["status-bar-vim-mode-insert", "Insert"]
  insert$replace:   ["status-bar-vim-mode-insert", "Replace"]
  command:          ["status-bar-vim-mode-command", "Command"]
  visual:           ["status-bar-vim-mode-visual", "Visual"]
  visual$linewise:  ["status-bar-vim-mode-visual", "Visual Line"]
  visual$blockwise: ["status-bar-vim-mode-visual", "Visual Block"]

module.exports =
class StatusBarManager
  constructor: ->
    @element = document.createElement("div")
    @element.id = "status-bar-vim-mode"
    @element.classList.add("inline-block")

  initialize: (@statusBar) ->

  update: (currentMode, currentSubmode) ->
    currentFullMode = currentMode + "$" + currentSubmode if currentSubmode?
    for mode, [klass, html] of ContentsByMode
      if mode is currentMode or mode is currentFullMode
        @element.classList.add(klass)
        @element.innerHTML = html
      else
        @element.classList.remove(klass)

  # Private

  attach: ->
    @tile = @statusBar.addRightTile(item: @element, priority: 20)

  detach: ->
    @tile.destroy()
