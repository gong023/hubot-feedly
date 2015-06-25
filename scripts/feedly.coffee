Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'
_       = require 'underscore'
cronJob = require('cron').CronJob
Stream  = require '../lib/feedly/stream'
FeedlyClient = require '../lib/feedly/client'
Config       = require '../lib/config'

feedTask = (msg, newerThan) ->
  client = new FeedlyClient(Config.getAccessToken())
  Stream.feedIds(client.markCounts(newerThan))
  .catch (response) ->
    msg.send 'markCountsが失敗してしまいました'
    msg.send JSON.stringify(response)
  .then (feedIds) ->
    if !feedIds || feedIds.length is 0
      console.log 'there is no feed.'
      return Promise.reject()
    console.log(feedIds)
    Promise.resolve(feedIds)

class MessageDecorator
  constructor: (@robot, @env) ->

  send: (message) ->
    @robot.send(@env, message)

module.exports = (robot) ->
  new cronJob('*/20 * * * *', () ->
    msg = new MessageDecorator(robot, {room: Config.getFeedlyRoomName()})
    feedTask(msg, moment().subtract(20, 'minutes').valueOf())
  ).start()

  robot.respond /feed$/i, (msg) ->
    feedTask(msg, moment().subtract(20, 'minutes').valueOf())

  robot.respond /help token/i, (msg) ->
    msg.send 'アクセストークンを作るリンクはこれです'
    msg.send 'https://feedly.com/v3/auth/dev'
    msg.send '詳しいことはここを見て下さい'
    msg.send 'https://groups.google.com/forum/#!topic/feedly-cloud/YHLdeRAkn-c'
    msg.send 'アクセストークンがとれたら環境変数FEEDLY_ACCESS_TOKENに入れてください'

  robot.respond /profile$/i, (msg)->
    client = new FeedlyClient(Config.getAccessToken())
    client.profile()
    .spread (response, body) ->
      msg.send response.body
