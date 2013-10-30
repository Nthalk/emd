fs = require 'fs'
mincer = require 'mincer'
uglify = require 'uglify-js'

root = "#{__dirname}/.."

emd_dist_raw = "#{root}/dist/emd.js"
emd_dist_min = "#{root}/dist/emd.min.js"
emd_dist_min_map = "#{root}/dist/emd.min.js.map"

exports.registerTasks = ->
  ################################################################################
  # Raw, unminified source
  task 'package:emd', 'package the raw emd distributable', ->
    env = new mincer.Environment()
    env.expireIndex()
    env.appendPath 'src'
    emd_raw = env.findAsset 'emd'
    fs.writeFileSync emd_dist_raw, emd_raw

  ################################################################################
  # Minified source
  task 'package:emd:min', 'package minified emd distributable', ->
    invoke 'package:emd'
    emd_min = uglify.minify [emd_dist_raw], outSourceMap: emd_dist_min_map
    fs.writeFileSync emd_dist_min, emd_min.code
    fs.writeFileSync emd_dist_min_map, emd_min.map

  task 'build', 'build distributable, minified distributable, docs, tests', ->
    invoke 'package:test'
    invoke 'package:doc'
    invoke 'package:emd'
    invoke 'package:emd:min'
