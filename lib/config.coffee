module.exports = class Config

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
