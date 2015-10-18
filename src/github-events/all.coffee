#! /usr/bin/env coffee

#commit_comment,create,delete,deployment,deployment_status,fork,gollum,issue_comment,issues,member,membership,page_build,pull_request_review_comment,pull_request,push,repository,release,status,ping,team_add,watch
htmlError = "<span class='octicon octicon-alert'></span>"
htmlNotify = "<span class='octicon octicon-megaphone'></span>"
htmlPullRequest = "<span class='octicon octicon-git-pull-request'></span>"
htmlIssue = "<span class='octicon octicon-issue-opened'></span>"
htmlCommit = "<span class='octicon octicon-git-commit'></span>"
htmlFork = "<span class='octicon octicon-repo-forked'></span>"
htmlDeploy = "<span class='octicon octicon-squirrel'></span>"
htmlComment = "<span class='octicon octicon-comment-discussion'></span>"
htmlNotify = "<span class='octicon octicon-megaphone'></span>"
htmlRelease = "<span class='octicon octicon-package'></span>"
htmlWatch = "<span class='octicon octicon-eye'></span>"
htmlBranch = "<span class='octicon octicon-git-branch'></span>"



unique = (array) ->
  output = {}
  output[array[key]] = array[key] for key in [0...array.length]
  value for key, value of output

extractMentionsFromBody = (body) ->
  mentioned = body.match(/(^|\s)(@[\w\-\/]+)/g)

  if mentioned?
    mentioned = mentioned.filter (nick) ->
      slashes = nick.match(/\//g)
      slashes is null or slashes.length < 2

    mentioned = mentioned.map (nick) -> nick.trim()
    mentioned = unique mentioned

    "\nMentioned: #{mentioned.join(", ")}"
  else
    ""

module.exports =
  commit_comment: (data, callback) ->
    comment = data.comment
    repo = data.repository

    callback "#{htmlComment} new comment by #{comment.user.login}
    on commit <a target='_blank' href='#{comment.html_url}'>#{comment.commit_id}</a>"

  create: (data, callback) ->
    repo = data.repository
    ref_type = data.ref_type
    ref = data.ref

    if ref_type is "branch"
      msg = "#{htmlBranch} "
    else
      msg = "#{htmlNotify} "

    callback msg += "new #{ref_type} #{ref} created on #{repo.full_name}"

  delete: (data, callback) ->
    repo = data.repository
    ref_type = data.ref_type

    ref = data.ref.split('refs/heads/').join('')

    callback "#{htmlNotify} #{ref_type} #{ref} deleted on #{repo.full_name}"

  deployment: (data, callback) ->
    deploy = data.deployment
    repo = data.repository

    callback "#{htmlDeploy} new deployment #{deploy.id} from: #{repo.full_name} to: #{deploy.environment} started by: #{deploy.creator.login}"

  deployment_status: (data, callback) ->
    deploy = data.deployment
    deploy_status = data.deployment_status
    repo = data.repository

    callback "#{htmlNotify} deployment #{deploy.id} from: #{repo.full_name} to: #{deploy.environment} - #{deploy_status.state} by #{deploy.status.creator.login}"

  fork: (data, callback) ->
    forkee = data.forkee
    repo = data.repository

    callback "#{htmlFork} #{repo.full_name} forked by #{forkee.owner.login}"

  # Needs to handle more then just one page
  gollum: (data, callback) ->
    pages = data.pages
    repo = data.repository
    sender = data.sender

    page = pages[0]

    callback "#{htmlNotify} wiki page: #{page.page_name} #{page.action} on #{repo.full_name} by #{sender.login}"

  issues: (data, callback) ->
    issue = data.issue
    repo = data.repository
    action = data.action
    sender = data.sender

    msg = "#{htmlIssue} issue <strong>\##{issue.number}</strong> <a target='_blank' href='#{issue.html_url}'>#{issue.title}</a>"

    switch action
      when "assigned"
        msg += " assigned to: #{issue.assignee.login} by #{sender.login} "
      when "unassigned"
        msg += " unassigned #{data.assignee.login} by #{sender.login} "
      when "opened"
        msg += " opened by #{sender.login} "
      when "closed"
        msg += " closed by #{sender.login} "
      when "reopened"
        msg += " reopened by #{sender.login} "
      when "labeled"
        msg += " #{sender.login} added label: \"#{data.label.name}\" "
      when "unlabeled"
        msg += " #{sender.login} removed label: \"#{data.label.name}\" "

    callback msg

  issue_comment: (data, callback) ->
    issue = data.issue
    comment = data.comment
    repo = data.repository

    issue_pull = "issue"

    if comment.html_url.indexOf("/pull/") > -1
      issue_pull = "pull request"

    callback "#{htmlComment} new <a target='_blank' href='#{comment.html_url}'>comment</a> on <strong>#{issue_pull} #{issue.number}</strong> by #{comment.user.login}"

  member: (data, callback) ->
    member = data.member
    repo = data.repository

    callback "#{htmlNotify} member #{member.login} #{data.action} from #{repo.full_name}"

  # Org level event
  membership: (data, callback) ->
    scope = data.scope
    member = data.member
    team = data.team
    org = data.organization

    callback "#{htmlNotify} #{org.login} #{data.action} #{member.login} to #{scope} #{team.name}"

  page_build: (data, callback) ->
    build = data.build
    repo = data.repository
    if build?
      if build.status is "built"
        callback "#{htmlNotify} #{build.pusher.login} built #{data.repository.full_name} pages at #{build.commit} in #{build.duration}ms."
      if build.error.message?
        callback "#{htmlNotify} page build for #{data.repository.full_name} errored: #{build.error.message}."

  pull_request_review_comment: (data, callback) ->
    comment = data.comment
    pull_req = data.pull_request
    base = data.base
    repo = data.repository

    callback "#{htmlComment} new comment on pull request <a target='_blank' href='#{comment.html_url}'>#{comment.body}</a> by #{comment.user.login}"

  pull_request: (data, callback) ->
    pull_num = data.number
    pull_req = data.pull_request
    base = data.base
    repo = data.repository
    sender = data.sender

    action = data.action

    msg = "#{htmlPullRequest} pull request <strong>\##{data.number}</strong> <a target='_blank' href='#{pull_req.html_url}'>#{pull_req.title}</a> "

    switch action
      when "assigned"
        msg += " assigned to: #{data.assignee.login} by #{sender.login} "
      when "unassigned"
        msg += " unassigned #{data.assignee.login} by #{sender.login} "
      when "opened"
        msg += " opened by #{sender.login} "
      when "closed"
        if pull_req.merged
          msg += " merged by #{sender.login} "
        else
          msg += " closed by #{sender.login} "
      when "reopened"
        msg += " reopened by #{sender.login} "
      when "labeled"
        msg += " #{sender.login} added label: <strong>#{data.label.name}</strong> "
      when "unlabeled"
        msg += " #{sender.login} removed label: <strong>#{data.label.name}</strong> "
      when "synchronize"
        msg +=" synchornized by #{sender.login} "

    callback msg

  push: (data, callback) ->
    commit = data.after
    commits = data.commits
    head_commit = data.head_commit
    repo = data.repository
    pusher = data.pusher

    if !data.deleted
      callback "#{htmlCommit} new commit <a target='_blank' href='#{head_commit.url}'>#{head_commit.message}</a> to #{repo.full_name} by #{pusher.name}"

  # Org level event
  repository: (data, callback) ->
    repo = data.repository
    org = data.organization
    action = data.action

    callback "#{repo.full_name} #{action}"

  release: (data, callback) ->
    release = data.release
    repo = data.repository
    action = data.action

    callback "release #{release.tag_name} #{action} on #{repo.full_name}"

  # No clue what to do with this one.
  status: (data, callback) ->
    commit = data.commit
    state = data.state
    branches = data.branches
    repo = data.repository

    callback ""

  watch: (data, callback) ->
    repo = data.repository
    sender = data.sender

    callback "#{htmlWatch} #{repo.full_name} is now being watched by #{sender.login}"
