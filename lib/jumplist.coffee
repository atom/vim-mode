
module.exports =
class JumpList
  constructor: (@maxEntries = 100) ->
    @list = []
    @pointer = -1
    @pending = false

  addJump: (editor) ->
    @list.splice(@pointer, 1) unless @pointer == -1
    entry = new JumpListEntry(editor)
    @list.unshift entry unless entry.isEqual(@list[0])
    @list.splice(0, @maxEntries) if @list.length > @maxEntries
    @pointer = -1

  moveToOlderPos: (editor, count=1) ->
    return if @pending
    if @pointer == -1
      @addJump editor
      @pointer = 0
    @_moveToPos editor, count

  moveToNewerPos: (editor, count=1) ->
    return if @pending
    @_moveToPos editor, -count

  _moveToPos: (editor, inc) ->
    dst = @pointer+inc
    if dst < 0
      dst = 0
    if dst >= @list.length
      dst = @list.length-1
    if dst != @pointer
      @pending = true
      @list[dst].restoreCursor editor, (err, dstEditor) =>
        @pointer = dst
        @pending = false


class JumpListEntry
  constructor: (editor) ->
    {@row, @column} = editor.getCursorBufferPosition()
    @uri = editor.getUri()

  isEqual: (o) ->
    o &&
    o.row == @row &&
    o.column == @column &&
    o.uri == @uri

  restoreCursor: (editor, cb) ->
    if editor.getUri() == @uri
      editor.setCursorBufferPosition [@row, @column]
      cb?(null, editor)
    else
      atom.workspace.open(@uri, {
        initialLine: @row,
        initialColumn: @column
      }).nodeify cb
