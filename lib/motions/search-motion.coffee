_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
SearchViewModel = require '../view-models/search-view-model'
{Input} = require '../view-models/view-model'

class BasicSearch extends MotionWithInput
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


class Search extends BasicSearch
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    @viewModel = new SearchViewModel(@)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  compose: (input) ->
    super(input)
    @viewModel.value = @input.characters

class SearchCurrentWord extends BasicSearch
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false
    @input = new Input(@getCurrentWordMatch())

  getCurrentWord: ->
    wordRange  = @editor.getCursor().getCurrentWordBufferRange()
    @editor.getTextInBufferRange(wordRange)

  getCurrentWordMatch: ->
    characters = @getCurrentWord()
    if /\W/.test(characters) then "#{characters}\\b" else "\\b#{characters}\\b"

  isOnWord: ->
    @getCurrentWord().length isnt 0

  isComplete: -> true

  execute: (count=1) ->
    super(count) if @isOnWord()


module.exports = {Search, SearchCurrentWord}
