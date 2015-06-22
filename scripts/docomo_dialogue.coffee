Config = require '../lib/config'
Docomo = require 'docomo-api'

request = require('request').defaults({
  strictSSL: false
})

module.exports = (robot) ->

  robot.respond /(.*)/, (msg) ->
    c = new Config()
    query = msg.match[1]
    params = c.getDocomoCharacter()
    docomo_client = new Docomo(c.getDocomoToken())

    docomo_client.createDialogue(query, params, (err, data) ->
        msg.send(data.utt)
      )
