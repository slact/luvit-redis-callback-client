--[[lit-meta
name = "slact/redis-callback-client"
version = "0.0.1"
description = "A full-featured callback-based Redis client for Luvit"
tags = {"redis"}
license = "MIT"
author = { name = "slact" }
homepage = "https://github.com/slact/luvit-redis-callback-client"
dependencies = {
  "creationix/redis-codec@1.0.2",
}
]]

local redisCodec = require 'redis-codec'
local sha1 = require "sha1"
local regex = require "rex"
local net = require 'net'

local parseUrl = function(url)
  local m = {regex.match(url, "(redis://)?(:([^?]+)@)?([\\w.-]+)(:(\\d+))?/?(\\d+)?")}
  return {
    host=m[4] or "127.0.0.1",
    port=m[6] and tonumber(m[6]) or 6379,
    password=m[3],
    db=m[7] and tonumber(m[7])
  }
end

return function(url)
  local pubsub = {}
  local callbacks = {}
  local scripts = {}
  
  
  
  local socket
  
  local failHard=function(err, ok)
    if(err) then error(err) end
  end
  
  local connect_params=parseUrl(url)
  
  local self = {
    send = function(self, ...)
      local arg = {...}
      if type(arg[#arg]) == "function" then
        --add callback
        table.insert(callbacks, table.remove(arg, #arg))
      else
        table.insert(callbacks, false)
      end
      if arg[1] =="multi" then
        socket:cork()
      elseif arg[1]=="exec" then
        socket:uncork()
      end
      socket:write(redisCodec.encode(arg))
      
      return self
    end,
    
    subscribe = function(self, channel, callback)
      self:send("subscribe", channel, function(err, d)
        p("subscribe", channel, err, d)
        if d then
          pubsub[channel]=callback
        else
          callback(err, nil)
        end
      end)
      return self
    end,
    
    unsubscribe = function(self, channel)
      self:send("unsubscribe", channel, function(err, d)
        if d then
          pubsub[channel]=nil
        end
      end)
    end,
    
    disconnect = function(self)
      socket:shutdown()
    end,
    
    loadScript = function(self, name, script, callback)
      local src
      scripts[name]=sha1(script)
      self:send("script", "load", script, function(err, data)
        failHard(err, data)
        assert(scripts[name] == data)
      end)
    end,
    
    runScript = function(self, name, keys, args, callback)
      if scripts[name] == false then
        error("script hasn't loaded yet")
      elseif scripts[name] then
        if callback then
          self:send("evalsha", scripts[name], #keys, unpack(keys), unpack(args), callback)
        else
          self:send("evalsha", scripts[name], #keys, unpack(keys), unpack(args))
        end
      else
        error("Unknown Redis script " .. tostring(name))
      end
    end
  }
  
  p(connect_params)
  
  socket = net.connect(connect_params.port, connect_params.host)
  socket:cork()
  
  if connect_params.password then
    self:send("auth", connect_params.password, failHard)
  end
  
  if connect_params.db then
    self:send("select", connect_params.db, failHard)
  end
    
  socket:on("connect", function(err, d)
    p("connected")
    socket:uncork()
    if err then 
      if err == "ECONNREFUSED" then
        error("Cound not connect to Redis at " .. connect_params.host .. ":" .. connect_params.port)
      else
        error(err)
      end
    end
  end)
  
  socket:on("disconnect", function(err, d)
    p("gone")
  end)
  
  socket:on('data', function(data)
    -- If error, print and close connection
    --p("onData", data)
    
    while #data>0 do
      local d
      d, data = redisCodec.decode(data)
      if type(d)=="table" and d[1]=="message" then
        pubsub[d[2]](d[3])
      elseif callbacks[1] then
        if type(d)=="table" and d.error then
          callbacks[1](d.error, nil)
        else
          callbacks[1](nil, d)
        end
        table.remove(callbacks, 1)
      end
    end
  end)
  return self
end
