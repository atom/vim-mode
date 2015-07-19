ExCommands = require './ex-commands'
module.exports =
class GlobalVimState
  registers: {}
  histories: {}
  currentSearch: {}
  exCommands: ExCommands
