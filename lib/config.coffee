Config =
  getAccessToken: () ->
    process.env.FEEDLY_ACCESS_TOKEN

  getWhiteListCategories: () ->
    process.env.FEEDLY_WHITELIST_CATEGORIES.split(',') if process.env.FEEDLY_WHITELIST_CATEGORIES isnt undefined

  getBlackListCategories: () ->
    process.env.FEEDLY_BLACKLIST_CATEGORIES.split(',') if process.env.FEEDLY_BLACKLIST_CATEGORIES isnt undefined

  getMarkAsReadCategories: () ->
    process.env.FEEDLY_MARK_AS_READ_CATEGORIES.split(',') if process.env.FEEDLY_MARK_AS_READ_CATEGORIES isnt undefined

  getFeedlyRoomName:() ->
    process.env.FEEDLY_ROOM_NAME

  getDocomoToken: () ->
    process.env.HUBOT_DOCOMO_TOKEN

  getDocomoCharacter: () ->
    JSON.parse(process.env.HUBOT_DOCOMO_CHARACTER) if process.env.HUBOT_DOCOMO_CHARACTER isnt undefined

  getTumblrConsumerKey: () ->
    process.env.TUMBLR_CONSUMER_KEY

  getTumblrConsumerSecret: () ->
    process.env.TUMBLR_CONSUMER_SECRET

  getTumblrToken: () ->
    process.env.TUMBLR_TOKEN

  getTumblrTokenSecret: () ->
    process.env.TUMBLR_TOKEN_SECRET

  getTumblrApiKey: () ->
    process.env.TUMBLR_API_KEY

module.exports = Config
