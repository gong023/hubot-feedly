Config = require '../lib/config'
Docomo = require 'docomo-api'
moment = require 'moment'

module.exports = (robot) ->

  robot.respond /(.*)/, (msg) ->
    query = msg.match[1]
    return if query.match(/(教えて|feed|ping|profile|help|image|animate|yuri)/)
    params = Config.getDocomoCharacter()
    docomoClient = new Docomo(Config.getDocomoToken())

    contextTimestamp = robot.brain.get 'docomo_context_timestamp' || moment().unix()
    if moment().unix() - contextTimestamp > 60 * 15
      robot.brain.set 'docomo_context', ''
    else
      params['context'] = robot.brain.get 'docomo_context' || ''

    docomoClient.createDialogue(query, params, (err, data) ->
        msg.send(data.utt)
        robot.brain.set 'docomo_context', data.context
        robot.brain.set 'docomo_context_timestamp', moment().unix()
      )

  robot.respond /教えて (.*)/, (msg) ->
    query = msg.match[1]
    docomoClient = new Docomo(Config.getDocomoToken())

    docomoClient.createKnowledgeQA(query, (err, data) ->
        msg.send(data.message.textForDisplay + ' ' + data.answers[0].linkUrl)
      )
