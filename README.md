# redis-luvit

A [Redis][] protocol codec for [Luvit][]

## Installing

Simply install using lit directly:

```sh
lit install slact/redis-callback-client
```

## Usage

```lua
local Redis = require('redis-callback-client')

-- Connect to redis server specified by URL of the form
-- redis://:password@host:port/db. Can be truncated to just host:port or host
local client = Redis("redis://127.0.0.1:6379")

--send a command
client:send("ping")

--send a command with a callback
client:send("get", "foo", function(err, data)
  if err then error(err) end
  print(data)
end)

--subscribe to a channel
client:subscribe("channel:foo", function(msg)
  --handle subscription messages
end)
--unsubscribe
client:unsubscribe("channel:foo")

--(subscribing to channel patterns with PSUBSCRIBE is not yet supported)

--multi/exec blocks are buffered and are not sent until the "exec" command
cliend:send("multi") --buffered until exec/discard
client:send("set", "foo", 1) --buffered until exec/discard
client:send("get", "foo") --buffered until exec/discard
client:send("exec", function(err, data)
  --process multi/exec results
end)

--lua scripts can be loaded and called by name
client:loadScript("example script", "return KEYS[1], ARGV[1]") -- will throw an error if script fails to load
client:loadScript("example script", "return KEYS[1], ARGV[1]", function(err, hash) --passes error, if present, to callback
  --process "SCRIPT LOAD" response
end)

--                  script name  , {keys},      {args}
client:runScript("example script", {"foo"}, {"first arg"}, function(err, data)
  --process EVALSHA response
end)
-- runScript can be used without waiting for client:loadScript response, provided that the script is syntactically correct


--all redis client functions are chainable

client:send("get", "foo"):send("get" "bar")

client:disconnect() 
```

[Redis]: http://redis.io/
[Luvit]: https://luvit.io/
