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
    @prefixChar = opts.prefixChar ? ''

    @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

    @focus()
    @handleEvents()
    @editor.setText @prefixChar

  handleEvents: ->
    if @singleChar?
      @editor.find('input').on 'textInput', @autosubmit
    if @prefixChar != ''
      @editor.find('input').on 'keyup', @checkPrefix
    @editor.on 'core:confirm', @confirm
    @editor.on 'core:cancel', @cancel
    @editor.find('input').on 'blur', @cancel

  stopHandlingEvents: ->
    if @singleChar?
      @editor.find('input').off 'textInput', @autosubmit
    if @prefixChar != ''
      @editor.find('input').off 'keyup', @checkPrefix
    @editor.off 'core:confirm', @confirm
    @editor.off 'core:cancel', @cancel
    @editor.find('input').off 'blur', @cancel

  autosubmit: (event) =>
    @editor.setText(event.originalEvent.data)
    @confirm()

  checkPrefix: =>
    text = @editor.getText()
    if text.length < 1 || text[0] != @prefixChar
      @cancel()

  confirm: =>
    text = @editor.getText()
    if @prefixChar != '' && !(text && text.length > 0 && text[0] == @prefixChar)
      @cancel()
    else
      @value = if text == @prefixChar then @defaultText else if @prefixChar == '' then text else text.substr(1)
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
