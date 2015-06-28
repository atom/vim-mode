_ = require 'underscore-plus'
{Motion, MoveToFirstCharacterOfLine} = require './general-motions'
{ViewModel} = require '../view-models/view-model'
{Input} = require '../view-models/view-model'
{Point, Range} = require 'atom'
{SearchCurrentWord} = require './search-motion'

module.exports =
class MoveToDefinition extends SearchCurrentWord
  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)

    # FIXME: This must depend on the current language
    # NOTE: The only modification here is the addition of the $
    defaultIsKeyword = "[@$a-zA-Z0-9_\-]+"
    userIsKeyword = atom.config.get('vim-mode.iskeyword')
    @keywordRegex = new RegExp(userIsKeyword or defaultIsKeyword)

    searchString = @getCurrentWordMatch()
    @input = new Input(searchString)

  getSearchTerm: (term) ->
    search = "(\\w )?#{term}\\s?=?"
    search = search.replace /([$])/g, '\\$1'
    new RegExp search, 'gmi'

  scan: (cursor) ->
    actualRange = null
    @editor.scan @getSearchTerm(@input.characters), (iteration) ->
      actualRange = iteration.range

      # if there are two filled matches, that means
      # this followed the first and second part, so
      # we need to skip the match forward a bit
      if _.compact(iteration.match).length is 2
        actualRange.start.column += 2

      # scan starts from the top, so we just want
      # the first result
      iteration.stop()

    return [actualRange] if actualRange
    []
