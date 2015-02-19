
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

Object.keys(settings.config).forEach (k) ->
  settings[k] = ->
    atom.config.get('vim-mode.'+k)

settings.defaultRegister = ->
  if settings.useClipboardAsDefaultRegister() then '*' else '"'

module.exports = settings
