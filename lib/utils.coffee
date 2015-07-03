module.exports =
  # Public: Determines if a string should be considered linewise or character
  #
  # text - The string to consider
  #
  # Returns 'linewise' if the string ends with a line return and 'character'
  #  otherwise.
  copyType: (text) ->
    if text.lastIndexOf("\n") is text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") is text.length - 1
      'linewise'
    else
      'character'

  # Public: Return the word that the cursor is currently inside of
  #
  # editor - Editor instance to use
  # cursor - Cursor the word should be searched via
  # keywordRegex - [optional] RegEx to decide "what" a word is
  #
  # Returns {word, range} for the discovered content or null if not found
  getCurrentWord: (editor, cursor, keywordRegex) ->
    if not keywordRegex
      defaultIsKeyword = "[@a-zA-Z0-9_\-]+"
      userIsKeyword = atom.config.get('vim-mode.iskeyword')
      keywordRegex = new RegExp(userIsKeyword or defaultIsKeyword)

    wordStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: keywordRegex, allowPrevious: false)
    wordEnd   = cursor.getEndOfCurrentWordBufferPosition      (wordRegex: keywordRegex, allowNext: false)
    cursorPosition = cursor.getBufferPosition()

    if wordEnd.column is cursorPosition.column
      # either we don't have a current word, or it ends on cursor, i.e. precedes it, so look for the next one
      wordEnd = cursor.getEndOfCurrentWordBufferPosition      (wordRegex: keywordRegex, allowNext: true)
      return null if wordEnd.row isnt cursorPosition.row # don't look beyond the current line

      cursor.setBufferPosition wordEnd
      wordStart = cursor.getBeginningOfCurrentWordBufferPosition(wordRegex: keywordRegex, allowPrevious: false)

    cursor.setBufferPosition wordStart

    {
      word: editor.getTextInBufferRange([wordStart, wordEnd])
      range: [wordStart, wordEnd]
    }
