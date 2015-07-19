module.exports =
  class CommandError
    constructor: (@message) ->
      @name = 'Command Error'
