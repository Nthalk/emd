mincer = require 'mincer'
fs = require 'fs'
uglify = require 'uglify-js'
spawn = require('child_process').spawn

option '-g', '--grep [TEST]', 'sets the grep for `cake test`'

data_dist_raw = "dist/ember-d.js"
data_dist_min = "dist/ember-d.min.js"
data_dist_min_map = "dist/ember-d.min.js.map"
test_dist_raw = "dist/ember-d.test.js"
data_raw = false

task 'package:raw', 'package the raw distributable', ->
  return if data_raw
  env = new mincer.Environment()
  env.appendPath 'src'
  data_raw = env.findAsset 'data'
  fs.writeFileSync data_dist_raw, data_raw

task 'package:min', 'package minified distributable', ->
  invoke 'package:raw'
  data_min = uglify.minify [data_dist_raw], outSourceMap: data_dist_min_map
  fs.writeFileSync data_dist_min, data_min.code
  fs.writeFileSync data_dist_min_map, data_min.map

task 'package', 'package the distributables', ->
  invoke 'package:min'

task 'package:test', 'package tests', ->
  invoke 'package:raw'
  env = new mincer.Environment()
  env.appendPath 'test'
  test_raw = env.findAsset 'test'
  fs.writeFileSync test_dist_raw, test_raw


task 'test', 'test!', (options)->
  invoke 'package:test'

  file = "test/support/index.html" + (if options.grep then '?grep=' + options.grep else '' )
  phantomjs = spawn "phantomjs", [
    "/usr/local/lib/node_modules/mocha-phantomjs/lib/mocha-phantomjs.coffee"
    file
  ]
  phantomjs.stdout.pipe process.stdout
  phantomjs.stderr.pipe process.stdout
  phantomjs.on 'exit', (code)->
    if (code == 127)
      print "Perhaps phantomjs is not installed?\n"
    process.exit code

