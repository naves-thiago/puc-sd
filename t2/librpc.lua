local client = require'client'
local server = require'server'

local m = {}
m.create_proxy = client.create_proxy
m.register_servant = server.register_servant
m.waitincoming = server.waitincoming
return m
