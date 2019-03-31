socket = require"socket"
local client = {}

function client.sendrequests(conns, msgperconn, serverip, serverport, datalen)
    local starttime = socket.gettime()
    local request = 'foo\n'
    for i=1, conns do
            client = socket.tcp()
            client:connect(serverip, serverport)
            for k=1, msgperconn do
                    assert(client:send(request))
                    local line, err = client:receive('*l')
                    assert(line and #line == datalen - 1, #line)
            end
            client:close()
    end
    stoptime = socket.gettime()
    return stoptime - starttime
end
return client
