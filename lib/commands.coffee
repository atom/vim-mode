class Command
  constructor: (@editor) ->
  isComplete: -> true

class DeleteRight extends Command
  execute: ->
    rowLength = @editor.getCursor().getCurrentBufferLine().length
    return if rowLength == 0

    @editor.delete()
    rowLength -= 1

    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorLeft() if column == rowLength

module.exports = { DeleteRight }
