local client = require'client'

local serverip = arg[1] and tonumber(arg[1]) or '127.0.0.1'
local serverport = arg[2] and tonumber(arg[2]) or 1234
local datalen = 1024

local function doreport(times, conns, msgperconn)
    local time = 0
    for i=0, times do
        time = time + client.sendrequests(conns, msgperconn, serverip, serverport, datalen)
    end
    time = time / times
    print(string.format("Time:  %f\nConns: %d\nReqs:  %d", time, conns, conns * msgperconn))
end

doreport(10, 1, 1)
doreport(10, 1, 1000)
--doreport(10, 100, 1)
doreport(10, 1000, 1)
