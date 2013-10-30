mincer = require 'mincer'
fs = require 'fs'
uglify = require 'uglify-js'
spawn = require('child_process').spawn
log = console.log
watch = require "watch"

option '-g', '--grep [TEST]', 'sets the grep for `cake test`'

emd_dist_raw = "dist/emd.js"
emd_dist_min = "dist/emd.min.js"
emd_dist_min_map = "dist/emd.min.js.map"
emd_dist_test = "dist/emd.test.js"
doc_dist_raw = "dist/emd.doc.js"

################################################################################
# Documentation
task 'package:doc', 'generate documentation', ->
  env = new mincer.Environment()
  env.expireIndex()
  env.appendPath 'doc'
  doc_raw = env.findAsset 'doc'
  fs.writeFileSync doc_dist_raw, doc_raw

task 'doc:server', 'live documentation server', ->
  "doc".split(" ").forEach (dir)->
    path = "#{__dirname}/#{dir}"
    test = (file)->
      return unless file.constructor is String
      return unless file.indexOf(path) is 0
      invoke 'package:doc'
    watch.watchTree path, test

  invoke 'package:doc'

  livereload = require 'livereload'
  reloader = livereload.createServer port: 4001
  reloader.watch "#{__dirname}/dist"

  connect = require('connect');
  server = connect.createServer()
  server.use connect.static("#{__dirname}/dist")
  server.listen 4000
  require('child_process').spawn "open", ["http://localhost:4400/doc.html"]

################################################################################
# Raw, unminified source
task 'package:raw', 'package the raw distributable', ->
  env = new mincer.Environment()
  env.expireIndex()
  env.appendPath 'src'
  emd_raw = env.findAsset 'emd'
  fs.writeFileSync emd_dist_raw, emd_raw

################################################################################
# Minified source
task 'package:min', 'package minified distributable', ->
  invoke 'package:raw'
  emd_min = uglify.minify [emd_dist_raw], outSourceMap: emd_dist_min_map
  fs.writeFileSync emd_dist_min, emd_min.code
  fs.writeFileSync emd_dist_min_map, emd_min.map

task 'package', 'package the distributables', ->
  invoke 'package:min'

################################################################################
# Creates the tests
task 'package:test', 'package tests', ->
  invoke 'package:raw'
  env = new mincer.Environment()
  env.expireIndex()
  env.appendPath 'test/src'
  test_raw = env.findAsset 'test'
  fs.writeFileSync emd_dist_test, test_raw

################################################################################
#
task 'test:server', 'package and run tests in a livereload session', ->
  "src test/src examples".split(" ").forEach (dir)->
    path = "#{__dirname}/#{dir}"
    test = (file)->
      return unless file.constructor is String
      return unless file.indexOf(path) is 0
      invoke 'package:test'
    watch.watchTree path, test

  invoke 'package:test'

  livereload = require 'livereload'
  reloader = livereload.createServer port: 4001
  reloader.watch "#{__dirname}/test/support"
  reloader.watch "#{__dirname}/dist"

  connect = require('connect');
  server = connect.createServer()
  server.use connect.static("#{__dirname}/test/support")
  server.use connect.static("#{__dirname}/dist")
  server.listen 4000
  require('child_process').spawn "open", ["http://localhost:4000/index.html"]

################################################################################
#
task 'test', 'runs ci tests', (options)->
  invoke 'package:test'

  file = "#{__dirname}/test/support/index.html" + (if options.grep then '?grep=' + options.grep else '' )
  phantomjs = spawn "phantomjs", [
    "#{__dirname}/node_modules/mocha-phantomjs/lib/mocha-phantomjs.coffee"
    file
  ]
  phantomjs.stdout.pipe process.stdout
  phantomjs.stderr.pipe process.stdout
  phantomjs.on 'exit', (code)->
    if (code == 127)
      log "Perhaps phantomjs is not installed?\n"
    process.exit code

task 'build', 'build', ->
  invoke 'package:test'
  invoke 'doc'

task 'watch', 'watch', ->
  watch = require "watch"
  "src test examples".split(" ").forEach (dir)->
    path = "#{__dirname}/#{dir}"
    build = (file)->
      return unless file.constructor is String
      return unless file.indexOf(path) is 0
      invoke 'build'
    watch.watchTree path, build
  invoke 'build'

