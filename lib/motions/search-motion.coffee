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
    @scan(cursor)
    @match count, (pos) =>
      cursor.setBufferPosition(pos.range.start)

  match: (count, callback) ->
    pos = @matches[(count - 1) % @matches.length]
    if pos?
      callback(pos)
    else
      atom.beep()

  scan: (cursor) ->
    addToMod = (modifier) =>
      if mod.indexOf(modifier) == -1
        return mod += modifier
      else return
    term = @input.characters
    mod = ''
    addToMod('g')
    usingSmartcase = atom.config.get 'vim-mode.useSmartcaseForSearch'
    if usingSmartcase && !term.match('[A-Z]')
      addToMod('i')
    if term.indexOf('\\c') != -1
      term = term.replace('\\c','')
      addToMod('i')
    regexp =
      try
        new RegExp(term, mod)
      catch
        new RegExp(_.escapeRegExp(term), mod)

    cur = cursor.getBufferPosition()
    matchPoints = []
    iterator = (item) =>
      matchPointItem =
        range: item.range
      matchPoints.push(matchPointItem)

    @editor.scan(regexp, iterator)

    previous = _.filter matchPoints, (point) =>
      if @reverse
        point.range.start.compare(cur) < 0
      else
        point.range.start.compare(cur) <= 0

    after = _.difference(matchPoints, previous)
    after.push(previous...)
    after = after.reverse() if @reverse

    @matches = after

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

class BracketMatchingMotion extends SearchBase
  operatesInclusively: true
  @keywordRegex: null

  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false
    @characters         = [')','(','}','{',']','[']
    @charactersMatching = ['(',')','{','}','[',']']
    @reverseSearch      = [true,false,true,false,true,false]

    # FIXME: This must depend on the current language
    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: (onRecursion=false) ->
    cursor = @editor.getLastCursor()
    tempPoint = cursor.getBufferPosition().toArray()
    @character = @editor.getTextInBufferRange([cursor.getBufferPosition(),new Point(tempPoint[0],tempPoint[1] + 1)])
    @startUp = false;
    index = @characters.indexOf(@character)
    if index >= 0
      @matching = @charactersMatching[index]
      @reverse = @reverseSearch[index]
    else
      @startUp = true

    @character

  getCurrentWordMatch: ->
    characters = @getCurrentWord()
    characters

  isComplete: -> true

  searchFor: (cursor, character) ->
    term = character
    regexp =
        new RegExp(_.escapeRegExp(term), 'g')

    cur = cursor.getBufferPosition()
    matchPoints = []
    iterator = (item) =>
      matchPointItem =
        range: item.range
      matchPoints.push(matchPointItem)

    @editor.scan(regexp, iterator)

    previous = _.filter matchPoints, (point) =>
      if @reverse
        point.range.start.compare(cur) < 0
      else
        point.range.start.compare(cur) <= 0

    if @reverse
      after = []
      after.push(previous...)
      after = after.reverse()
    else
      after = _.difference(matchPoints, previous)

    matches = after
    matches

  scan: (cursor) ->
    if @startUp
      @startUpPos = cursor.getBufferPosition()
      min = -1
      iwin = -1
      for i in [0..@characters.length - 1]
        matchesCharacter = @searchFor(cursor, @characters[i])
        if matchesCharacter.length > 0
          dst = matchesCharacter[0].range.start.toArray()
          if @startUpPos.toArray()[0] == dst[0] and @startUpPos.toArray()[1] < dst[1]
            if dst[1] < min or min == -1
              line = dst[0]
              min = dst[1]
              iwin = i
      if iwin != -1
        cursor.setBufferPosition(new Point(line,min))
        @character = @characters[iwin]
        @matching = @charactersMatching[iwin]
        @reverse = @reverseSearch[iwin]

    matchesCharacter = @searchFor(cursor, @character)
    matchesMatching = @searchFor(cursor, @matching)
    if matchesMatching.length == 0
      @matches = []
    else
      charIndex = 0;
      matchIndex = 0;
      counter = 1;
      winner = -1
      if @reverse
        compVal = 1
      else
        compVal = -1
      while counter > 0
        if matchIndex < matchesMatching.length and charIndex < matchesCharacter.length
          if matchesCharacter[charIndex].range.compare(matchesMatching[matchIndex].range) == compVal
            counter = counter + 1
            charIndex = charIndex + 1
          else
            counter = counter - 1
            winner = matchIndex
            matchIndex = matchIndex + 1
        else if matchIndex < matchesMatching.length
          counter = counter - 1
          winner = matchIndex
          matchIndex = matchIndex + 1
        else
          break

      retVal = []
      if counter == 0
        retVal.push(matchesMatching[winner])
      @matches = retVal

    if @matches.length == 0 and @startUp
      cursor.setBufferPosition(@startUpPos)

  execute: (count=1) ->
    super(count) if @input.characters.length > 0

module.exports = {Search, SearchCurrentWord,BracketMatchingMotion}
