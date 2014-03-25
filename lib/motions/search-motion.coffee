_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
SearchViewModel = require '../view-models/search-view-model'

module.exports =
class Search extends MotionWithInput
  @currentSearch: null
  constructor: (@editorView, @vimState) ->
    super(@editorView, @vimState)
    @viewModel = new SearchViewModel(@)
    Search.currentSearch = @
    @reverse = @initiallyReversed = false

  compose: (input) ->
    super(input)
    @viewModel.value = @input.characters

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
