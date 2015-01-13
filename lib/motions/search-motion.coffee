_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
SearchViewModel = require '../view-models/search-view-model'
{Input} = require '../view-models/view-model'
{Point, Range} = require 'atom'

class SearchBase extends MotionWithInput
  operatesInclusively: false
  @currentSearch: null

  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  repeat: (opts = {}) =>
    reverse = opts.backwards
    if @initiallyReversed and reverse
      @reverse = false
    else
      @reverse = reverse or @initiallyReversed
    @

  reversed: =>
    @initiallyReversed = @reverse = true
    @

  moveCursor: (cursor, count=1) ->
    ranges = @scan(cursor)
    if ranges.length > 0
      range = ranges[(count - 1) % ranges.length]
      cursor.setBufferPosition(range.start)
    else
      atom.beep()

  scan: (cursor) ->
    currentPosition = cursor.getBufferPosition()

    [rangesBefore, rangesAfter] = [[], []]
    @editor.scan @getSearchTerm(@input.characters), ({range}) =>
      isBefore = if @reverse
        range.start.compare(currentPosition) < 0
      else
        range.start.compare(currentPosition) <= 0

      if isBefore
        rangesBefore.push(range)
      else
        rangesAfter.push(range)

    if @reverse
      rangesAfter.concat(rangesBefore).reverse()
    else
      rangesAfter.concat(rangesBefore)

  getSearchTerm: (term) ->
    modifiers = {'g': true}

    if not term.match('[A-Z]') and atom.config.get('vim-mode.useSmartcaseForSearch')
      modifiers['i'] = true

    if term.indexOf('\\c') >= 0
      term = term.replace('\\c', '')
      modifiers['i'] = true

    modFlags = Object.keys(modifiers).join('')

    try
      new RegExp(term, modFlags)
    catch
      new RegExp(_.escapeRegExp(term), modFlags)

class Search extends SearchBase
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @viewModel = new SearchViewModel(@)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  compose: (input) ->
    super(input)
    @viewModel.value = @input.characters

class SearchCurrentWord extends SearchBase
  @keywordRegex: null

  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

    # FIXME: This must depend on the current language
    defaultIsKeyword = "[@a-zA-Z0-9_\-]+"
    userIsKeyword = atom.config.get('vim-mode.iskeyword')
    @keywordRegex = new RegExp(userIsKeyword or defaultIsKeyword)

    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: (onRecursion=false) ->
    cursor = @editor.getLastCursor()
    wordRange  = cursor.getCurrentWordBufferRange(wordRegex: @keywordRegex)
    characters = @editor.getTextInBufferRange(wordRange)

    # We are not standing on top of a word, let's try to
    # get to the next word and try again
    if characters.length is 0 and not onRecursion
      if @cursorIsOnEOF(cursor)
        ""
      else
        cursor.moveToNextWordBoundary(wordRegex: @keywordRegex)
        @getCurrentWord(true)
    else
      characters

  cursorIsOnEOF: (cursor) ->
    pos = cursor.getNextWordBoundaryBufferPosition(wordRegex: @keywordRegex)
    eofPos = @editor.getEofBufferPosition()
    pos.row == eofPos.row && pos.column == eofPos.column

  getCurrentWordMatch: ->
    characters = @getCurrentWord()
    if characters.length > 0
      if /\W/.test(characters) then "#{characters}\\b" else "\\b#{characters}\\b"
    else
      characters

  isComplete: -> true

  execute: (count=1) ->
    super(count) if @input.characters.length > 0

OpenBrackets = ['(', '{', '[']
CloseBrackets = [')', '}', ']']
AnyBracket = new RegExp(OpenBrackets.concat(CloseBrackets).map(_.escapeRegExp).join("|"))

class BracketMatchingMotion extends SearchBase
  operatesInclusively: true
  @keywordRegex: null

  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  isComplete: -> true

  searchOnLine: (startPosition, reverse, inCharacter, outCharacter) ->
    if reverse
      endColumn = 0
      increment = -1
    else
      endColumn = @editor.lineLengthForBufferRow(startPosition.row)
      increment = 1

    depth = 0
    {row, column} = startPosition
    loop
      point = new Point(row, column)
      character = @characterAt(new Point(row, column))
      depth++ if character is inCharacter
      depth-- if character is outCharacter
      return point if depth is 0
      return null if column is endColumn
      column += increment

  characterAt: (position) ->
    @editor.getTextInBufferRange([position, position.add([0, 1])])

  getSearchData: (position) ->
    character = @characterAt(position)
    if (index = OpenBrackets.indexOf(character)) >= 0
      [character, CloseBrackets[index], false]
    else if (index = CloseBrackets.indexOf(character)) >= 0
      [character, OpenBrackets[index], true]
    else
      []

  moveCursor: (cursor) ->
    startPosition = cursor.getBufferPosition()

    [inCharacter, outCharacter, reverse] = @getSearchData(startPosition)

    unless inCharacter?
      restOfLine = [startPosition, [startPosition.row, Infinity]]
      @editor.scanInBufferRange AnyBracket, restOfLine, ({range, stop}) ->
        startPosition = range.start
        stop()

    [inCharacter, outCharacter, reverse] = @getSearchData(startPosition)

    return unless inCharacter?

    if matchPosition = @searchOnLine(startPosition, reverse, inCharacter, outCharacter)
      cursor.setBufferPosition(matchPosition)

module.exports = {Search, SearchCurrentWord,BracketMatchingMotion}
