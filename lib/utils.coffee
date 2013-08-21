module.exports =
  # Public: Determines if a string should be considered linewise or character
  #
  # text - The string to consider
  #
  # Returns 'linewise' if the string ends with a line return and 'character'
  #  otherwise.
  copyType: (text) ->
    if text.lastIndexOf("\n") == text.length - 1
      'linewise'
    else if text.lastIndexOf("\r") == text.length - 1
      'linewise'
    else
      'character'
