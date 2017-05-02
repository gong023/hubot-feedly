Promise      = require 'bluebird'
_            = require 'underscore'
mysql        = require 'mysql'
cronJob      = require('cron').CronJob
YuriClient   = require '../lib/yuriclient'
Config       = require '../lib/config'

class MysqlClient
  constructor: () ->
    @connection = mysql.createConnection
      host: Config.getMysqlHost(),
      user: Config.getMysqlUser(),
      password: Config.getMysqlPassword(),
      database: Config.getMysqlDatabase()
    @connection.connect()

  getByWorkId: (workId) ->
    Promise.promisify(@connection.query, @connection)('select * from read_works where work_id = ?', [workId])

  addWorkId: (workId) ->
    Promise.promisify(@connection.query, @connection)('insert ignore into read_works values (?)', [workId])

  disconnect: () ->
    @connection.end()

yuriTask = (robot) ->
  if !Config.IsAvailableYuri()
    return
  client = new YuriClient()
  client.following()
  .spread (response, body) ->
    if response.statusCode isnt 200
      return Promise.reject(response, body)
    body = JSON.parse(body)
    _.each body.works, (work) =>
      attachments = []
      mysqlClient = new MysqlClient()
      mysqlClient.getByWorkId(work.id)
      .spread (rows, conn) ->
        if rows.length >= 1
          robot.logger.info(work.id + ' already exists')
          return Promise.resolve(conn)
        _.each work.links, (link, i) ->
          attachments.push({text: i, image_url: link})
        robot.emit 'slack.attachment',
          channel: Config.getYuriRoomName()
          text: work.caption
          attachments: attachments
        mysqlClient.addWorkId(work.id)
      .then () ->
        mysqlClient.disconnect()
  .catch (response, body) ->
    robot.send(JSON.stringify(response))
    robot.send(JSON.stringify(body))

module.exports = (robot) ->
  robot.respond /yuri$/i, () ->
    yuriTask(robot)

  new cronJob('*/20 * * * *', () ->
    yuriTask(robot)
  ).start()

