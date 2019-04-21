local socket = require'socket'
local binser = require'binser'
local mime = require'mime'
local types = require'types'

idls = {}

idls.interfaces = {}
idls.structs = {}
current_idl = ''

local unconnected = {}
local connected = {}
local sockets = {}

function validate_recv(recv, expected)
        for i, received in ipairs(recv) do
            local ok, err = types.validate_type(received, expected[i].type)
            if not ok then
                return ok, err
            end
        end
        return true
end

function struct(t)
	if not types.validate_struct(t) then
		error('Invalid struct')
	end
	idls[current_idl].structs[t.name] = t.fields
end

function interface(t)
	if not types.validate_interface(t) then
		error('Invalid interface')
	end
	idls[current_idl].interface.methods = t.methods
end

local function parse_incoming(incoming, idl)
    local data = mime.unb64(incoming)
    local received = binser.deserialize(data)
    local name = received[1]
    table.remove(received, 1)
    local methinfo = idl.interface.methods[name]
    local res = table.pack(pcall(methinfo.func, table.unpack(received)))
    return res, name
end

local function parse_and_check_results(res, idl, name)
    if not res[1] then
        return false, res[2]
    end
    table.remove(res, 1)
    local methinfo = idl.interface.methods[name]
    local exp_results = {{type = methinfo.resulttype}}
    table.move(methinfo.args, 1, #methinfo.args, 2, exp_results)
    local veridict, err = validate_recv(res, exp_results)
    return veridict and res or false, 'wrong return types'
end

function register_servant(idlname, o)
    current_idl = idlname
    idls[idlname] = {}
    idls[idlname].structs = {}
    idls[idlname].interface = {}
    loadfile(idlname .. '.lua' , 't')()
    local idl = idls[idlname]
    local server = assert(socket.bind('*', 0))
    local ip, port = server:getsockname()
    for name, func in pairs(o) do
        idl.interface.methods[name].func = func
    end
    unconnected[server] = idl
    table.insert(sockets, server)
    return ip, port
end

local function waitincoming()
    while true do
            local socks = socket.select(sockets)
            for _, sock in pairs(socks) do
                if type(sock) == 'userdata' then
                    sock:settimeout(1)
                    if unconnected[sock] then
                        local client = sock:accept()
                        if client then
                            if #connected == 3 then
                                local sock_toclose = next(connected, nil)
                                connected[sock_toclose] = nil
                                sock_toclose:close()
                            end
                            connected[client] = unconnected[sock]
                            unconnected[sock] = nil
                            table.insert(sockets, client)
                        end
                    else
                        local line, err = sock:receive('*l')
                        if line then
                            local res, name = parse_incoming(line, connected[sock])
                            res, err = parse_and_check_results(res, connected[sock], name)
                            if res then
                                sock:send(mime.b64(binser.serialize(table.unpack(res))) .. '\n')
                            else
                                sock:send(mime.b64('__RPC_ERROR ' .. err).. '\n')
                            end
                        else
                            sock:send(mime.b64(binser.serialize(false, err)) .. '\n')
                        end
                    end
                end
            end
    end
end
