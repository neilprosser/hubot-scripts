# Description:
#   Allows Hubot to chat about Seyren.
#   Seyren can be found here: https://github.com/scobal/seyren
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SEYREN_URL
#
# Commands:
#   hubot seyren list - list all enabled Seyren checks and their state
#   hubot seyren broken - list all enabled Seyren checks which are not in an OK state
#
# Author:
#   neilprosser

QS = require "querystring"
module.exports = (robot) ->

  displayChecks = (msg, res, body) ->
    status = res.statusCode
    if status is 200
      data = JSON.parse(body)
      checks = data.values
      if checks.length == 0
        msg.send "I've got nothing to show you"
      else
        response = ""
        for check in checks
          state = switch check.state
            when "OK" then "OK     "
            when "WARN" then "WARN   "
            when "ERROR" then "ERROR  "
            else "UNKNOWN"
          response += "#{state} | #{check.name}\n"
        msg.send response
    else
      msg.send "Something broke. I got a response code of #{status}"

  robot.respond /seyren list/i, (msg) ->
    url = process.env.HUBOT_SEYREN_URL
    msg.http("#{url}/api/checks?enabled=true")
      .get() (err, res, body) ->
        displayChecks(msg, res, body)

  robot.respond /seyren broken/i, (msg) ->
    url = process.env.HUBOT_SEYREN_URL
    msg.http("#{url}/api/checks?enabled=true&state=ERROR&state=WARN")
      .get() (err, res, body) ->
        displayChecks(msg, res, body)

  robot.router.post "/hubot/seyren/alert", (req, res) ->
    seyrenUrl = req.body.seyrenUrl
    rooms = req.body.rooms
    check = req.body.check
    alerts = req.body.alerts
    res.end "Thanks for letting me know"

    message = "Seyren is saying that #{check.name} changed state:\n"

    for alert in alerts
      message += "- #{alert.target} has gone from #{alert.fromType} to #{alert.toType} with #{alert.value}\n"

    message += "The warning value is #{check.warn} and the error value is #{check.error}.\n"
    message += "#{seyrenUrl}/#/checks/#{check.id}"

    for room in rooms
      robot.messageRoom room, message