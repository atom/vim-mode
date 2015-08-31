_ = require 'underscore-plus'
{Operator} = require './general-operators'

class AdjustIndentation extends Operator
  execute: (count) ->
    mode = @vimState.mode
    @motion.select(count)
    originalRanges = @editor.getSelectedBufferRanges()

    if mode is 'visual'
      @editor.transact =>
        _.times(count ? 1, => @indent())
    else
      @indent()

    @editor.clearSelections()
    @editor.getLastCursor().setBufferPosition([originalRanges.shift().start.row, 0])
    for range in originalRanges
      @editor.addCursorAtBufferPosition([range.start.row, 0])
    @editor.moveToFirstCharacterOfLine()
    @vimState.activateNormalMode()

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
