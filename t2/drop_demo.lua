local librpc = require'librpc'

t1 = {}
t2 = {}

port1 = arg[1]
port2 = arg[2] or (tonumber(port1) + 1)

for i=1,2 do
	t1[i] = librpc.create_proxy('idl_demo.lua', 'localhost', port1, 'numbers')
end

for i=1,2 do
	t2[i] = librpc.create_proxy('idl_demo2.lua', 'localhost', port2, 'interface_a')
end

for i=1,2 do
	print(pcall(t1[i].add, 1, 2))
end

for i=1,2 do
	print(pcall(t2[i].sum, 3, 4))
end

