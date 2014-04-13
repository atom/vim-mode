Motions = require './general-motions'
{Search, BasicSearch, SearchCurrentWord} = require './search-motion'
MoveToMark = require './move-to-mark-motion'
Find = require './find-motion'

Motions.Search = Search
Motions.SearchCurrentWord = SearchCurrentWord
Motions.MoveToMark = MoveToMark
Motions.Find = Find

module.exports = Motions
