Promise      = require 'bluebird'
_            = require 'underscore'
YuriClient = require '../lib/yuriclient'

module.exports = (robot) ->
  robot.respond /yuri$/i, (msg) ->
    client = new YuriClient()
    client.following()
    .spread (response, body) ->
      Promise.reject(response, body) if response.statusCode isnt 200
      body = JSON.parse(body)
      _.each body.works, (work) ->
        attachments = []
        _.each work.links, (link, i) ->
          attachments.push({text: i, image_url: link})

        robot.emit 'slack.attachment',
          message: msg.message
          text: work.caption
          attachments: attachments
    .catch (response, body) ->
      msg.send JSON.stringify(response)
      msg.send JSON.stringify(body)

