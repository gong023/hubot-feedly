Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))
moment  = require 'moment'
_       = require 'underscore'
async   = require 'asyncawait/async'
await   = require 'asyncawait/await'
FeedlyClient = require '../lib/feedlyclient'
Config       = require '../lib/config'

module.exports = (robot) ->
  robot.respond /help token/i, (msg) ->
    msg.send 'アクセストークンを作るリンクはこれです'
    msg.send 'https://feedly.com/v3/auth/dev'
    msg.send '詳しいことはここを見て下さい'
    msg.send 'https://groups.google.com/forum/#!topic/feedly-cloud/YHLdeRAkn-c'
    msg.send 'トークンをセットしたかったらこれで”set token XXX(アクセストークンの値)"'

  robot.respond /set token (.*)/i, (msg) ->
    msg.send '雑にアクセストークンを取り込みます'
    Config.setAccessToken msg.match[1]
    msg.send 'すごく雑に持ってるから扱いに気をつけて'

  robot.respond /profile$/i, (msg)->
    config = new Config()
    client = new FeedlyClient(config.getAccessToken())
    client.profile()
    .spread (response, body) ->
      msg.send response.body

  robot.respond /feed$/i, (msg) ->
    getFeed = async (newerThan) ->
      config = new Config()
      client = new FeedlyClient(config.getAccessToken())
      feedIds = await client.markCounts(newerThan)
      .then (response) ->
        return Promise.reject(response) if response[0].statusCode isnt 200
        _.chain(JSON.parse(response[0].body).unreadcounts)
          .filter((content) ->
            return true if not config.getWhiteListCategories()? and not config.getBlackListCategories()?
            content.id.match(/global\.all$/)
          )
          .filter((content) ->
            return true if not config.getWhiteListCategories()?
            console.log 'a'
            category = config.id.match(/^user\/.+\/category\/(.+)$/)[1]
            _.contains(config.getWhiteListCategories(), category)
          )
          .reject((content) ->
            return false if not config.getBlackListCategories()?
            console.log 'b'
            category = config.id.match(/^user\/.+\/category\/(.+)$/)[1]
            _.contains(config.getBlackListCategories(), category)
          )
          .map((content) -> content.id)
          .value()
      .error (response) ->
        msg.send 'markCountsが失敗してしまいました'
        msg.send JSON.stringify(response[0].body)

      return if !feedIds || feedIds.length is 0
      _.each(feedIds, (feedId) ->
          client.streamContents(feedId)
          .then (response) ->
            return Promise.reject(response) if response[0].statusCode isnt 200
            _.each(JSON.parse(response[0].body).items, (item) ->
                msg.send item.title
                msg.send item.alternate[0].href
              )
          .error (response) ->
            msg.send 'streamContentsが失敗してしまいました'
            msg.send JSON.stringify(response[0].body)
        )

    #fiveMinAgo = moment().subtract(5, 'minutes').valueOf()
    fiveMinAgo = moment().subtract(1, 'hours').valueOf()
    getFeed(fiveMinAgo)
