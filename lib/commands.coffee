_ = require 'underscore-plus'

class Command
  constructor: (@editor, @vimState) ->
  isComplete: -> true
  isRecordable: -> false

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
    @editor.getCursor().skipLeadingWhitespace()

class InsertBelowWithNewline extends Command
  execute: (count=1) ->
    @vimState.activateInsertMode()
    @editor.insertNewlineBelow()
    @editor.getCursor().skipLeadingWhitespace()

class Substitute extends Command
  execute: (count=1) ->
    _.times count, =>
      @editor.selectRight()
    @editor.delete()
    @vimState.activateInsertMode()

class SubstituteLine extends Command
  execute: (count=1) ->
    @editor.moveCursorToBeginningOfLine()
    _.times count, =>
      @editor.selectDown()
    @editor.delete()
    @editor.insertNewline()
    @editor.moveCursorUp()
    @vimState.activateInsertMode()

module.exports = { Insert, InsertAfter, InsertAboveWithNewline, InsertBelowWithNewline,
  Substitute, SubstituteLine }
