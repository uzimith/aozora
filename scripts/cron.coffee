cron = require('cron').CronJob

module.exports = (robot) ->
  new cron '0 * * * * *', () =>
    robot.send {room: "#general"}, "1分経ったよ"
  , null, true, "Asia/Tokyo"
