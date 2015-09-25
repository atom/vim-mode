{Point, Range} = require 'atom'
AllWhitespace = /^\s$/
WholeWordRegex = /\S+/
{mergeRanges} = require './utils'

class TextObject
  constructor: (@editor, @state) ->

  isComplete: -> true
  isRecordable: -> false

  execute: -> @select.apply(this, arguments)

class SelectInsideWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      selection.expandOverWord()
    [true]

class SelectInsideWholeWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(mergeRanges(selection.getBufferRange(), range))
      true

# SelectInsideQuotes and the next class defined (SelectInsideBrackets) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideQuotes extends TextObject
  constructor: (@editor, @char, @includeQuotes) ->

  findOpeningQuote: (pos) ->
    start = pos.copy()
    pos = pos.copy()
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        if line[pos.column] is @char
          if pos.column is 0 or line[pos.column - 1] isnt '\\'
            if @isStartQuote(pos)
              return pos
            else
              return @lookForwardOnLine(start)
        -- pos.column
      pos.column = -1
      -- pos.row
    @lookForwardOnLine(start)

  isStartQuote: (end) ->
    line = @editor.lineTextForBufferRow(end.row)
    numQuotes = line.substring(0, end.column + 1).replace( "'#{@char}", '').split(@char).length - 1
    numQuotes % 2

  lookForwardOnLine: (pos) ->
    line = @editor.lineTextForBufferRow(pos.row)

    index = line.substring(pos.column).indexOf(@char)
    if index >= 0
      pos.column += index
      return pos
    null

  findClosingQuote: (start) ->
    end = start.copy()
    escaping = false

    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        if endLine[end.column] is '\\'
          ++ end.column
        else if endLine[end.column] is @char
          -- start.column if @includeQuotes
          ++ end.column if @includeQuotes
          return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningQuote(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingQuote(start)
        if end?
          selection.setBufferRange(mergeRanges(selection.getBufferRange(), [start, end]))
      not selection.isEmpty()

# SelectInsideBrackets and the previous class defined (SelectInsideQuotes) are
# almost-but-not-quite-repeated code. They are different because of the depth
# checks in the bracket matcher.

class SelectInsideBrackets extends TextObject
  constructor: (@editor, @beginChar, @endChar, @includeBrackets) ->

  findOpeningBracket: (pos) ->
    pos = pos.copy()
    depth = 0
    while pos.row >= 0
      line = @editor.lineTextForBufferRow(pos.row)
      pos.column = line.length - 1 if pos.column is -1
      while pos.column >= 0
        switch line[pos.column]
          when @endChar then ++ depth
          when @beginChar
            return pos if -- depth < 0
        -- pos.column
      pos.column = -1
      -- pos.row

  findClosingBracket: (start) ->
    end = start.copy()
    depth = 0
    while end.row < @editor.getLineCount()
      endLine = @editor.lineTextForBufferRow(end.row)
      while end.column < endLine.length
        switch endLine[end.column]
          when @beginChar then ++ depth
          when @endChar
            if -- depth < 0
              -- start.column if @includeBrackets
              ++ end.column if @includeBrackets
              return end
        ++ end.column
      end.column = 0
      ++ end.row
    return

  select: ->
    for selection in @editor.getSelections()
      start = @findOpeningBracket(selection.cursor.getBufferPosition())
      if start?
        ++ start.column # skip the opening quote
        end = @findClosingBracket(start)
        if end?
          selection.setBufferRange(mergeRanges(selection.getBufferRange(), [start, end]))
      not selection.isEmpty()

class SelectAWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      selection.expandOverWord()
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

class SelectAWholeWord extends TextObject
  select: ->
    for selection in @editor.getSelections()
      range = selection.cursor.getCurrentWordBufferRange({wordRegex: WholeWordRegex})
      selection.setBufferRange(mergeRanges(selection.getBufferRange(), range))
      loop
        endPoint = selection.getBufferRange().end
        char = @editor.getTextInRange(Range.fromPointWithDelta(endPoint, 0, 1))
        break unless AllWhitespace.test(char)
        selection.selectRight()
      true

class Paragraph extends TextObject

  select: ->
    for selection in @editor.getSelections()
      @selectParagraph(selection)

  # Return a range delimted by the start or the end of a paragraph
  paragraphDelimitedRange: (startPoint) ->
    inParagraph = @isParagraphLine(@editor.lineTextForBufferRow(startPoint.row))
    upperRow = @searchLines(startPoint.row, -1, inParagraph)
    lowerRow = @searchLines(startPoint.row, @editor.getLineCount(), inParagraph)
    new Range([upperRow + 1, 0], [lowerRow, 0])

  searchLines: (startRow, rowLimit, startedInParagraph) ->
    for currentRow in [startRow..rowLimit]
      line = @editor.lineTextForBufferRow(currentRow)
      if startedInParagraph isnt @isParagraphLine(line)
        return currentRow
    rowLimit

  isParagraphLine: (line) -> (/\S/.test(line))

class SelectInsideParagraph extends Paragraph
  selectParagraph: (selection) ->
    oldRange = selection.getBufferRange()
    startPoint = selection.cursor.getBufferPosition()
    newRange = @paragraphDelimitedRange(startPoint)
    selection.setBufferRange(mergeRanges(oldRange, newRange))
    true

class SelectAParagraph extends Paragraph
  selectParagraph: (selection) ->
    oldRange = selection.getBufferRange()
    startPoint = selection.cursor.getBufferPosition()
    newRange = @paragraphDelimitedRange(startPoint)
    nextRange = @paragraphDelimitedRange(newRange.end)
    selection.setBufferRange(mergeRanges(oldRange, [newRange.start, nextRange.end]))
    true

class SelectTags extends TextObject

  Tag = /<(\/?)([^\s<>]+)[^<>]*>/g

  class TagTree
    constructor: (@outerTags, @parent) ->
      @innerTags = []
    addInnerTags: (tagTree) -> @innerTags.push(tagTree)
    isRoot: -> not @parent?
    findTags: (pos) ->
      for tagTree in @innerTags
        if tagTree.outerTags.contains(pos)
          return tagTree.findTags(pos)
      @outerTags
    findMatchingAncestor: (matchObj) ->
      ancestor = @parent
      while ancestor
        if ancestor.outerTags.isSameTag(matchObj)
          return ancestor
        ancestor = ancestor.parent
      undefined

  class Tags
    constructor: (matchObj) ->
      @name = matchObj.match[2]
      @openingTagRange = matchObj.range
    close: (matchObj) -> @closingTagRange = matchObj.range
    isSameTag: (matchObj) -> @name is matchObj.match[2]
    isAfter: (pos) -> @openingTagRange.start.isGreaterThan(pos)
    isBefore: (pos) -> @closingTagRange?.end.isLessThanOrEqual(pos)
    contains: (pos) -> @openingTagRange.start.isLessThanOrEqual(pos) and @closingTagRange?.end.isGreaterThan(pos)
    notClosed: -> not @closingTagRange?

  select: ->
    for selection in @editor.getSelections()
      pos = selection.getBufferRange().start
      tags = @findTags(pos)
      if tags
        @setSelection(selection, tags.openingTagRange, tags.closingTagRange)
        true

  findTags: (point) ->
    tagTree = @searchStartingLine(point)
    if tagTree is undefined
      tagTree = @searchMultiline(point)
    if tagTree?.outerTags.contains(point) or tagTree?.outerTags.isAfter(point)
      tagTree.findTags(point)

  # Searches for tags opened on the starting line.
  # Returns the nearest tag that is opened around or in front of the point.
  searchStartingLine: (point) ->
    tagTree = @searchBufferLine(point)
    if tagTree?.outerTags.notClosed()
      treeStartPoint = tagTree.outerTags.openingTagRange.start
      tagTree = @buildTagTreeForRange(@rangeToEofFromPoint(treeStartPoint))
    if @sameRow(point, tagTree?.outerTags.openingTagRange.start)
      tagTree

  sameRow: (point, otherPoint) -> point.row is otherPoint?.row

  searchBufferLine: (point) ->
    lineRange = @rangeToLineEndFromPoint(new Point(point.row, 0))
    while tagTree = @buildTagTreeForRange(lineRange)
      if tagTree?.outerTags.isBefore(point)
        lineRange = @rangeToLineEndFromPoint(tagTree.outerTags.closingTagRange.end)
      else
        return tagTree
    undefined

  searchMultiline: (startPoint) ->
    tagTree = undefined
    @editor.backwardsScanInBufferRange(Tag, new Range(new Point(0, 0), startPoint), ((matchObj) ->
      if @isOpeningTag(matchObj)
        tagTree = @buildTagTreeForRange(@rangeToEofFromPoint(matchObj.range.start))
        if tagTree?.outerTags.contains(startPoint)
          matchObj.stop()
    ).bind(this))
    tagTree

  rangeToLineEndFromPoint: (point) -> new Range(point, new Point(point.row, @editor.lineTextForBufferRow(point.row).length))
  rangeToEofFromPoint: (point) -> new Range(point, @editor.getEofBufferPosition())

  buildTagTreeForRange: (bufferRange) ->
    currentTagTree = undefined
    @editor.scanInBufferRange(Tag, bufferRange, ((matchObj) ->
      if @isOpeningTag(matchObj)
        newTagTree = new TagTree(new Tags(matchObj), currentTagTree)
        currentTagTree?.addInnerTags(newTagTree)
        currentTagTree = newTagTree
      else
        if currentTagTree?.outerTags.isSameTag(matchObj)
          currentTagTree.outerTags.close(matchObj)
        else
          openingTagNode = currentTagTree?.findMatchingAncestor(matchObj)
          openingTagNode?.outerTags.close(matchObj)
          currentTagTree = openingTagNode
        if currentTagTree?.isRoot()
          matchObj.stop()
        else
          currentTagTree = currentTagTree?.parent
    ).bind(this))
    currentTagTree

  isOpeningTag: (matchObj) -> matchObj.match[1] is ''

class SelectInsideTags extends SelectTags
  setSelection: (selection, openingTagRange, closingTagRange) ->
    selection.setBufferRange([openingTagRange.end, closingTagRange.start])

class SelectAroundTags extends SelectTags
  setSelection: (selection, openingTagRange, closingTagRange) ->
    selection.setBufferRange([openingTagRange.start, closingTagRange.end])

module.exports = {TextObject, SelectInsideWord, SelectInsideWholeWord, SelectInsideQuotes,
  SelectInsideBrackets, SelectAWord, SelectAWholeWord, SelectInsideParagraph, SelectAParagraph,
  SelectInsideTags, SelectAroundTags}
