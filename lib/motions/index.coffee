Motions = require './general-motions'
{Search, SearchCurrentWord, BracketMatchingMotion} = require './search-motion'
MoveToMark = require './move-to-mark-motion'
{Find, Till} = require './find-motion'

Motions.Search = Search
Motions.SearchCurrentWord = SearchCurrentWord
Motions.BracketMatchingMotion = BracketMatchingMotion
Motions.MoveToMark = MoveToMark
Motions.Find = Find
Motions.Till = Till

module.exports = Motions
