Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'

class FeedlyClient
  BASE_URL = "https://sandbox.feedly.com/"

  constructor: (@client_id, @client_secret, @access_token = null) ->
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
      json:
        code: code
        client_id: @client_id
        client_secret: @client_secret
        redirect_uri: encodeURIComponent('http://localhost')
        grant_type: 'authorization_code'
    )
    .then (response) ->
      console.log(response)
      reject new Error(response) if response.statusCode isnt 200
      console.log '%j', response.body
    .catch (response) ->
      # msg.send '失敗してしまいました'
      console.log response

  refresh: (refresh_token) ->
    request.postAsync(
      uri: BASE_URL + 'v3/auth/token'
      headers: @authHeader
      json:
        refresh_token: refresh_token
        client_id: @client_id
        client_secret: @client_secret
        grant_type: 'refresh_token'
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
    code = msg.match[1]
    client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET)
    client.auth(code)

  robot.respond /refresh$/i, (msg)->
    client = new FeedlyClient(process.env.FEEDLY_CLIENT_ID, process.env.FEEDLY_CLIENT_SECRET, process.env.FEEDLY_ACCESS_TOKEN)
    client.refresh(process.env.FEEDLY_REFRESH_TOKEN)
    .then (contents) ->
      console.log('%j',contents)

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
