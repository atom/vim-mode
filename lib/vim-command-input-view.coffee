{View} = require 'atom'

module.exports =

class VimCommandModeInputView extends View
  @content: ->
    @div class: 'vim-command-mode-input', =>
      @input class: 'vim-command-mode-input-field'
