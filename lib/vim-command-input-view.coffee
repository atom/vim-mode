{View} = require 'atom'

module.exports =

class VimCommandModeInputView extends View
  activate: ->
    console.log "activating"

  @content: ->
    console.log "contenting"
    @div class: 'command-mode-input', =>
      @input outlet: "input", class: 'command-mode-input-field'

  initialize: ->
    pane = rootView.getActivePane()
    statusBar = pane.find('.status-bar')

    if statusBar.length > 0
      @.insertBefore(statusBar)
    else
      pane.append(@)

    @input.focus()
    @handleEvents()

  handleEvents: ->
    console.log "handling events"
    @on 'vim-mode:command-mode-input-confirm', =>
      console.log "someone pressed enter!"
