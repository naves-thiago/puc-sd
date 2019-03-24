socket = require"socket"

conns = arg[1] and tonumber(arg[1]) or 1
msgperconn = arg[2] and tonumber(arg[2]) or 1
datalen = 1024
--client = socket.tcp()
request = 'foo\n'

local starttime = socket.gettime()
for i=1, conns do
	client = socket.tcp()
	client:connect("127.0.0.1", 1234)
	for k=1, msgperconn do
		assert(client:send(request))
		local line, err = client:receive('*l')
		assert(line and #line == datalen - 1, #line)
	end
	client:close()
end
stoptime = socket.gettime()
print(string.format("Time:  %f\nConns: %d\nReqs:  %d", stoptime - starttime, conns, conns * msgperconn))
