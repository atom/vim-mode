{View, EditorView} = require 'atom'

module.exports =

class VimCommandModeInputView extends View
  @content: ->
    @div class: 'command-mode-input', =>
      @div class: 'editor-container', outlet: 'editorContainer', =>
        @subview 'editor', new EditorView(mini: true)

  initialize: (@viewModel, opts = {})->
    @editor.setFontSize(atom.config.get('vim-mode.commandModeInputViewFontSize'))

    if opts.class?
      @editorContainer.addClass opts.class

    if opts.hidden?
      @editorContainer.addClass 'hidden-input'

    if opts.singleChar?
      @singleChar = true

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
    if @singleChar?
      @editor.find('input').on 'textInput', @autosubmit
    @editor.on 'core:confirm', @confirm
    @editor.on 'core:cancel', @cancel
    @editor.find('input').on 'blur', @cancel

  stopHandlingEvents: ->
    if @singleChar?
      @editor.find('input').off 'textInput', @autosubmit
    @editor.off 'core:confirm', @confirm
    @editor.off 'core:cancel', @cancel
    @editor.find('input').off 'blur', @cancel

  autosubmit: (event) =>
    @editor.setText(event.originalEvent.data)
    @confirm()

  confirm: =>
    @value = @editor.getText()
    @viewModel.confirm(@)
    @remove()

  focus: =>
    @editorContainer.find('.editor').focus()

  cancel: (e) =>
    @viewModel.cancel(@)
    @remove()

  remove: =>
    @stopHandlingEvents()
    atom.workspaceView.focus() if atom.workspaceView?
    super()
