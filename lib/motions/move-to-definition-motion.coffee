{Motion, MoveToFirstCharacterOfLine} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Point, Range} = require 'atom'
{SearchCurrentWord} = require './search-motion'

module.exports =
class MoveToDefinition extends SearchCurrentWord
  scan: (cursor) ->
    actualRange = null
    @editor.scan @getSearchTerm(@input.characters + ' ?='), (iteration) =>
      actualRange = iteration.range
      iteration.stop()

    return [actualRange] if actualRange
    []
