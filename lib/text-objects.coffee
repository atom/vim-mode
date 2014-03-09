_ = require 'underscore-plus'
motions = require './motions'

class TextObject extends motions.Motion

class InnerWord extends TextObject
  execute: (count=1) ->
    _.times count, =>
      @editor.moveCursorToBeginningOfWord()

  select: (count=1) ->
    _.times count, =>
      @editor.selectWord()
      true

module.exports = { TextObject, InnerWord }
