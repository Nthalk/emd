describe 'EMD.Model', ->
  it 'should have a baseUrl', ->
    App.User = EMD.Model.extend
      baseUrl: base_url = "/user"

    user = App.User.load id: id = 5
    expect(user.get("url")).to.equal base_url + "/#{id}"

    user = App.User.create()
    expect(user.get("url")).to.equal base_url

  it 'should load data from the baseUrl', (done)->
    App.User = EMD.Model.extend
      baseUrl: base_url = "/users"
      name: EMD.attr 'name'

    user = App.User.find 1

    expect(user.get "isLoading").to.equal true
    expect(user.get "isLoaded").to.equal false

    response = JSON.stringify user: {id: 1, name: name = "carl"}
    headers = {"Content-Type": "application/json"}
    @xhr.requests[0].respond 200, headers, response

    user.then ->
      expect(user.get "isLoading").to.equal false
      expect(user.get "isLoaded").to.equal true
      expect(user.get 'name').to.equal name
      done()
