ContentsByMode =
  'insert': ["status-bar-vim-mode-insert", "Insert"]
  'insert.replace': ["status-bar-vim-mode-insert", "Replace"]
  'normal': ["status-bar-vim-mode-normal", "Normal"]
  'visual': ["status-bar-vim-mode-visual", "Visual"]
  'visual.characterwise': ["status-bar-vim-mode-visual", "Visual"]
  'visual.linewise': ["status-bar-vim-mode-visual", "Visual Line"]
  'visual.blockwise': ["status-bar-vim-mode-visual", "Visual Block"]

module.exports =
class StatusBarManager
  constructor: ->
    @element = document.createElement("div")
    @element.id = "status-bar-vim-mode"

    @container = document.createElement("div")
    @container.className = "inline-block"
    @container.appendChild(@element)

  initialize: (@statusBar) ->

  update: (currentMode, currentSubmode) ->
    currentMode = currentMode + "." + currentSubmode if currentSubmode?
    if newContents = ContentsByMode[currentMode]
      [klass, text] = newContents
      @element.className = klass
      @element.textContent = text
    else
      @hide()

  hide: ->
    @element.className = 'hidden'

  # Private

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
