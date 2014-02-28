{View} = require 'atom'

module.exports =

class VimDebugView extends View
  @content: >
    @div outlet: 'main', class: 'debug-window', =>
      @div class: 'keys'
      @div class: 'commands'
      @div class: 'register'

  initialize: (@state)->
    # add some events?

  toggle: =>
    @main.toggleClass('hidden')
