# Description
#   Listen for Webhook Events
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot hello - <what the respond trigger does>
#   orly - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Lee Faus <leefaus@github.com>

url = require('url')
querystring = require('querystring')
require('./github-webhooks')

module.exports = (robot) ->
  robot.router.post "/hubot/test", (request, response) ->
    query = querystring.parse(url.parse(request.url).query)
    data = request.body
    room = query.room
    eventName = "test"
    eventType = request.headers["x-test-event"]
    message = "<span class='octicon octicon-megaphone'></span> Received a new #{eventType} event, just so you know!"
    robot.messageRoom room, message
    response.statusCode = 200
    response.statusMessage = 'SUCCESS'
    response.end ""
