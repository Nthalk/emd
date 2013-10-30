livereload = require 'livereload'
connect = require 'connect'
mincer = require 'mincer'
spawn = require('child_process').spawn
fs = require 'fs'
watch = require "watch"
path = require "path"

root = path.resolve "#{__dirname}/.."

emd_dist_test = "#{root}/dist/emd.test.js"

exports.registerTasks = ->
  option '-g', '--grep [TEST]', 'sets the test grep for `cake test`'

  ################################################################################
  # Creates the tests
  task 'package:test', 'package tests', ->
    invoke 'package:emd'
    env = new mincer.Environment()
    env.expireIndex()
    env.appendPath "#{root}/test/src"
    test_raw = env.findAsset 'test'
    fs.writeFileSync emd_dist_test, test_raw

  ################################################################################
  #
  task 'test:server', 'package and run tests in a livereload session', ->
    "src test/src examples".split(" ").forEach (dir)->
      watch.watchTree "#{root}/#{dir}", (file)->
        path = "#{root}/#{dir}"
        return unless file.constructor is String
        return unless file.indexOf(path) is 0
        invoke 'package:test'

    invoke 'package:test'

    reloader = livereload.createServer port: 4001
    reloader.watch "#{root}/test/support"
    reloader.watch "#{root}/dist"

    server = connect.createServer()
    server.use connect.static("#{root}/test/support")
    server.use connect.static("#{root}/dist")
    server.listen 4000
    spawn "open", ["http://localhost:4000"]

  ################################################################################
  #
  task 'test', 'runs ci tests', (options)->
    invoke 'package:test'

    file = "#{root}/test/support/index.html" + (if options.grep then '?grep=' + options.grep else '' )
    phantomjs = spawn "phantomjs", [
      "#{root}/node_modules/mocha-phantomjs/lib/mocha-phantomjs.coffee"
      file
    ]
    phantomjs.stdout.pipe process.stdout
    phantomjs.stderr.pipe process.stdout
    phantomjs.on 'exit', (code)->
      if (code == 127)
        log "Perhaps phantomjs is not installed?\n"
      process.exit code

