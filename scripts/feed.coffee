Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'

class FeedlyClient
  BASE_URL = "https://sandbox.feedly.com/"

  constructor: (@client_id, @client_secret, @access_token = null, @refresh_token) ->
    @authHeader = Authorization: "Bearer " + @access_token

  profile: () ->
    request.getAsync(
      uri: BASE_URL + 'v3/profile'
      headers: @authHeader
    )
    .spread (response, body) ->
      console.log("%j", response)

  auth: (code) ->
    request.postAsync(
      uri: BASE_URL + 'v3/auth/token'
      form:
        code: code
        client_id: @client_id
        client_secret: @client_secret
        redirect_uri: 'http://localhost/'
        grant_type: 'authorization_code'
    )

  fetchFeed: (newerThan) ->
    request.getAsync(
      uri: 'https://cloud.feedly.com/v3/streams/contents?unreadOnly=true&newerThan=' + newerThan
      headers: @authHeader
    )

module.exports = (robot) ->
  robot.respond /code$/i, (msg) ->
    msg.send 'このURLをブラウザで開いて下さい'
    msg.send "https://sandbox.feedly.com/v3/auth/auth?redirect_uri=http://localhost&scope=https://cloud.feedly.com/subscriptions&response_type=code&provider=google&client_id=" + process.env.FEEDLY_CLIENT_ID
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
    fiveMinAgo = moment().subtract(5, 'minutes')
    client = new FeedlyClient(process.env.FEEDLY_ACCESS_TOKEN)
    client.fetchFeed(fiveMinAgo)
    .spread (response, body) =>
      if response.statusCode isnt '200'
        msg.send 'failed!'
        console.warn('%j', response)
      else
        JSON.parse(response)
