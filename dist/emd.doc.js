Ember.TEMPLATES['index'] = Ember.Handlebars.template(function (Handlebars,depth0,helpers,partials,data) {
  this.compilerInfo = [4,'>= 1.0.0'];
helpers = this.merge(helpers, Handlebars.helpers); data = data || {};
  


  return "index! ";
  });
var Doc;

Doc = Em.Application.create({
  posts: [],
  LOG_TRANSITIONS: true,
  LOG_VIEW_LOOKUPS: true,
  LOG_ACTIVE_GENERATION: true
});

Doc.Post = Em.Object.extend();
var content;

content = "First post==========content!";

Doc.posts.pushObject(Doc.Post.create({
  date: moment("oct 30th 2013"),
  content: (new Markdown.Converter()).makeHtml(content)
}));
