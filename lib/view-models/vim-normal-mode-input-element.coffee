class VimNormalModeInputElement extends HTMLDivElement
  createdCallback: ->
    @className = "normal-mode-input"

  initialize: (@viewModel, @mainEditorElement, opts = {}) ->
    if opts.class?
      @classList.add(opts.class)

    @editorElement = document.createElement "atom-text-editor"
    @editorElement.classList.add('editor')
    @editorElement.getModel().setMini(true)
    @editorElement.setAttribute('mini', '')
    @appendChild(@editorElement)

    @singleChar = opts.singleChar
    @defaultText = opts.defaultText ? ''

    if opts.hidden
      @classList.add('vim-hidden-normal-mode-input')
      @mainEditorElement.parentNode.appendChild(this)
    else
      @panel = atom.workspace.addBottomPanel(item: this, priority: 100)

    @focus()
    @handleEvents()

    this

  handleEvents: ->
    if @singleChar?
      compositing = false
      @editorElement.getModel().getBuffer().onDidChange (e) =>
        @confirm() if e.newText and not compositing
      @editorElement.addEventListener 'compositionstart', -> compositing = true
      @editorElement.addEventListener 'compositionend', -> compositing = false
    else
      atom.commands.add(@editorElement, 'editor:newline', @confirm.bind(this))
      atom.commands.add(@editorElement, 'core:backspace', @backspace.bind(this))

    atom.commands.add(@editorElement, 'core:confirm', @confirm.bind(this))
    atom.commands.add(@editorElement, 'core:cancel', @cancel.bind(this))
    atom.commands.add(@editorElement, 'blur', @cancel.bind(this))

  backspace: ->
    # pressing backspace over empty `/` should cancel search
    @cancel() unless @editorElement.getModel().getText().length

  confirm: ->
    @value = @editorElement.getModel().getText() or @defaultText
    @viewModel.confirm(this)
    @removePanel()

  focus: ->
    @editorElement.focus()

  cancel: (e) ->
    @viewModel.cancel(this)
    @removePanel()

  removePanel: ->
    atom.workspace.getActivePane().activate()
    if @panel?
      @panel.destroy()
    else
      this.remove()

module.exports =
document.registerElement("vim-normal-mode-input"
  extends: "div",
  prototype: VimNormalModeInputElement.prototype
)
