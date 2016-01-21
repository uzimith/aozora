cron = require('cron').CronJob

module.exports = (robot) ->
  new cron '0 * * * * *', () =>
    robot.send {room: "general"}, "１分経ったよ！"
  , null, true, "Asia/Tokyo"
