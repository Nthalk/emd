content = "
First post
==========

content!

"

Doc.posts.pushObject Doc.Post.create
  date: moment("oct 30th 2013")
  content: (new Markdown.Converter()).makeHtml content
