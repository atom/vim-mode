{Operator} = require './general-operators'
{Range} = require 'atom'
settings = require '../settings'

#
# It increases or decreases the next number on the line
#
class Increase extends Operator
  step: 1

  constructor: ->
    super
    @complete = true
    @numberRegex = new RegExp(settings.numberRegex())

  execute: (count=1) ->
    @editor.transact =>
      increased = false
      for cursor in @editor.getCursors()
        if @increaseNumber(count, cursor) then increased = true
      atom.beep() unless increased

  increaseNumber: (count, cursor) ->
    # find position of current number, adapted from from SearchCurrentWord
    cursorPosition = cursor.getBufferPosition()
    numEnd = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowNext: false)

    if numEnd.column is cursorPosition.column
      # either we don't have a current number, or it ends on cursor, i.e. precedes it, so look for the next one
      numEnd = cursor.getEndOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowNext: true)
      return if numEnd.row isnt cursorPosition.row # don't look beyond the current line
      return if numEnd.column is cursorPosition.column # no number after cursor

    cursor.setBufferPosition numEnd
    numStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: @numberRegex, allowPrevious: false)

    range = new Range(numStart, numEnd)

    # parse number, increase/decrease
    number = parseInt(@editor.getTextInBufferRange(range), 10)
    if isNaN(number)
      cursor.setBufferPosition(cursorPosition)
      return

    number += @step*count

    # replace current number with new
    newValue = String(number)
    @editor.setTextInBufferRange(range, newValue, normalizeLineEndings: false)

    cursor.setBufferPosition(row: numStart.row, column: numStart.column-1+newValue.length)
    return true

class Decrease extends Increase
  step: -1

module.exports = {Increase, Decrease}
