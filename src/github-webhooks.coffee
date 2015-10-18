# Available GitHub Events
# githubEventTypes = ["commit_comment", "create", "delete", "deployment", "deployment_status", "fork",
#                     "gollum", "issue_comment", "issues", "member", "membership", "page_build", "public",
#                     "pull_request_review_comment", "pull_request", "push", "repository", "release",
#                     "status", "team_add", "watch", "ping"]

url = require('url')
querystring = require('querystring')

eventActions = require('./github-events/all')
eventTypes = ["commit_comment:*", "create", "delete", "deployment", "deployment_status", "fork", "issue_comment:*", "issues:*", "pull_request_review_comment", "pull_request:*", "push", "repository", "status", "ping"]
htmlError = "<span class='octicon octicon-alert'></span>"
htmlNotify = "<span class='octicon octicon-megaphone'>"


module.exports = (robot) ->
  robot.router.post "/hubot/github-repo-events", (request, response) ->
    query = querystring.parse(url.parse(request.url).query)

    data = request.body
    room = query.room || process.env["HUBOT_GITHUB_EVENT_NOTIFIER_ROOM"]
    eventType = request.headers["x-github-event"]
    console.log "Processing event type #{eventType}..."

    try
      filter_parts = eventTypes
        .filter (e) ->
          # should always be at least two parts, from eventTypes creation above
          parts = e.split(":")
          event_part = parts[0]
          action_part = parts[1]

          if event_part != eventType
            return false # remove anything that isn't this event

          if action_part == "*"
            return true # wildcard on this event

          if !data.hasOwnProperty('action')
            return true # no action property, let it pass

          if action_part == data.action
            return true # action match

          return false # no match, fail

      if filter_parts.length > 0
        announceRepoEvent data, eventType, (what) ->
          robot.messageRoom room, what
      else
        console.log "ignoring #{eventType}:#{data.action} as it's not allowed."
    catch error
      robot.messageRoom room, "#{htmlError} we received a(n) #{error}"
      console.log "GitHub repo event notifier error: #{error}. Request: #{request.body}"

    response.statusCode = 200
    response.statusMessage = 'SUCCESS'
    response.end ""

announceRepoEvent = (data, eventType, cb) ->
  if eventActions[eventType]?
    eventActions[eventType](data, cb)
  else
    cb("#{htmlNotify} received a new #{eventType} event, just so you know.")
