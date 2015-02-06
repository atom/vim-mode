{Operator} = require './general-operators'

class AdjustIndentation extends Operator
  execute: (count=1) ->
    mode = @vimState.mode
    @motion.select(count)
    {start} = @editor.getSelectedBufferRange()

    @indent()

    if mode isnt 'visual'
      @editor.setCursorBufferPosition([start.row, 0])
      @editor.moveToFirstCharacterOfLine()
      @vimState.activateCommandMode()

class Indent extends AdjustIndentation
  indent: ->
    @editor.indentSelectedRows()

class Outdent extends AdjustIndentation
  indent: ->
    @editor.outdentSelectedRows()

class Autoindent extends AdjustIndentation
  indent: ->
    @editor.autoIndentSelectedRows()

module.exports = {Indent, Outdent, Autoindent}
