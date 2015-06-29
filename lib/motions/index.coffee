Motions = require './general-motions'
{Search, SearchCurrentWord, BracketMatchingMotion, RepeatSearch} = require './search-motion'
MoveToMark = require './move-to-mark-motion'
{Find, Till} = require './find-motion'
OpenFileUnderCursor = require './open-file-under-cursor'

Motions.Search = Search
Motions.SearchCurrentWord = SearchCurrentWord
Motions.BracketMatchingMotion = BracketMatchingMotion
Motions.RepeatSearch = RepeatSearch
Motions.MoveToMark = MoveToMark
Motions.Find = Find
Motions.Till = Till
Motions.OpenFileUnderCursor = OpenFileUnderCursor

module.exports = Motions
