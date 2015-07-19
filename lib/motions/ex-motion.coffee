_ = require 'underscore-plus'
{MotionWithInput} = require './general-motions'
{ViewModelWithHistory} = require '../view-models/view-model-with-history'
{scanEditor} = require '../utils'
ExCommands = require '../ex-commands'
CommandError = require '../command-error'

cmp = (x, y) -> if x > y then 1 else if x < y then -1 else 0

class ExMode extends MotionWithInput

  constructor: (@editor, @vimState) ->
    super(@editor, @vimState)
    @viewModel = new ViewModelWithHistory(this, 'ex')

  parseAddress: (str, cursor) ->
    row = cursor.getBufferRow()
    if str in ['', '.']
      addr = row
    else if str is '$'
      # Lines are 0-indexed in Atom, but 1-indexed in vim.
      addr = @editor.getBuffer().lines.length - 1
    else if str[0] in ['+', '-']
      addr = row + @parseOffset(str)
    else if not isNaN(str)
      addr = parseInt(str) - 1
    else if str[0] is "'" # Parse Mark...
      mark = @vimState.marks[str[1]]
      unless mark?
        throw new CommandError("Mark #{str} not set.")
      addr = mark.getEndBufferPosition().row
    else if (first = str[0]) in ['/', '?']
      reversed = first is '?'
      str = @viewModel.checkForRepeatSearch(str[1..], reversed)
      throw new CommandError('No previous regular expression') if str is ''
      str = str[...-1] if str[str.length - 1] is first
      @regex = str
      lineRange = cursor.getCurrentLineBufferRange()
      pos = if reversed then lineRange.start else lineRange.end
      addr = scanEditor(str, @editor, pos, reversed)[0]
      unless addr?
        throw new CommandError("Pattern not found: #{str[1...-1]}")
      addr = addr.start.row

    return addr

  parseOffset: (str) ->
    if str.length is 0
      return 0
    if str.length is 1
      offset = 1
    else
      offset = parseInt(str[1..])
    if str[0] is '+'
      return offset
    else
      return -offset

  parse: (commandLine, cursor) ->
    _commandLine = commandLine
    # Command line parsing (mostly) following the rules at
    # http://pubs.opengroup.org/onlinepubs/9699919799/utilities/ex.html
    # /ex.html#tag_20_40_13_03

    # Steps 1/2: Leading blanks and colons are ignored.
    commandLine = commandLine.replace(/^(:|\s)*/, '')
    return unless commandLine.length > 0

    # Step 3: If the first character is a ", ignore the rest of the line
    if commandLine[0] is '"'
      return

    # Step 4: Address parsing
    lastLine = @editor.getBuffer().lines.length - 1
    if commandLine[0] is '%'
      range = [0, lastLine]
      commandLine = commandLine[1..]
    else
      addrPattern = ///^
        (?:                       # First address
        (
        \.|                       # Current line
        \$|                       # Last line
        \d+|                      # n-th line
        '[\[\]<>'`"^.(){}a-zA-Z]| # Marks
        /.*?(?:[^\\]/|$)|         # Regex
        \?.*?(?:[^\\]\?|$)|       # Backwards search
        [+-]\d*                   # Current line +/- a number of lines
        )((?:\s*[+-]\d*)*)        # Line offset
        )?
        (?:,                      # Second address
        (                         # Same as first address
        \.|
        \$|
        \d+|
        '[\[\]<>'`"^.(){}a-zA-Z]|
        /.*?[^\\](?:/|$)|
        \?.*?[^\\](?:\?|$)|
        [+-]\d*|
                                  # Empty second address
        )((?:\s*[+-]\d*)*)
        )?
      ///

      [match, addr1, off1, addr2, off2] = commandLine.match(addrPattern)

      if addr1?
        address1 = @parseAddress(addr1, cursor)
      else
        # If no addr1 is given (e.g. `,+3`), assume it is '.'
        address1 = cursor.getBufferRow()
      if off1?
        address1 += @parseOffset(off1)

      address1 = 0 if address1 is -1

      if address1 < 0 or address1 > lastLine
        throw new CommandError('Invalid range')

      if addr2?
        address2 = @parseAddress(addr2, cursor)
      if off2?
        address2 += @parseOffset(off2)

      if @regex?
        @vimState.pushCustomHistory('search', @regex)

      if address2 < 0 or address2 > lastLine
        throw new CommandError('Invalid range')

      if address2 < address1
        throw new CommandError('Backwards range given')

      range = [address1, if address2? then address2 else address1]
      commandLine = commandLine[match?.length..]

    # Step 5: Leading blanks are ignored
    commandLine = commandLine.trimLeft()

    # Step 6a: If no command is specified, go to the last specified address
    if commandLine.length is 0
      cursor.setBufferPosition([range[1], 0])
      return [range, undefined, []]
    else

    # Skip steps 6b, 6c and 7a since flags are not yet implpemented.

    # Step 7b: :k<valid mark> is equivalent to :mark <valid mark> - only
    # a-z is in vim-mode for now
    if commandLine.length is 2 and commandLine[0] is 'k' and /[a-z]/.test(commandLine[1])
      command = 'mark'
      args = commandLine[1]
    else if not /[a-z]/i.test(commandLine[0])
      command = commandLine[0]
      args = commandLine[1..]
    else
      [m, command, args] = commandLine.match(/^(\w+)(.*)/)

    commandLineRE = new RegExp("^" + _.escapeRegExp(command))
    matching = []

    for name in Object.keys(ExCommands.commands)
      if commandLineRE.test(name)
        command = ExCommands.commands[name]
        if matching.length is 0
          matching = [command]
        switch cmp(command.priority, matching[0].priority)
          when 1 then matching = [command]
          when 0 then matching.push(command)

    command = matching.sort()[0]
    unless command?
      throw new CommandError("Not an editor command: #{_commandLine}")

    return [range, command?.callback, args.trimLeft()]

  moveCursor: (cursor, count=1) ->
    try
      [range, command, args] = @parse(@input.characters, cursor)
      command?({args, range, @vimState, @editor})
    catch e
      unless e instanceof CommandError
        throw e
      atom.notifications.addError("Command Error: #{e.message}")

module.exports = ExMode
