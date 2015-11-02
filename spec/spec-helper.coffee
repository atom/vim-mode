VimState = require '../lib/vim-state'
GlobalVimState = require '../lib/global-vim-state'
VimMode  = require '../lib/vim-mode'
StatusBarManager = require '../lib/status-bar-manager'

[globalVimState, statusBarManager] = []

beforeEach ->
  atom.workspace ||= {}
  statusBarManager = null
  globalVimState = null
  spyOn(atom, 'beep')

getEditorElement = (callback) ->
  textEditor = null

  waitsForPromise ->
    atom.workspace.open().then (e) ->
      textEditor = e

  runs ->
    element = atom.views.getView(textEditor)
    element.setUpdatedSynchronously(true)
    element.classList.add('vim-mode')
    statusBarManager ?= new StatusBarManager
    globalVimState ?= new GlobalVimState
    element.vimState = new VimState(element, statusBarManager, globalVimState)

    element.addEventListener "keydown", (e) ->
      atom.keymaps.handleKeyboardEvent(e)

    # mock parent element for the text editor
    document.createElement("html").appendChild(element)

    callback(element)

mockPlatform = (editorElement, platform) ->
  wrapper = document.createElement('div')
  wrapper.className = platform
  wrapper.appendChild(editorElement)

unmockPlatform = (editorElement) ->
  editorElement.parentNode.removeChild(editorElement)

dispatchKeyboardEvent = (target, eventArgs...) ->
  e = document.createEvent('KeyboardEvent')
  e.initKeyboardEvent(eventArgs...)
  # 0 is the default, and it's valid ASCII, but it's wrong.
  Object.defineProperty(e, 'keyCode', get: -> undefined) if e.keyCode is 0
  target.dispatchEvent e

dispatchTextEvent = (target, eventArgs...) ->
  e = document.createEvent('TextEvent')
  e.initTextEvent(eventArgs...)
  target.dispatchEvent e

keydown = (key, {element, ctrl, shift, alt, meta, raw}={}) ->
  key = "U+#{key.charCodeAt(0).toString(16)}" unless key is 'escape' or raw?
  element ||= document.activeElement
  eventArgs = [
    false, # bubbles
    true, # cancelable
    null, # view
    key,  # key
    0,    # location
    ctrl, alt, shift, meta
  ]

  canceled = not dispatchKeyboardEvent(element, 'keydown', eventArgs...)
  dispatchKeyboardEvent(element, 'keypress', eventArgs...)
  if not canceled
    if dispatchTextEvent(element, 'textInput', eventArgs...)
      element.value += key
  dispatchKeyboardEvent(element, 'keyup', eventArgs...)

module.exports = {keydown, getEditorElement, mockPlatform, unmockPlatform}
