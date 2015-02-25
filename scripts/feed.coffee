Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
fs      = Promise.promisifyAll(require('fs'))

class FeedlyClient
  constructor: (@access_token) ->
    @authHeader = Authorization: "Bearer " + @access_token

  profile: () ->
    request.getAsync(
      uri: 'https://cloud.feedly.com/v3/profile'
      headers: @authHeader
    )
    .spread (response, body) ->
      console.log("%j", response)

module.exports = (robot) ->
  robot.respond /token$/i, (msg) ->
    msg.send 'client id作らないと無理じゃない？'

  robot.respond /feed$/i, (msg) ->
    msg.send 'now implementing'
    client = new FeedlyClient(process.env.FEEDLY_ACCESS_TOKEN)
    client.profile()
