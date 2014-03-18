_ = require 'underscore-plus'
{$$, Point, Range} = require 'atom'
SearchViewModel = require './search-view-model'

class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

class SelectInsideWord extends TextObject
  select: ->
    @editor.selectWord()
    [true]

module.exports = {TextObject, SelectInsideWord}
