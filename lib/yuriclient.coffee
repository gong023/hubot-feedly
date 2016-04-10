Promise = require 'bluebird'
request = Promise.promisifyAll(require('request'))

module.exports = class YuriClient
  BASE_URL = 'https://glassof.garden/'

  following: () ->
    request.getAsync(
      uri: BASE_URL + 'following'
    )

