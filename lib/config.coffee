module.exports = class Config
  getAccessToken: () ->
    process.env.FEEDLY_ACCESS_TOKEN # config:getで見えちゃうけどね

  setAccessToken: (token) ->
    process.env['FEEDLY_ACCESS_TOKEN'] = token

  getWhiteListCategories: () ->
    return null if !process.env.FEEDLY_WHITELIST_CATEGORIES
    process.env.FEEDLY_WHITELIST_CATEGORIES.split(',')

  getBlackListCategories: () ->
    return null if !process.env.FEEDLY_BLACKLIST_CATEGORIES
    process.env.FEEDLY_BLACKLIST_CATEGORIES.split(',')

  getMarkAsReadCategories: () ->
    return null if !process.env.FEEDLY_MARK_AS_READ_CATEGORIES
    process.env.FEEDLY_MARK_AS_READ_CATEGORIES.split(',')
