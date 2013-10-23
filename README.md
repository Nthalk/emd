Emd
=======

An opinionated convention over configuration EmberJs data modeling framework.

Prescribed Format
------

The typical (coffee) JSON format that I would suggest looks like this:

    model_name:
      url: "/link/to/resource/route"    # Required
      id: modelid                       # Required
      under_score_names: "with values!"
      created_at: "date string"         # Optional
      errors: {key: ["problem"]}        # Optional
      links:                            # Recommended
        relatedmodel: "/link/to/related/model?with=relevant&conditions"

Prescribed API Structure
----

Every API should have a root object, that provides discoverable urls through a
nested links object.

    api:
      url: "/api"
      version: "0.1.0"
      links:
        users: "/api/users"
        articles: "/api/articles"
        comments: "/api/comments"

Example?
-------

Here is the coffee script to deal with the above api structure

    App.Api = EMD.Model.extend
      url: "/api"
      users: EMD.hasMany 'App.User', urlBinding: 'links.users'
      articles: EMD.hasMany articles: 'App.Article'
      comments: EMD.hasMany 'App.Comment', urlBinding: 'links.comments'

    App.User = EMD.Model.extend
      email: EMD.attr "email"
      phoneNumber: EMD.attr "phone_number"
      comments: EMD.hasMany 'App.Comment', urlBinding: 'links.comments'

    api = App.Api.create()
    users = api.get "users"
    users.load().then ->
      first_user = users.get "firstObject"

    new_user = users.get "nextNew"
    new_user.save().then (ok = ->
      console.log "saved user!"
      next_new_user = users.get "nextNew"
      next_new_user != new_user # true
    ), (er = ->
      console.log "errors!", new_user.get 'errors'
    )

Attribute Types
-----

Currently there is support for

    EMD.attr.belongsTo foreign_key: 'Parent.Model'
    EMD.attr.hasMany 'Child.Model', urlBinding: 'link.children' # Which is the same as
    EMD.attr.hasMany children: 'Child.Model'
    EMD.attr.moment 'key_name'
    EMD.attr 'key_name'
    EMD.attr.object 'key_name'


Links and Urls?
----

Links represent the state of all models of the same type.
Url's represent the resource location of a specific model or collection.

Whenever a `Certain.Model` is updated, created, or destroyed, the
`Certain.Model.link` is updated and triggers reloads on collections that rely
on that link.


RecordArrays, Relations?
----

RecordArrays are arrays that contain a single model type, url, and link.

Relations are modified `Ember.Array` objects that lazy load their contents
and can extend their parent Relation's query.

They can also be used to create new models.


Testing
----

    npm install
    cake test         # Headless
    cake test:server  # Livereload

Pull requests are welcome!
