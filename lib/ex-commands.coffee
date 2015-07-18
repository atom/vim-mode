fs = require 'fs-plus'
{saveAs, getFullPath} = require './utils'
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
          @callCommand('edit', ev)
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

    @registerCommand: ({name, priority, callback}) =>
      @commands[name] = {priority, callback}

    @callCommand: (name, ev) =>
      @commands[name].callback(ev)
