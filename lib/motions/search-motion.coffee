_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
SearchViewModel = require '../view-models/search-view-model'
{$$, Point, Range} = require 'atom'
{Input} = require '../view-models/view-model'

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
        q = pos.start.toArray()
        @editor.setCursorBufferPosition(new Point(q[0],q[1]+pos.matchText.length))
        for i in [0..pos.matchText.length-1]
          @editor.selectLeft()

  select: (count=1) ->
    @scan()
    cur = @editor.getCursorBufferPosition()
    @match count, (pos) =>
      @editor.setSelectedBufferRange([cur, pos.start])
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
      matchPointItem =
        start: item.range.start
        matchText: item.matchText
      matchPoints.push(matchPointItem)

    @editor.scan(regexp, iterator)

    previous2 = _.filter matchPoints, (point) =>
        point.start.compare(cur) <= 0
    if @reverse
      if previous2.length>0
        if previous2[previous2.length-1].start.compare(cur)<0
          previous = previous2[..]
        else
          if previous2.length > 1
            previous = previous2[0..previous2.length-2]
          else
            previous = []
      else
        previous2 = []
    else
        previous = previous2[..]

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

module.exports = {Search, SearchCurrentWord}
