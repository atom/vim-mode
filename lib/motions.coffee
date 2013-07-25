class Motion
  constructor: (@editor) ->
  isComplete: -> true

class MoveLeft extends Motion
  execute: ->
    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorLeft() if column > 0

class MoveRight extends Motion
  execute: ->
    # FIXME: Don't run off the end
    {column, row} = @editor.getCursorScreenPosition()
    @editor.moveCursorRight()

class MoveUp extends Motion
  execute: ->
    @editor.moveCursorUp()

class MoveDown extends Motion
  execute: ->
    @editor.moveCursorDown()

class MoveToPreviousWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfWord()

  select: ->
    @editor.selectToBeginningOfWord()

class MoveToNextWord extends Motion
  execute: ->
    @editor.moveCursorToBeginningOfNextWord()

  select: ->
    @editor.selectToBeginningOfNextWord()

class MoveToNextParagraph extends Motion
  execute: ->
    @editor.setCursorScreenPosition(@nextPosition())

  select: ->
    @editor.selectToPosition(@nextPosition())

  nextPosition: ->
    @editor.getCurrentParagraphBufferRange().end

module.exports = { Motion, MoveLeft, MoveRight, MoveUp, MoveDown, MoveToNextWord, MoveToPreviousWord, MoveToNextParagraph }
