fs   = require('fs')
path = require('path')

module.exports = class Config

  file: () ->
    'feedly_access_token.txt'

  getAccessToken: () ->
    try
      fs.readFileSync(this.file(), {encodinf: 'utf8'})
    catch e
      console.error(e)

  setAccessToken: (token) ->
    fs.writeFileSync(this.file(), token)

  getWhiteListCategories: () ->
    process.env.FEEDLY_WHITELIST_CATEGORIES.split(',') if process.env.FEEDLY_WHITELIST_CATEGORIES isnt undefined

  getBlackListCategories: () ->
    process.env.FEEDLY_BLACKLIST_CATEGORIES.split(',') if process.env.FEEDLY_BLACKLIST_CATEGORIES isnt undefined

  getMarkAsReadCategories: () ->
    process.env.FEEDLY_MARK_AS_READ_CATEGORIES.split(',') if process.env.FEEDLY_MARK_AS_READ_CATEGORIES isnt undefined
