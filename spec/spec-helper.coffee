Editor = require 'editor'
Keymap = require 'keymap'

VimState = require '../lib/vim-state'

originalKeymap = null

beforeEach ->
  originalKeymap = window.keymap
  window.keymap = new Keymap

afterEach ->
  window.keymap = originalKeymap

cacheEditor = (existingEditor) ->
  if existingEditor?
    existingEditor.edit(window.project.open())
    existingEditor.vimState.registerChangeHandler(existingEditor.getBuffer())
  else
    editor = new Editor(project.open())
    editor.simulateDomAttachment()
    editor.enableKeymap()

    editor.addClass('vim-mode')
    editor.vimState = new VimState(editor)

  existingEditor or editor

keydown = (key, {element, ctrl, shift, alt, meta}={}) ->
  dispatchKeyboardEvent = (target, eventArgs...) ->
    e = document.createEvent('KeyboardEvent')
    e.initKeyboardEvent eventArgs...
    target.dispatchEvent e

  dispatchTextEvent = (target, eventArgs...) ->
    e = document.createEvent('TextEvent')
    e.initTextEvent eventArgs...
    target.dispatchEvent e

  key = "U+#{key.charCodeAt(0).toString(16)}" unless key == 'escape'
  element ||= document.activeElement
  eventArgs = [true, true, null, key, 0, ctrl, alt, shift, meta] # bubbles, cancelable, view, key, location

  canceled = not dispatchKeyboardEvent(element, 'keydown', eventArgs...)
  dispatchKeyboardEvent(element, 'keypress', eventArgs...)
  if not canceled
     if dispatchTextEvent(element, 'textInput', eventArgs...)
       element.value += key
  dispatchKeyboardEvent(element, 'keyup', eventArgs...)

module.exports = { keydown, cacheEditor }
