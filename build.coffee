mincer = require 'mincer'
fs = require 'fs'

uglify = require 'uglify-js'

env = new mincer.Environment()
env.appendPath 'src'
data_raw = env.findAsset 'data'

data_dist_raw = "dist/ember-d.js"
data_dist_min = "dist/ember-d.min.js"
data_dist_min_map = "dist/ember-d.min.js.map"

# Raw distribution
fs.writeFile data_dist_raw, data_raw, ->
  # Minified
  data_min = uglify.minify [data_dist_raw], outSourceMap: data_dist_min_map
  fs.writeFile data_dist_min, data_min.code
  fs.writeFile data_dist_min_map, data_min.map


