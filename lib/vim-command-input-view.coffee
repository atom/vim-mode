{View} = require 'atom'

module.exports =

class VimCommandModeInputView extends View
  @content: ->
    @div class: 'command-mode-input', =>
      @input outlet: "input", class: 'command-mode-input-field'

  initialize: (@motion)->
    pane = rootView.getActivePane()
    statusBar = pane.find('.status-bar')

    if statusBar.length > 0
      @.insertBefore(statusBar)
    else
      pane.append(@)

    @input.focus()
    @handleEvents()

  handleEvents: ->
    @on 'vim-mode:command-mode-input-confirm', @confirm
    @on 'core:cancel', @remove
    @on 'core:focus-next', @remove
    @on 'core:focus-previous', @remove

  confirm: =>
    window.inp = @input
    @value = @input[0].value
    @motion.confirm(@)
    @remove()

  remove: =>
    rootView.focus()
    super()
