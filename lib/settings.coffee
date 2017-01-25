
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
    overrideDefaultRegister:
      type: 'string',
      default: '',
      description: 'Enter the key of the register (other than "), to override the default register used'
    useClipboardAsDefaultRegister:
      type: 'boolean'
      default: true
    numberRegex:
      type: 'string'
      default: '-?[0-9]+'
      description: 'Use this to control how Ctrl-A/Ctrl-X finds numbers; use "(?:\\B-)?[0-9]+" to treat numbers as positive if the minus is preceded by a character, e.g. in "identifier-1".'

Object.keys(settings.config).forEach (k) ->
  settings[k] = ->
    atom.config.get('vim-mode.'+k)

settings.defaultRegister = ->
  defaultRegister = if settings.overrideDefaultRegister() then settings.overrideDefaultRegister() else '""
  '
  if settings.useClipboardAsDefaultRegister() then '*' else defaultRegister

module.exports = settings
