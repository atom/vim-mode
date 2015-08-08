{SearchCurrentWord} = require './search-motion'

module.exports =
class MoveToDefinition extends SearchCurrentWord

  # Scan using a fake cursor that reports its position at the top of the doc
  scan: (cursor) -> super {getBufferPosition: -> [0, 0]}, true
