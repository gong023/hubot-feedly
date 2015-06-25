Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'
_       = require 'underscore'
async   = require 'asyncawait/async'
await   = require 'asyncawait/await'
cronJob = require('cron').CronJob
FeedlyClient = require '../lib/feedlyclient'
Config       = require '../lib/config'

feedTask = (msg) ->
  getFeed = async (newerThan) ->
    config = new Config()
    client = new FeedlyClient(config.getAccessToken())
    whiteListCategories = config.getWhiteListCategories()
    blackListCategories = config.getBlackListCategories()

    client.markCounts(newerThan)
    .spread (response, body) ->
      return Promise.reject(response) if response.statusCode isnt 200
      fIds =
        _.chain(JSON.parse(body).unreadcounts)
          .reject((content) -> content.count is 0 )
          .filter (content) ->
            # whitelist の指定も blacklist の指定もなかったら全部とる
            return true if whiteListCategories isnt undefined or blackListCategories isnt undefined
            content.id.match(/global\.all$/)
          .filter (content) ->
            # whitelist の指定があったらそれを適用
            return true if whiteListCategories is undefined
            return false if content.id.match(/^user\/.+\/category\/(.+)$/) is null
            _.contains(whiteListCategories, content.id.match(/^user\/.+\/category\/(.+)$/)[1])
          .reject (content) ->
            # blacklist の指定があったらそれを適用
            return false if blackListCategories is undefined
            return true if content.id.match(/^user\/.+\/category\/(.+)$/) is null
            _.contains(blackListCategories, content.id.match(/^user\/.+\/category\/(.+)$/)[1])
          .map((content) -> content.id)
          .value()
      return Promise.resolve(fIds)
    .catch (response) ->
      msg.send 'markCountsが失敗してしまいました'
      msg.send JSON.stringify(response)
    .then (fIds) ->
      console.log(fIds)

    console.log(feedIds)
    return if !feedIds || feedIds.length is 0
    responseItems = []
    _.each(feedIds, (feedId) ->
        client.streamContents(feedId)
        .spread (response, body) ->
          return Promise.reject(response, body) if response.statusCode isnt 200
          # newerThan が期待通りに動かない
          #items = _.filter(JSON.parse(response[0].body).items, (item) -> parseInt(item.crawled) > newerThan)
          items = _.last(JSON.parse(body).items, 10) # 多すぎるとbotのプロセスが死ぬ？
          _.each items, (item) ->
                msg.send item.title
                msg.send item.alternate[0].href
                responseItems.push item
        .error (response, body) ->
          msg.send 'streamContentsが失敗してしまいました'
          msg.send JSON.stringify(response)
          msg.send JSON.stringify(body)
      )

    markCategories = config.getMarkAsReadCategories()
    return if markCategories is undefined
    markFeeds = _.chain(responseItems)
                .map((responseItem) ->
                  label = responseItem.categories[0].label
                  if _.contains(markCategories, label) then responseItem.id else ''
                )
                .compact()
                .value()
    client.markEntriesAsRead(markFeeds)
    .then (response) ->
      if response[0].statusCode isnt 200
        msg.send '既読つけるのに失敗してしまいました'
        msg.send JSON.stringify(response[0].body)

  twentyMinAgo = moment().subtract(20, 'minutes').valueOf()
  getFeed(twentyMinAgo)

class MessageDecorator
  constructor: (@robot, @env) ->

  send: (message) ->
    @robot.send(@env, message)

module.exports = (robot) ->
  new cronJob('*/20 * * * *', () ->
    c = new Config()
    msg = new MessageDecorator(robot, {room: c.getFeedlyRoomName()})
    feedTask(msg)
  ).start()

  robot.respond /feed$/i, (msg) ->
    feedTask(msg)

  robot.respond /help token/i, (msg) ->
    msg.send 'アクセストークンを作るリンクはこれです'
    msg.send 'https://feedly.com/v3/auth/dev'
    msg.send '詳しいことはここを見て下さい'
    msg.send 'https://groups.google.com/forum/#!topic/feedly-cloud/YHLdeRAkn-c'
    msg.send 'アクセストークンがとれたら環境変数FEEDLY_ACCESS_TOKENに入れてください'

  robot.respond /profile$/i, (msg)->
    config = new Config()
    client = new FeedlyClient(config.getAccessToken())
    client.profile()
    .spread (response, body) ->
      msg.send response.body
