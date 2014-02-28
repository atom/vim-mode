{View, EditorView} = require 'atom'

module.exports =

class VimCommandModeInputView extends View
  @content: ->
    @div class: 'command-mode-input', =>
      @div class: 'editor-container', outlet: 'editorContainer', =>
        @subview 'commandModeInputEditor', new EditorView(mini: true)

  initialize: (@motion, opts = {})->
    if opts.class?
      @editorContainer.addClass opts.class

    unless atom.workspaceView?
      # We're in test mode. Don't append to anything, just initialize.
      @focus()
      @handleEvents()
      return

    statusBar = atom.workspaceView.find('.status-bar')

    if statusBar.length > 0
      @.insertBefore(statusBar)
    else
      atom.workspace.getActivePane().append(@)

    @focus()
    @handleEvents()

  handleEvents: ->
    @commandModeInputEditor.on 'core:confirm', @confirm
    @commandModeInputEditor.on 'core:cancel', @remove
    @commandModeInputEditor.find('input').on 'blur', @remove

  confirm: =>
    @value = @commandModeInputEditor.getText()
    @motion.confirm(@)
    @remove()

  focus: =>
    @editorContainer.find('.editor').focus()

  remove: =>
    atom.workspaceView.focus() if atom.workspaceView?
    super()
