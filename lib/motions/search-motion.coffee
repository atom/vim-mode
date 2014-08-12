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
      @editor.setCursorBufferPosition(pos.range.start)

  select: (count=1) ->
    @scan()
    selectionStart = @getSelectionStart()
    @match count, (pos) =>
      reversed = selectionStart.compare(pos.range.start) > 0
      @editor.setSelectedBufferRange([selectionStart, pos.range.start], {reversed})
    [true]

  getSelectionStart: ->
    cur = @editor.getCursorBufferPosition()
    {start, end} = @editor.getSelectedBufferRange()
    if start.compare(cur) is 0 then end else start

  match: (count, callback) ->
    pos = @matches[(count - 1) % @matches.length]
    if pos?
      callback(pos)
    else
      atom.beep()

  scan: ->
    term = @input.characters
    mod = 'g'
    if term.indexOf('\\c') != -1
      term = term.replace('\\c','')
      mod += 'i'
    regexp =
      try
        new RegExp(term, mod)
      catch
        new RegExp(_.escapeRegExp(term), mod)

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
    @characters         = [')','(','}','{',']','[']
    @charactersMatching = ['(',')','{','}','[',']']
    @reverseSearch      = [true,false,true,false,true,false]

    # FIXME: This must depend on the current language
    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: (onRecursion=false) ->
    cursor = @editor.getCursor()
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

    cur = if @startUp then @startUpPos else @editor.getCursorBufferPosition()

    @match count, (pos) =>
      if @reverse
        tempPoint = cur.toArray()
        @editor.setSelectedBufferRange([pos.range.start, new Point(tempPoint[0],tempPoint[1] + 1)], {reversed: true})
      else
        tempPoint = pos.range.start.toArray()
        @editor.setSelectedBufferRange([ cur, new Point(tempPoint[0],tempPoint[1] + 1)], {reversed: true})
    [true]

  scan: ->
    if @startUp
      @startUpPos = @editor.getCursorBufferPosition()
      min = -1
      iwin = -1
      for i in [0..@characters.length - 1]
        matchesCharacter = @searchFor(@characters[i])
        if matchesCharacter.length > 0
          dst = matchesCharacter[0].range.start.toArray()
          if @startUpPos.toArray()[0] == dst[0] and @startUpPos.toArray()[1] < dst[1]
            if dst[1] < min or min == -1
              line = dst[0]
              min = dst[1]
              iwin = i
      if iwin != -1
        @editor.setCursorBufferPosition(new Point(line,min))
        @character = @characters[iwin]
        @matching = @charactersMatching[iwin]
        @reverse = @reverseSearch[iwin]

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
      @editor.setCursorBufferPosition(@startUpPos)



  execute: (count=1) ->
    super(count) if @input.characters.length > 0

module.exports = {Search, SearchCurrentWord,BracketMatchingMotion}
