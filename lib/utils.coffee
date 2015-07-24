# copied from atom/atom-keymap src/helpers.coffee
AtomModifierRegex = /(ctrl|alt|shift|cmd)$/

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

  # copied and simplified from atom/atom-keymap src/helpers.coffee
  isAtomModifier: (keystroke) ->
    AtomModifierRegex.test(keystroke)
