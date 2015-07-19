_ = require 'underscore-plus'
fs = require 'fs-plus'
path = require 'path'
settings = require './settings'

getSearchTerm = (term, modifiers = {'g': true}) ->

  escaped = false
  hasc = false
  hasC = false
  term_ = term
  term = ''
  for char in term_
    if char is '\\' and not escaped
      escaped = true
      term += char
    else
      if char is 'c' and escaped
        hasc = true
        term = term[...-1]
      else if char is 'C' and escaped
        hasC = true
        term = term[...-1]
      else if char isnt '\\'
        term += char
      escaped = false

  if hasC
    modifiers['i'] = false
  if (not hasC and not term.match('[A-Z]') and \
      settings.useSmartcaseForSearch()) or hasc
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

  # Public: Scans an editor for occurences of a term relative to a position
  #
  # term     - The string to find
  # editor   - The editor to scan
  # position - The position before/after which to scan
  # reverse  - Whether or not to search in reverse (default: false)
  #
  # Returns an array of ranges of all occurences of `term` in `editor`.
  #  The array is sorted so that the first occurences after the cursor come
  #  first (and the search wraps around). If `reverse` is true, the array is
  #  reversed so that the first occurence before the cursor comes first.
  scanEditor: (term, editor, position, reverse = false) ->
    [rangesBefore, rangesAfter] = [[], []]
    editor.scan getSearchTerm(term), ({range}) ->
      isBefore = if reverse
        range.start.compare(position) < 0
      else
        range.start.compare(position) <= 0

      if isBefore
        rangesBefore.push(range)
      else
        rangesAfter.push(range)

    if reverse
      rangesAfter.concat(rangesBefore).reverse()
    else
      rangesAfter.concat(rangesBefore)

  # Public: Save the given editor's contents at a given path
  #
  # filePath - The path to save the file at
  # editor - The TextEditor of which to save the text
  saveAs: (filePath, editor) ->
    fs.writeFileSync(filePath, editor.getText())

  # Public: Get the full path for a given relative path, expanding `~` to the
  #  home directory and using the first project path as root path for relative
  #  paths
  #
  # filePath - The relative path to expand
  #
  # Returns the expanded path
  getFullPath: (filePath) ->
    filePath = fs.normalize(filePath)
    return filePath if path.isAbsolute(filePath)
    return path.join(atom.project.getPaths()[0], filePath)

  # Public: Replace vim style capturing groups (\1, \2 etc.) with the matched
  #  groups
  #
  # groups - An Array of the matched groups
  # string - The string containing \1, \2 etc.
  #
  # Returns `string` with all capturing groups replaced by the corresponding
  #  entry in `groups` (or '' if there is no corresponding entry)
  replaceGroups: (groups, string) ->
    replaced = ''
    escaped = false
    while (char = string[0])?
      string = string[1..]
      if char is '\\' and not escaped
        escaped = true
      else if /\d/.test(char) and escaped
        console.debug "replacing group #{char}"
        escaped = false
        group = groups[parseInt(char)]
        group ?= ''
        replaced += group
      else
        escaped = false
        replaced += char

    replaced

  # Public: Makes a RegExp from a term. Respects the Smartcase setting and \c
  #
  # term - The string to make a RegExp from
  #
  # Returns a RegExp with the appropriate modifiers
  getSearchTerm: getSearchTerm
