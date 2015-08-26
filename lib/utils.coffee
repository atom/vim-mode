{Range} = require 'atom'

module.exports =
  # Public: Determines if a string should be considered linewise or character
  #
  # text - The string to consider
  #
  # Returns 'linewise' if the string ends with a line return and 'character'
  #  otherwise.
  copyType: (text) ->
    if text.lastIndexOf("\n") is text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") is text.length - 1
      'linewise'
    else
      'character'

  # Public: return a union of two ranges, or simply the newRange if the oldRange is empty.
  #
  # Returns a Range
  mergeRanges: (oldRange, newRange) ->
    oldRange = Range.fromObject oldRange
    newRange = Range.fromObject newRange
    if oldRange.isEmpty()
      newRange
    else
      oldRange.union(newRange)
