Config  = require('../config')
Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
_      　= require('underscore')

class Item
  constructor: (@item) ->

  title: () ->
    @item.title

  hrefs: () ->
    return Promise.reject('item alternate is not found') if !@item.alternate || !@item.alternate[0]
    rawHref = @item.alternate[0].href
    if rawHref.match(/tumblr/)
      t = new TumblrHref(rawHref)
      return t.convertToImage()
    Promise.resolve([rawHref])

class TumblrHref
  constructor: (@rawHref) ->

  convertToImage: () ->
    request.getAsync(
        uri: 'http://api.tumblr.com/v2/blog/' + this.blogName() + '/posts'
        qs:
          id: this.postId()
          api_key: Config.getTumblrApiKey()
    ).spread (response, body) ->
      body = JSON.parse(body)
      return Promise.reject(body.meta.msg) if body.meta.status isnt 200
      return Promise.resolve(_.map(body.response.posts, (post) -> post.post_url)) if body.response.posts[0].type isnt 'photo'
      return Promise.resolve(_.map(body.response.posts[0].photos, (photo) -> photo.original_size.url))

  blogName: () ->
    match = @rawHref.match(/^http:\/\/(.*)\/post\/\d+/)
    if match is null
      console.log('fail to match blogName: ' + @rawHref)
      return @rawHref
    return match[1]

  postId: () ->
    match = @rawHref.match(/^http:\/\/.*\/post\/(\d+)$/)
    if match is null
      console.log('fail to match postId: ' + @rawHref)
      return @rawHref
    return match[1]

module.exports = Item
