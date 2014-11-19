{Operator} = require './general-operators'
#
# It indents everything selected by the following motion.
#
class Indent extends Operator
  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count)

  # Protected: Indents or outdents the text selected by the given motion.
  #
  # count  - The number of times to execute.
  # direction - Either 'indent' or 'outdent'
  #
  # Returns nothing.
  indent: (count, direction='indent') ->
    mode = @vimState.mode

    @motion.select(count)
    {start} = @editor.getSelectedBufferRange()
    if direction == 'indent'
      @editor.indentSelectedRows()
    else if direction == 'outdent'
      @editor.outdentSelectedRows()
    else if direction == 'auto'
      @editor.autoIndentSelectedRows()

    if mode != 'visual'
      @editor.setCursorScreenPosition([start.row, 0])
      @editor.moveToFirstCharacterOfLine()
      @vimState.activateCommandMode()

#
# It outdents everything selected by the following motion.
#
class Outdent extends Indent
  # Public: Indents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count, 'outdent')

#
# It autoindents everything selected by the following motion.
#
class Autoindent extends Indent
  # Public: Autoindents the text selected by the given motion.
  #
  # count - The number of times to execute.
  #
  # Returns nothing.
  execute: (count=1) ->
    @indent(count, 'auto')

module.exports = {Indent, Outdent, Autoindent}
