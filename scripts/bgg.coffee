# Description:
#   Suggest games to play based on boardgamegeek collection
#
# Commands:
#   hubot board game sync <bgguser> - Download game list for user bguser
#   hubot suggest a game [for <n>] - Randomly pick an owned game for n people

libxmljs = require("libxmljs");

module.exports = (robot) ->
  robot.respond /suggest a game(?: for (\d+))?$/i, (msg) ->
    players = msg.match[1]
    games = msg.message.user.games
    if !games
      msg.send "I don't know about any games you own!"
      return
    games = (game for game in games when game.min <= players and game.max >= players) if players
    l = games.length
    i = Math.floor(Math.random() * l)
    msg.send "How about #{games[i].name}? http://boardgamegeek.com/boardgame/#{games[i].bggid}"

  robot.respond /board game sync (\w+)$/i, (msg) ->
    bggname = msg.match[1].trim()
    msg
     .http("http://boardgamegeek.com/xmlapi/collection/#{bggname}?own=1")
     .header("User-Agent: Board game suggestion bot")
     .get() (err, res, body) ->
       doc = libxmljs.parseXml(body)
       if doc.root().name() == 'message'
         msg.send doc.root().text()
         return
       games = doc.find("//item")
       gamer = msg.message.user
       gamer.games = ({
           name: game.get("./name").text(),
           min: game.get("./stats").attr("minplayers")?.value(),
           max: game.get("./stats").attr("maxplayers")?.value(),
           bggid: game.attr("objectid").value()
       } for game in games)
       msg.send "#{gamer.games.length} games added"
