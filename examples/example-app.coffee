# EmberJS boilerplate:
App = Em.Application.create()

# The meat of the model:
App.User = EMD.Model.create
  name: EMD.attr "name"
  emailAddress: EMD.attr "email_address"
  lastLogin: EMD.attr "last_login", readonly: true
  favoriteColor: EMD.attr "favorite_color", optional: true

# Default fields
# ----
# All classes that extend `EMD.Model` have the following default fields:
#
# 1. `id: EMD.attr "id"`, the basic id field: `{id:1}`
# 1.  `errors: EMD.attr.object "errors", optional: true, readonly: true`
# 1.  `createdAt: EMD.attr.object "errors", optional: true, readonly: true`
