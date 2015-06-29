{Motion} = require './general-motions'
path = require 'path'
{Directory} = require 'atom'
shell = require 'shell'
{exec} = require 'child_process'

class OpenFileUnderCursor extends Motion
  execute: (count) ->
    ###
      /usr/bin/test
      ../../.travis.yml
      ./search-motion
      ./index
      http://github.com
      https://thing.com/item%20test
      //github.com
    ###
    wordRegex = /[a-z0-9\.\-_\/\\%:]+/i
    @editor.getCursors().forEach (cursor) =>
      range = cursor.getCurrentWordBufferRange wordRegex: wordRegex
      selectedPath = @editor.getTextInRange range

      # exit early for url match
      if /^https?:/i.test(selectedPath)
        return @openUrl selectedPath
      if /^\/\//i.test(selectedPath)
        return @openUrl "http:#{selectedPath}"

      if selectedPath[0] isnt '/' and selectedPath[0] isnt '\\'
        selectedPath = path.join path.dirname(@editor.buffer.file.path), selectedPath

      pathDir = path.dirname selectedPath
      dir = new Directory pathDir
      ext = path.extname @editor.buffer.file.path
      dir.getEntries (err, entries) =>
        # find any paths that contain the selected path
        matches = entries.filter (entry) -> entry.path.indexOf(selectedPath) > -1
        return @loadFile matches[0].path if matches.length is 1

        # if there are other possible matches, try to match on extension
        extMatches = matches.filter (entry) -> path.extname(entry.path) is ext
        return @loadFile extMatches[0].path if extMatches.length is 1

  loadFile: (path) -> atom.workspace.open path

  openUrl: (url) ->
    # pulled from https://github.com/magbicaleman/open-in-browser/blob/master/lib/open-in-browser.coffee
    process_architecture = process.platform
    switch process_architecture
      when 'darwin' then exec "open '#{url}'"
      when 'linux' then exec "xdg-open '#{url}'"
      when 'win32' then shell.openExternal url

module.exports = OpenFileUnderCursor
