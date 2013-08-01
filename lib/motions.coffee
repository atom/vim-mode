class Motion
  constructor: (@editor) ->
  isComplete: -> true

class MoveLeft extends Motion
  execute: ->
    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorLeft() if column > 0

  select: ->
    {column, row} = @editor.getCursorScreenPosition()

    if column > 0
      @editor.selectLeft()
      true
    else
      false

class MoveRight extends Motion
  execute: ->
    {column, row} = @editor.getCursorScreenPosition()
    lastCharIndex = @editor.getBuffer().lineForRow(row).length - 1
    unless column >= lastCharIndex
      @editor.moveCursorRight()

class MoveUp extends Motion
  execute: ->
    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorUp() if row > 0

class MoveDown extends Motion
  execute: ->
    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorDown() if row < (@editor.getBuffer().getLineCount() - 1)

class MoveToPreviousWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfWord()

  select: ->
    @editor.selectToBeginningOfWord()
    true

class MoveToNextWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfNextWord()

  select: ->
    @editor.selectToBeginningOfNextWord()
    true

class MoveToNextParagraph extends Motion
  execute: ->
    @editor.setCursorScreenPosition(@nextPosition())

  select: ->
    @editor.selectToPosition(@nextPosition())
    true

  nextPosition: ->
    @editor.getCurrentParagraphBufferRange().end

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown, MoveToNextWord, MoveToPreviousWord, MoveToNextParagraph }
