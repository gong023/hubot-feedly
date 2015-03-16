Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'
_       = require 'underscore'
async   = require 'asyncawait/async'
await   = require 'asyncawait/await'

class FeedlyClient
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
      uri: BASE_URL + 'v3/markers/counts?newerThan=' + newerThan
      headers: @authHeader
    )


  streamContents: (feedId) ->
    request.getAsync(
      uri: BASE_URL + 'v3/streams/' + feedId + '/contents?unreadOnly=true'
      headers: @authHeader
    )

module.exports = (robot) ->
  robot.respond /help token/i, (msg) ->
    msg.send 'アクセストークンを作るリンクはこれです'
    msg.send 'https://feedly.com/v3/auth/dev'
    msg.send '詳しいことはここを見て下さい'
    msg.send 'https://groups.google.com/forum/#!topic/feedly-cloud/YHLdeRAkn-c'
    msg.send 'トークンをセットしたかったらこれで set token XXX(アクセストークンの値)'

  robot.respond /set token (.*)/i, (msg) ->
    msg.send '雑にアクセストークンを取り込みます'
    process.env['FEEDLY_ACCESS_TOKEN'] = msg.match[1]
    msg.send 'すごく雑に持ってるから扱いに気をつけて'

  robot.respond /profile$/i, (msg)->
    client = new FeedlyClient(process.env.FEEDLY_ACCESS_TOKEN)
    client.profile()
    .spread (response, body) ->
      console.log("%j", response)

  robot.respond /feed$/i, (msg) ->
    getFeed = async (newerThan) ->
      client = new FeedlyClient(process.env.FEEDLY_ACCESS_TOKEN)
      feedIds = await client.markCounts(newerThan)
      .then (response) ->
        return Promise.reject(response) if response[0].statusCode isnt 200
        console.log response[0].body
        _.chain(JSON.parse(response[0].body).unreadcounts)
          .filter((content) -> content.count isnt 0)
          .map((content) -> content.id)
      .error (response) ->
        msg.send '失敗してしまいました'
        msg.send JSON.stringify(response[0].body)

      return if not feedIds?
      contents = []
      _.each(feedIds, (feedId) ->
          msg.send feedId
          content = await client.streamContents(feedId)
          .then (response) ->
            return Promise.reject(response) if response[0].statusCode isnt 200
            console.log '%j', JSON.parse(response[0].body)
          .error (response) ->
            msg.send '失敗してしまいました'
            msg.send JSON.stringify(response[0].body)
        )

    #fiveMinAgo = moment().subtract(5, 'minutes').valueOf()
    fiveMinAgo = moment().subtract(5, 'days').valueOf()
    getFeed(fiveMinAgo)
