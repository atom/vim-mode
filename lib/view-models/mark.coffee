ViewModel = require './view-model'

module.exports =
class MarkViewModel extends ViewModel
  constructor: (@markOperator) ->
    super(@markOperator, class: 'mark', singleChar: true, hidden: true)
