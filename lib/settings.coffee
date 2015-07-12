
settings =
  config:
    startInInsertMode:
      type: 'boolean'
      default: false
    useSmartcaseForSearch:
      type: 'boolean'
      default: false
    wrapLeftRightMotion:
      type: 'boolean'
      default: false
    useClipboardAsDefaultRegister:
      type: 'boolean'
      default: false
    numberRegex:
      type: 'string'
      default: '-?[0-9]+'
      description: 'Use this to control how Ctrl-A/Ctrl-X finds numbers; use "(?:\\B-)?[0-9]+" to treat numbers as positive if the minus is preceded by a character, e.g. in "identifier-1".'
    makeDefaultWordCamelCaseSensitive:
      type: 'boolean'
      default: true
      description: 'If set to true, the w and similar motions and text objects will be camel-case sensitive. The alt modifier key can be used to access the camel-case insensitive behaviour. Setting to false reverses the bindings.'

Object.keys(settings.config).forEach (k) ->
  settings[k] = ->
    atom.config.get('vim-mode.'+k)

settings.defaultRegister = ->
  if settings.useClipboardAsDefaultRegister() then '*' else '"'

module.exports = settings
