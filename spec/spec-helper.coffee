{$} = require 'atom'
VimState = require '../lib/vim-state'
VimMode  = require '../lib/vim-mode'

originalKeymap = null

beforeEach ->
  atom.workspace ||= {}
  VimMode._initializeWorkspaceState()

getEditorElement = (callback) ->
  textEditor = null

  waitsForPromise ->
    atom.project.open().then (e) ->
      textEditor = e

  runs ->
    element = document.createElement("atom-text-editor")
    element.setModel(textEditor)
    element.classList.add('vim-mode')
    element.vimState = new VimState(element)

    $(element).simulateDomAttachment()
    $(element).enableKeymap()

    callback(element)

mockPlatform = (editorElement, platform) ->
  wrapper = document.createElement('div')
  wrapper.className = platform
  wrapper.appendChild(editorElement)

unmockPlatform = (editorElement) ->
  editorElement.parentNode.removeChild(editorElement)

keydown = (key, {element, ctrl, shift, alt, meta, raw}={}) ->
  dispatchKeyboardEvent = (target, eventArgs...) ->
    e = document.createEvent('KeyboardEvent')
    e.initKeyboardEvent eventArgs...
    # 0 is the default, and it's valid ASCII, but it's wrong.
    Object.defineProperty(e, 'keyCode', get: -> undefined) if e.keyCode is 0
    target.dispatchEvent e

  dispatchTextEvent = (target, eventArgs...) ->
    e = document.createEvent('TextEvent')
    e.initTextEvent eventArgs...
    target.dispatchEvent e

  key = "U+#{key.charCodeAt(0).toString(16)}" unless key == 'escape' || raw?
  element ||= document.activeElement
  eventArgs = [true, true, null, key, 0, ctrl, alt, shift, meta] # bubbles, cancelable, view, key, location

  canceled = not dispatchKeyboardEvent(element, 'keydown', eventArgs...)
  dispatchKeyboardEvent(element, 'keypress', eventArgs...)
  if not canceled
     if dispatchTextEvent(element, 'textInput', eventArgs...)
       element.value += key
  dispatchKeyboardEvent(element, 'keyup', eventArgs...)

module.exports = { keydown, getEditorElement, mockPlatform, unmockPlatform }
