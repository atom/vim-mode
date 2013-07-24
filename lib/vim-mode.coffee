VimState = require './vim-state'

module.exports =

  activate: (state) ->
    @vimState = new VimState()
    @enabled = config.get("vim.enabled") == true
    @enableVim() if @enabled
    rootView.command "vim:toggle", =>
      @enabled = !@enabled
      config.set("vim.enabled", @enabled)
      if @enabled then @enableVim() else @disableVim()

  deactivate: ->
    @disableVim()

  serialize: ->
    vimModeViewState: @vimModeView.serialize


  @enableVim: ->
    rootView.eachEditor (editor) =>
      @appendToEditorPane(rootView, editor) if editor.attached

  @disableVim: ->
    rootView.eachEditor (editor) =>
      editor.getPane()?.find(".vim").remove()


  @appendToEditorPane: (rootView, editor) ->
    editor.addClass("vim-mode")

    if pane = editor.getPane()
      view = new VimState(editor)
