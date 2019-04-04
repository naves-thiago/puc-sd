socket = require"socket"

conns = arg[1] and tonumber(arg[1]) or 1
msgperconn = arg[2] and tonumber(arg[2]) or 1
serverport = arg[3] and tonumber(arg[3]) or 5500
serverip = arg[4] or '127.0.0.1'
datalen = 1024
--client = socket.tcp()
request = 'foo\n'

local failed = 0
local starttime = socket.gettime()
for i=1, conns do
	client = socket.tcp()
	client:connect(serverip, serverport)
	for k=1, msgperconn do
		if not client:send(request) then
			failed = failed + 1
			goto continue
		end
		local line, err = client:receive('*l')
		assert(line and #line == datalen - 1, #line)
		::continue::
	end
	client:close()
end
stoptime = socket.gettime()
print(string.format("Time:  %f\nConns: %d\nReqs:  %d\nFailed: %d", stoptime - starttime, conns, conns * msgperconn, failed))
