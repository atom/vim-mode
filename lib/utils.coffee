settings = require './settings'
_ = require 'underscore-plus'

getSearchTerm = (term) ->
  modifiers = {'g': true}

  if not term.match('[A-Z]') and settings.useSmartcaseForSearch()
    modifiers['i'] = true

  if term.indexOf('\\c') >= 0
    term = term.replace('\\c', '')
    modifiers['i'] = true

  modFlags = Object.keys(modifiers).filter((key) -> modifiers[key]).join('')

  try
    new RegExp(term, modFlags)
  catch
    new RegExp(_.escapeRegExp(term), modFlags)

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

  # Public: Scans an editor for occurences of a term relative to a cursor
  #
  # term    - The string to find
  # editor  - The editor to scan
  # cursor  - The cursor before/after which to scan
  # reverse - Whether or not to search in reverse (default: false)
  #
  # Returns an array of ranges of all occurences of `term` in `editor`.
  #  The array is sorted so that the first occurences after the cursor come
  #  first (and the search wraps around). If `reverse` is true, the array is
  #  reversed so that the first occurence before the cursor comes first.
  scanEditor: (term, editor, cursor, reverse = false) ->
    currentPosition = cursor.getBufferPosition()

    [rangesBefore, rangesAfter] = [[], []]
    editor.scan getSearchTerm(term), ({range}) ->
      isBefore = if reverse
        range.start.compare(currentPosition) < 0
      else
        range.start.compare(currentPosition) <= 0

      if isBefore
        rangesBefore.push(range)
      else
        rangesAfter.push(range)

    if reverse
      rangesAfter.concat(rangesBefore).reverse()
    else
      rangesAfter.concat(rangesBefore)

  # Public: Makes a RegExp from a term. Respects the Smartcase setting and \c
  #
  # term - The string to make a RegExp from
  #
  # Returns a RegExp with the appropriate modifiers
  getSearchTerm: getSearchTerm
