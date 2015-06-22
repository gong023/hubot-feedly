Config = require '../lib/config'
Docomo = require 'docomo-api'
moment = require 'moment'

module.exports = (robot) ->

  robot.respond /(.*)/, (msg) ->
    query = msg.match[1]
    return if query.match(/(教えて|feed|ping|profile|help|image)/)
    c = new Config()
    params = c.getDocomoCharacter()
    docomo_client = new Docomo(c.getDocomoToken())

    context_timestamp = robot.brain.get 'docomo_context_timestamp' || moment().unix()
    if moment().unix() - context_timestamp > 60 * 15
      robot.brain.set 'docomo_context', ''
    else
      params['context'] = robot.brain.get 'docomo_context' || ''

    docomo_client.createDialogue(query, params, (err, data) ->
        msg.send(data.utt)
        robot.brain.set 'docomo_context', data.context
        robot.brain.set 'docomo_context_timestamp', moment().unix()
      )

  robot.respond /教えて (.*)/, (msg) ->
    c = new Config()
    query = msg.match[1]
    docomo_client = new Docomo(c.getDocomoToken())

    docomo_client.createKnowledgeQA(query, (err, data) ->
        msg.send(data.message.textForDisplay + ' ' + data.answers[0].linkUrl)
      )
