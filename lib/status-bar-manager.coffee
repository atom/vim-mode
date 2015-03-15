{Disposable, CompositeDisposable} = require 'event-kit'

# Mode names are combined with submode names with the `.` character.
# If a mode has submodes, they need to be enumerated here.
ContentsByMode =
  'insert':               ["status-bar-vim-mode-insert",  "Insert"]
  'insert.replace':       ["status-bar-vim-mode-insert",  "Replace"]
  'command':              ["status-bar-vim-mode-command", "Command"]
  'visual':               ["status-bar-vim-mode-visual",  "Visual"]
  'visual.characterwise': ["status-bar-vim-mode-visual",  "Visual"]
  'visual.linewise':      ["status-bar-vim-mode-visual",  "Visual Line"]
  'visual.blockwise':     ["status-bar-vim-mode-visual",  "Visual Block"]

ClassesByMode = []

for mode, [klass, html] of ContentsByMode
  ClassesByMode.push(klass) unless klass in ClassesByMode

module.exports =
class StatusBarManager
  constructor: ->
    @element = document.createElement("div")
    @element.id = "status-bar-vim-mode"
    @element.classList.add("inline-block")

  initialize: (@statusBar) ->

  update: (currentMode, currentSubmode) ->
    currentMode = currentMode + "." + currentSubmode if currentSubmode?
    return unless currentMode of ContentsByMode

    # remove all the classes from @element before adding the right class
    for klass in ClassesByMode
      @element.classList.remove(klass)

    [klass, html] = ContentsByMode[currentMode]
    @element.classList.add(klass)
    @element.innerHTML = html

  # Private

  attach: ->
    @tile = @statusBar.addRightTile(item: @element, priority: 20)

  detach: ->
    @tile.destroy()
