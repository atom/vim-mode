VimState = require './vim-state'

module.exports =

  activate: (state) ->
    atom.rootView.eachEditor (editor) =>
      return unless editor.attached

      editor.addClass('vim-mode')
      editor.vimState = new VimState(editor)
