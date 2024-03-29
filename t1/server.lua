socket = require'socket'

port = arg[1] and tonumber(arg[1]) or 5500
local datalen = 1024
local data = string.rep('a', datalen-1) .. '\n'
local server = assert(socket.bind('*', port))
local ip, port = server:getsockname()
print('ip = ' .. ip .. ' - port = ' .. port)

local starttime
while true do
	local client = server:accept()
	client:settimeout(1)
	local line, err = client:receive('*l')
	while not err do
		assert(client:send(data))
		line, err = client:receive('*l')
	end
	client:close()
end

