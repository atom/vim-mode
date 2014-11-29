{View, TextEditorView} = require 'atom'

module.exports =
class VimCommandModeInputView extends View
  @content: ->
    @div class: 'command-mode-input', =>
      @div class: 'editor-container', outlet: 'editorContainer', =>
        @subview 'editor', new TextEditorView(mini: true)

  initialize: (@viewModel, opts = {})->
    if opts.class?
      @editorContainer.addClass opts.class

    if opts.hidden
      @editorContainer.addClass 'hidden-input'

    @singleChar = opts.singleChar
    @defaultText = opts.defaultText ? ''

    @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

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
    @value = @editor.getText() or @defaultText
    @viewModel.confirm(@)
    @remove()

  focus: =>
    @editorContainer.find('.editor').focus()

  cancel: (e) =>
    @viewModel.cancel(@)
    @remove()

  remove: =>
    @stopHandlingEvents()
    atom.workspace.getActivePane().activate()
    @panel.destroy()
