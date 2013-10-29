mincer = require 'mincer'
fs = require 'fs'
uglify = require 'uglify-js'
spawn = require('child_process').spawn
log = console.log

option '-g', '--grep [TEST]', 'sets the grep for `cake test`'

emd_dist_raw = "dist/emd.js"
emd_dist_min = "dist/emd.min.js"
emd_dist_min_map = "dist/emd.min.js.map"
test_dist_raw = "dist/emd.test.js"
emd_raw = false

task 'package:raw', 'package the raw distributable', ->
  return if emd_raw
  env = new mincer.Environment()
  env.appendPath 'src'
  emd_raw = env.findAsset 'emd'
  fs.writeFileSync emd_dist_raw, emd_raw

task 'package:min', 'package minified distributable', ->
  invoke 'package:raw'
  emd_min = uglify.minify [emd_dist_raw], outSourceMap: emd_dist_min_map
  fs.writeFileSync emd_dist_min, emd_min.code
  fs.writeFileSync emd_dist_min_map, emd_min.map

task 'package', 'package the distributables', ->
  invoke 'package:min'

task 'package:test', 'package tests', ->
  invoke 'package:raw'
  env = new mincer.Environment()
  env.expireIndex()
  env.appendPath 'test'
  test_raw = env.findAsset 'test'
  fs.writeFileSync test_dist_raw, test_raw
  log "Wrote #{test_dist_raw}"

task 'test:server', 'run tests', ->
  test = (file)->
    return unless file instanceof Object or file.indexOf("#{__dirname}/src") is 0 or file.indexOf("#{__dirname}/test") is 0
    log file
    invoke 'package:test'

  watch = require "watch"
  watch.watchTree "#{__dirname}", test

  livereload = require 'livereload'
  reloader = livereload.createServer port: 4001
  reloader.watch "#{__dirname}/support"
  reloader.watch "#{__dirname}/dist"

  connect = require('connect');
  server = connect.createServer()
  server.use connect.static("#{__dirname}/support")
  server.use connect.static("#{__dirname}/dist")
  server.listen 4000
  require('child_process').spawn "open", ["http://localhost:4000/index.html"]


task 'test', 'test!', (options)->
  invoke 'package:test'

  file = "#{__dirname}/support/index.html" + (if options.grep then '?grep=' + options.grep else '' )
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
  build = ->
    invoke 'build'
  watch.watchTree "#{__dirname}",
    filter: (file)->
      return false if file.indexOf("#{__dirname}/src") == 0
      return false if file.indexOf("#{__dirname}/test") == 0
      return false if file.indexOf("#{__dirname}/example") == 0
      true
    build

task 'doc', 'generate documentation', ->
  fs = require 'fs'
  walk = (dir, ret = [])->
    for file in fs.readdirSync dir
      try
        walk "#{dir}/#{file}", ret
      catch e
        ret.push "#{dir}/#{file}"
    ret

  require('child_process').spawn "#{__dirname}/node_modules/docco/bin/docco", [
    "--output", "#{__dirname}/doc"
    "--layout", "linear"
  ].concat walk("#{__dirname}/src").concat walk("#{__dirname}/examples")


