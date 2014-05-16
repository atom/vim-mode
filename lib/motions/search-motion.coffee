_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
SearchViewModel = require '../view-models/search-view-model'
{Input} = require '../view-models/view-model'
{$$, Point, Range} = require 'atom'

class SearchBase extends MotionWithInput
  @currentSearch: null
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
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

  execute: (count=1) ->
    @scan()
    @match count, (pos) =>
      @editor.setCursorBufferPosition(pos)

  select: (count=1) ->
    @scan()
    cur = @editor.getCursorBufferPosition()
    @match count, (pos) =>
      @editor.setSelectedBufferRange([cur, pos])
    [true]

  match: (count, callback) ->
    pos = @matches[(count - 1) % @matches.length]
    if pos?
      callback(pos)
    else
      atom.beep()

  scan: ->
    term = @input.characters
    regexp =
      try
        new RegExp(term, 'g')
      catch
        new RegExp(_.escapeRegExp(term), 'g')

    cur = @editor.getCursorBufferPosition()
    matchPoints = []
    iterator = (item) =>
      matchPoints.push(item.range.start)

    @editor.scan(regexp, iterator)

    previous = _.filter matchPoints, (point) =>
      if @reverse
        point.compare(cur) < 0
      else
        point.compare(cur) <= 0

    after = _.difference(matchPoints, previous)
    after.push(previous...)
    after = after.reverse() if @reverse

    @matches = after

class Search extends SearchBase
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    @viewModel = new SearchViewModel(@)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  compose: (input) ->
    super(input)
    @viewModel.value = @input.characters

class SearchCurrentWord extends SearchBase
  @keywordRegex: null
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

    # FIXME: This must depend on the current language
    defaultIsKeyword = "[@a-zA-Z0-9_\-]+"
    userIsKeyword = atom.config.get('vim-mode.iskeyword')
    @keywordRegex = new RegExp(userIsKeyword or defaultIsKeyword)

    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: (onRecursion=false) ->
    cursor = @editor.getCursor()
    wordRange  = cursor.getCurrentWordBufferRange(wordRegex: @keywordRegex)
    characters = @editor.getTextInBufferRange(wordRange)

    # We are not standing on top of a word, let's try to
    # get to the next word and try again
    if characters.length is 0 and not onRecursion
      if @cursorIsOnEOF()
        ""
      else
        cursor.moveToNextWordBoundary(wordRegex: @keywordRegex)
        @getCurrentWord(true)
    else
      characters

  cursorIsOnEOF: ->
    cursor = @editor.getCursor()
    pos = cursor.getMoveNextWordBoundaryBufferPosition(wordRegex: @keywordRegex)
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
  @keywordRegex: null
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

    # FIXME: This must depend on the current language
    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: (onRecursion=false) ->
    cursor = @editor.getCursor()
    tempPoint = cursor.getBufferPosition().toArray()
    @character = @editor.getTextInBufferRange([cursor.getBufferPosition(),new Point(tempPoint[0],tempPoint[1]+1)])
    if @character==']'
      @matching='['
      @reverse=true
    else if @character=='['
      @matching=']'
      @reverse=false
    else if @character==')'
      @matching='('
      @reverse=true
    else if @character=='('
      @matching=')'
      @reverse=false
    else if @character=='}'
      @matching='{'
      @reverse=true
    else if @character=='{'
      @matching='}'
      @reverse=false
    else
      @character = ''
      
    @character

  getCurrentWordMatch: ->
    characters = @getCurrentWord()
    characters

  isComplete: -> true

  searchFor:(character) ->
    term = character
    regexp =
        new RegExp(_.escapeRegExp(term), 'g')

    cur = @editor.getCursorBufferPosition()
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

  select: (count=1) ->
    @scan()
    cur = @editor.getCursorBufferPosition()
    @match count, (pos) =>
      if @reverse
        tempPoint = cur.toArray()
        @editor.setSelectedBufferRange([new Point(tempPoint[0],tempPoint[1]+1), pos.range.start])
      else
        tempPoint = pos.range.start.toArray()
        @editor.setSelectedBufferRange([cur, new Point(tempPoint[0],tempPoint[1]+1)])
    [true]

  scan: ->
    matchesCharacter = @searchFor(@character)
    matchesMatching = @searchFor(@matching)
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
      while counter>0
        if matchIndex < matchesMatching.length and charIndex < matchesCharacter.length
          if matchesCharacter[charIndex].range.compare(matchesMatching[matchIndex].range)==compVal
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


  execute: (count=1) ->
    super(count) if @input.characters.length > 0

module.exports = {Search, SearchCurrentWord,BracketMatchingMotion}
