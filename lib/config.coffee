module.exports = class Config
  getAccessToken: () ->
    process.env.FEEDLY_ACCESS_TOKEN # config:getで見えちゃうけどね

  setAccessToken: (token) ->
    process.env['FEEDLY_ACCESS_TOKEN'] = token

  getWhiteListCategories: () ->
    process.env.FEEDLY_WHITELIST_CATEGORIES.split(',')

  getBlackListCategories: () ->
    process.env.FEEDLY_BLACKLIST_CATEGORIES.split(',')

  getMarkAsReadCategories: () ->
    process.env.FEEDLY_MARK_AS_READ_CATEGORIES.split(',')
