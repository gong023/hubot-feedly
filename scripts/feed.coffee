Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'
_       = require 'underscore'
async   = require 'asyncawait/async'
await   = require 'asyncawait/await'

class FeedlyClient
  BASE_URL = 'https://sandbox.feedly.com/'
  REDIRECT_URL = 'http://localhost'

  constructor: (@client_id, @client_secret, @access_token = null, @refresh_token = null) ->
    @authHeader = Authorization: "Bearer " + @access_token

  profile: () ->
    request.getAsync(
      uri: BASE_URL + 'v3/profile'
      headers: @authHeader
    )
    .spread (response, body) ->
      console.log("%j", response)

  codeUrl: () ->
    BASE_URL + 'v3/auth/auth?scope=https://cloud.feedly.com/subscriptions&response_type=code&provider=google&client_id=' + @client_id + '&redirect_uri=' + REDIRECT_URL

  auth: (code) ->
    request.postAsync(
      uri: BASE_URL + 'v3/auth/token'
      form:
        code: code
        client_id: @client_id
        client_secret: @client_secret
        redirect_uri: REDIRECT_URL
        grant_type: 'authorization_code'
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
  robot.respond /code$/i, (msg) ->
    client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET)
    msg.send 'このURLをブラウザで開いて下さい'
    msg.send client.codeUrl()
    msg.send '認証したら、「code」パラメータをコピーして私に話しかけて下さい。こんな感じに'
    msg.send 'hubot token XXX(codeの値)'

  robot.respond /token (.*)/i, (msg) ->
    msg.send '今度はリフレッシュトークンとアクセストークンを作ります。'
    client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET)
    client.auth(msg.match[1])
    .then (response) ->
      return Promise.reject(response) if response[0].statusCode isnt 200
      body = JSON.parse(response[0].body)
      process.env['FEEDLY_ACCESS_TOKEN'] = body.access_token
      process.env['FEEDLY_REFRESH_TOKEN'] = body.refresh_token
      msg.send 'トークンが作れました'
    .error (response) ->
      msg.send '失敗してしまいました'
      msg.send JSON.stringify(response[0].body)

  robot.respond /profile$/i, (msg)->
    client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET, process.env.FEEDLY_ACCESS_TOKEN)
    client.profile()

  robot.respond /feed$/i, (msg) ->
    getFeed = async (newerThan) ->
      client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET, process.env.FEEDLY_ACCESS_TOKEN)
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
