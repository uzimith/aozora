module.exports = (robot) ->
  robot.respond /set (.*)/i, (res) ->
    room = res.envelope.room
    url = res.match[1]
    novels = robot.brain.get("novels") || {}
    novels[room] = {url: url, times: 0}
    robot.brain.set "novels", novels
    res.reply "登録しました。"

  robot.respond /remove/i, (res) ->
    room = res.envelope.room
    novels = robot.brain.get("novels") || {}
    delete novels[room]
    robot.brain.set "novels", novels
    res.reply "削除しました。"

  robot.respond /show/i, (res) ->
    room = res.envelope.room
    novels = robot.brain.get("novels") || {}
    data = novels[room]
    res.reply "#{data.url}: #{data.times}回"

  robot.respond /next/i, (res) ->
    room = res.envelope.room
    novels = robot.brain.get("novels") || {}
    data = novels[room]
    res.reply """
    """

  robot.respond /debug/i, (res) ->
    res.reply JSON.stringify robot.brain.data._private
