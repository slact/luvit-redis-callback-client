#!/usr/bin/luvit
local Redis = require "redis-callback-client"

-- Create client socket
local rds = Redis("redis://localhost/0")

rds:on("connect", function()
  p("connected!")
end)
rds:on("disconnect", function()
  p("disconnected...")
end)
--[[
rds:send("get", "fooo", function(err, d)
  p("hmmm", d)
end)

rds:send("ping", function(err, d)
  p("ping", d)
end)

rds:send("paong", function(err, d)
  p("paong", d, err)
end)

rds:loadScript("name", "return 1")

rds:runScript("name", {}, {1,2,4}, function(err, ok)
  p(ok)
end)

rds:send("hmset", "fooh", {hello="hi", what="huh", is=11, this=13}, function(err, ok)
  p("hmset", err, ok)
end)
rds:send("hgetall", "fooh", function(err, ok)
  p("hgetall", err, ok)
end)
]]
function cb(str)
  return function(err, ok)
    p(str, err, ok)
  end
end



rds:send("hmget", "fooh", "banana", "11", "what", cb("okay"))


rds:send("multi")
  --:send("hgetall", "fooh", cb("hgetall fooh"))
  :send("get", "fooo", cb("getfooo"))  
  :send("get", "foo1", cb("getfoo1"))  
  --:send("hgetall", "fooh", cb("hgetall fooh, again"))
:send("exec", function(err, data)
  p("ooooooooookay", err, data)
end)


--[[
rds:subscribe("foo", function(msg)
  p("got message", msg)
  if msg =="FIN" then
    p("goodbye")
    rds:disconnect()
  end
end)
]]
