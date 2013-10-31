# = require_tree ./templates
# = require_self
# = require_tree .

Doc = Em.Application.create
  posts: []

  LOG_TRANSITIONS: true
  LOG_TRANSITIONS_INTERNAL: true
  LOG_VIEW_LOOKUPS: true
  LOG_ACTIVE_GENERATION: true


Doc.Post = Em.Object.extend()
