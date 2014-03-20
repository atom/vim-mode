ViewModel = require './view-model'

module.exports =
class ReplaceViewModel extends ViewModel
  constructor: (@replaceOperator) ->
    super(@replaceOperator, class: 'replace', hidden: true, singleChar: true)
