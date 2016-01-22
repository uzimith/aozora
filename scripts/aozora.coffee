# Description
#   hubot scripts for aozora bunko
#
# Commands:
#   hubot set - 
#   hubot get - 
#   hubot delete - 
#
# Author:
#   uzimith

util    = require "util"
client = require('cheerio-httpcli')
cron = require('cron').CronJob
azure = require('azure-storage')

account           = process.env.HUBOT_BRAIN_AZURE_STORAGE_ACCOUNT
accessKey         = process.env.HUBOT_BRAIN_AZURE_STORAGE_ACCESS_KEY
blobSvc = azure.createBlobService account, accessKey

module.exports = (robot) ->

  initialized = false

  init = () ->
    blobSvc.createContainerIfNotExists 'novels', (error, result, response) ->
      initialized = true
      if !error
        robot.logger.error "Error checking if container exists: #{util.inspect(error)}"
      else
        robot.logger.info "novels container already exists."

  saveText = (filename, text) ->
    if initialized
      blobSvc.createBlockBlobFromText 'novels', filename, text, (err, blob, res) ->
        if err
          robot.logger.error "couldn't create #{filename}"
        else
          robot.logger.info "create #{filename}"

  load = (filename, times) ->
    console.log("load!")
    new Promise (resolve, reject) ->
      blobSvc.getBlobToText 'novels', filename, (error, response) ->
        if !error
          start = times * 400
          end   = start + 399
          text = response[start..end]
          resolve text
        else
          reject "読み込みに失敗しました。"

  init()

  robot.respond /set (.*)/i, (res) ->
    novels = robot.brain.get("novels") || {}
    room = res.envelope.room
    url = res.match[1]
    filename = "#{room}.txt"
    novels[room] = {url: url, times: 0, filename: filename}
    robot.brain.set "novels", novels
    client.fetch(url, null, (error, $, response) ->
      if !error
        title = $('title').text()
        text = $('div.main_text').text()
        saveText(filename, text)
        robot.logger.info "set #{url}"
        res.reply "登録しました。タイトル: #{title}"
      else
        res.reply util.inspect(error)
    )


  robot.respond /get/i, (res) ->
    novels = robot.brain.get("novels") || {}
    room = res.envelope.room
    data = novels[room]
    if data
      res.reply "#{data.url}: #{data.times}回"


  robot.respond /delete/i, (res) ->
    novels = robot.brain.get("novels") || {}
    room = res.envelope.room
    delete novels[room]
    robot.brain.set "novels", novels
    res.reply "削除しました。"

  robot.respond /read/i, (res) ->
    novels = robot.brain.get("novels") || {}
    room = res.envelope.room
    data = novels[room]
    load(data.filename, data.times)
      .then (text) ->
        res.send text
        novels[room].times++
        robot.brain.set "novels", novels
      .catch (error) ->
        res.reply error

  robot.respond /debug/i, (res) ->
    res.reply JSON.stringify robot.brain.data._private

  new cron '0 * * * * *', () =>
    novels = robot.brain.get("novels") || {}
    console.log("run")
    processes = []
    for room, data of novels
      processes.push [room, data]
    while process = processes.pop()
      load(data.filename, data.times)
        .then (text) ->
          robot.send {room: room}, text
          novels[room].times++
          console.log(room + text)
          robot.logger.info "load #{filename}"
        .catch (error) ->
          robot.send {room: room}, error
          robot.logger.error util.inspect(error)
    robot.brain.set "novels", novels
  , null, true, "Asia/Tokyo"
