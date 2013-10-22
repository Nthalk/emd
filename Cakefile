mincer = require 'mincer'
fs = require 'fs'
uglify = require 'uglify-js'
spawn = require('child_process').spawn

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
  env.appendPath 'test'
  test_raw = env.findAsset 'test'
  fs.writeFileSync test_dist_raw, test_raw


task 'test', 'test!', (options)->
  invoke 'package:test'

  file = "test/support/index.html" + (if options.grep then '?grep=' + options.grep else '' )
  phantomjs = spawn "phantomjs", [
    "node_modules/mocha-phantomjs/lib/mocha-phantomjs.coffee"
    file
  ]
  phantomjs.stdout.pipe process.stdout
  phantomjs.stderr.pipe process.stdout
  phantomjs.on 'exit', (code)->
    if (code == 127)
      print "Perhaps phantomjs is not installed?\n"
    process.exit code

