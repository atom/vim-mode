_ = require 'underscore'

class Command
  constructor: (@editor, @vimState) ->
  isComplete: -> true

class Insert extends Command
  execute: (count=1) ->
    @vimState.activateInsertMode()

class InsertAfter extends Command
  execute: (count=1) ->
    @vimState.activateInsertMode()
    @editor.moveCursorRight() unless @editor.getCursor().isAtEndOfLine()

class InsertAboveWithNewline extends Command
  execute: (count=1) ->
    @vimState.activateInsertMode()
    @editor.insertNewlineAbove()
    @editor.moveCursorUp()
    @editor.moveCursorToBeginningOfLine()

module.exports = { Insert, InsertAfter, InsertAboveWithNewline }
