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
    @vimState.activateCommandMode()

  # Protected: Indents or outdents the text selected by the given motion.
  #
  # count  - The number of times to execute.
  # direction - Either 'indent' or 'outdent'
  #
  # Returns nothing.
  indent: (count, direction='indent') ->
    row = @editor.getCursorScreenRow()

    @motion.select(count)
    if direction == 'indent'
      @editor.indentSelectedRows()
    else if direction == 'outdent'
      @editor.outdentSelectedRows()
    else if direction == 'auto'
      @editor.autoIndentSelectedRows()

    @editor.setCursorScreenPosition([row, 0])
    @editor.moveCursorToFirstCharacterOfLine()

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
    @vimState.activateCommandMode()

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
    @vimState.activateCommandMode()

module.exports = {Indent, Outdent, Autoindent}
