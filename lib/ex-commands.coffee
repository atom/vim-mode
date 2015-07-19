fs = require 'fs-plus'
{saveAs, getFullPath, replaceGroups, getSearchTerm} = require './utils'
CommandError = require './command-error'

trySave = (func) ->
  deferred = Promise.defer()

  try
    func()
    deferred.resolve()
  catch error
    if error.message.endsWith('is a directory')
      atom.notifications.addWarning("Unable to save file: #{error.message}")
    else if error.path?
      if error.code is 'EACCES'
        atom.notifications
          .addWarning("Unable to save file: Permission denied '#{error.path}'")
      else if error.code in ['EPERM', 'EBUSY', 'UNKNOWN', 'EEXIST']
        atom.notifications.addWarning("Unable to save file '#{error.path}'",
          detail: error.message)
      else if error.code is 'EROFS'
        atom.notifications.addWarning(
          "Unable to save file: Read-only file system '#{error.path}'")
    else if (errorMatch =
        /ENOTDIR, not a directory '([^']+)'/.exec(error.message))
      fileName = errorMatch[1]
      atom.notifications.addWarning("Unable to save file: A directory in the "+
        "path '#{fileName}' could not be written to")
    else
      throw error

  deferred.promise

module.exports =
  class ExCommands
    @commands =
      'quit':
        priority: 1000
        callback: ->
          atom.workspace.getActivePane().destroyActiveItem()
      'tabclose':
        priority: 1000
        callback: (ev) =>
          @callCommand('quit', ev)
      'qall':
        priority: 1000
        callback: ->
          atom.close()
      'tabnext':
        priority: 1000
        callback: ->
          atom.workspace.getActivePane().activateNextItem()
      'tabprevious':
        priority: 1000
        callback: ->
          atom.workspace.getActivePane().activatePreviousItem()
      'write':
        priority: 1001
        callback: ({editor, args}) ->
          if args[0] is '!'
            force = true
            args = args[1..]

          filePath = args.trimLeft()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')

          deferred = Promise.defer()

          if filePath.length isnt 0
            fullPath = getFullPath(filePath)
          else if editor.getPath()?
            trySave(-> editor.save())
              .then(deferred.resolve)
          else
            fullPath = atom.showSaveDialogSync()

          if fullPath?
            if not force and fs.existsSync(fullPath)
              throw new CommandError("File exists (add ! to override)")
            trySave(-> saveAs(fullPath, editor))
              .then(deferred.resolve)

          deferred.promise
      'update':
        priority: 1000
        callback: (ev) =>
          @callCommand('write', ev)
      'wall':
        priority: 1000
        callback: ->
          # FIXME: This is undocumented for quite a while now - not even
          #        deprecated. Should probably use PaneContainer::saveAll
          atom.workspace.saveAll()
      'wq':
        priority: 1000
        callback: (ev) =>
          @callCommand('write', ev).then => @callCommand('quit')
      'xit':
        priority: 1000
        callback: (ev) =>
          @callCommand('wq', ev)
      'exit':
        priority: 1000
        callback: (ev) => @callCommand('xit', ev)
      'xall':
        priority: 1000
        callback: (ev) =>
          atom.workspace.saveAll()
          @callCommand('qall', ev)
      'edit':
        priority: 1001
        callback: ({args, editor}) ->
          args = args.trim()
          if args[0] is '!'
            force = true
            args = args[1..]

          if editor.isModified() and not force
            throw new CommandError(
              'No write since last change (add ! to override)')

          filePath = args.trimLeft()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')

          if filePath.length isnt 0
            fullPath = getFullPath(filePath)
            if fullPath is editor.getPath()
              editor.getBuffer().reload()
            else
              atom.workspace.open(fullPath)
          else
            if editor.getPath()?
              editor.getBuffer().reload()
            else
              throw new CommandError('No file name')
      'tabedit':
        priority: 1000
        callback: (ev) =>
          if ev.args.trim() is ''
            @callCommand('tabnew', ev)
          else
            @callCommand('edit', ev)
      'tabnew':
        priority: 1000
        callback: ->
          atom.workspace.open()
      'split':
        priority: 1000
        callback: ({args}) ->
          filePath = args.trim()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')

          pane = atom.workspace.getActivePane()
          if filePath.length isnt 0
            # FIXME: This is horribly slow
            atom.workspace.openURIInPane(getFullPath(filePath), pane.splitUp())
          else
            pane.splitUp(copyActiveItem: true)
      'new':
        priority: 1000
        callback: ({args}) ->
          filePath = args.trim()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')
          filePath = undefined if filePath.length is 0
          # FIXME: This is horribly slow
          atom.workspace.openURIInPane(filePath,
            atom.workspace.getActivePane().splitUp())
      'vsplit':
        priority: 1000
        callback: ({args}) ->
          filePath = args.trim()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')

          pane = atom.workspace.getActivePane()
          if filePath.length isnt 0
            # FIXME: This is horribly slow
            atom.workspace.openURIInPane(getFullPath(filePath),
              pane.splitLeft())
          else
            pane.splitLeft(copyActiveItem: true)
      'vnew':
        priority: 1000
        callback: ({args}) ->
          filePath = args.trim()
          if /[^\\] /.test(filePath)
            throw new CommandError('Only one file name allowed')
          filePath = filePath.replace(/\\ /g, ' ')
          filePath = undefined if filePath.length is 0
          # FIXME: This is horribly slow
          atom.workspace.openURIInPane(filePath,
            atom.workspace.getActivePane().splitLeft())
      'delete':
        priority: 1000
        callback: ({range, editor}) ->
          range = [[range[0], 0], [range[1] + 1, 0]]
          editor.setTextInBufferRange(range, '')
      'substitute':
        priority: 1001
        callback: ({range, args, editor, vimState}) ->
          args_ = args.trimLeft()
          delim = args_[0]
          if /[a-z]/i.test(delim)
            throw new CommandError(
              "Regular expressions can't be delimited by letters")
          if delim is '\\'
            throw new CommandError(
              "Regular expressions can't be delimited by \\")
          args_ = args_[1..]
          parsed = ['', '', '']
          parsing = 0
          escaped = false
          while (char = args_[0])?
            args_ = args_[1..]
            if char is delim
              if not escaped
                parsing++
                if parsing > 2
                  throw new CommandError('Trailing characters')
              else
                parsed[parsing] = parsed[parsing][...-1]
            else if char is '\\' and not escaped
              parsed[parsing] += char
              escaped = true
            else
              escaped = false
              parsed[parsing] += char

          [pattern, substition, flags] = parsed
          if pattern is ''
            pattern = vimState.getCustomHistoryItem('search', 0)
            if not pattern?
              atom.beep()
              throw new CommandError('No previous regular expression')
          else
            vimState.pushCustomHistory('search', pattern)

          try
            flagsObj = {}
            flags.split('').forEach((flag) -> flagsObj[flag] = true)
            patternRE = getSearchTerm(pattern, flagsObj)
          catch e
            if e.message.indexOf('Invalid flags supplied to RegExp constructor') is 0
              throw new CommandError("Invalid flags: #{e.message[45..]}")
            else if e.message.indexOf('Invalid regular expression: ') is 0
              throw new CommandError("Invalid RegEx: #{e.message[27..]}")
            else
              throw e

          editor.transact ->
            for line in [range[0]..range[1]]
              editor.scanInBufferRange(
                patternRE,
                [[line, 0], [line + 1, 0]],
                ({match, replace}) ->
                  replace(replaceGroups(match[..], substition))
              )

    @registerCommand: ({name, priority, callback}) =>
      @commands[name] = {priority, callback}

    @callCommand: (name, ev) =>
      @commands[name].callback(ev)
