copyCharacterFromAbove = (editor, vimState) ->
  editor.transact ->
    for cursor in editor.getCursors()
      {row, column} = cursor.getScreenPosition()
      continue if row is 0
      range = [[row-1, column], [row-1, column+1]]
      cursor.selection.insertText(editor.getTextInBufferRange(editor.bufferRangeForScreenRange(range)))

copyCharacterFromBelow = (editor, vimState) ->
  editor.transact ->
    for cursor in editor.getCursors()
      {row, column} = cursor.getScreenPosition()
      range = [[row+1, column], [row+1, column+1]]
      cursor.selection.insertText(editor.getTextInBufferRange(editor.bufferRangeForScreenRange(range)))

module.exports = {
  copyCharacterFromAbove,
  copyCharacterFromBelow
}
