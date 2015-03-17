Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))

module.exports = class FeedlyClient
  BASE_URL = 'https://cloud.feedly.com/'

  constructor: (@access_token) ->
    @authHeader = Authorization: "Bearer " + @access_token

  profile: () ->
    request.getAsync(
      uri: BASE_URL + 'v3/profile'
      headers: @authHeader
    )

  markCounts: (newerThan = null) ->
    request.getAsync(
      uri: BASE_URL + 'v3/markers/counts'
      headers: @authHeader
      qs:
        newerThan
    )

  streamContents: (feedId) ->
    request.getAsync(
      uri: BASE_URL + 'v3/streams/contents'
      headers: @authHeader
      qs:
        streamId: feedId
        unreadOnly: true
    )
