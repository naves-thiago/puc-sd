local librpc = require'librpc'

colors = librpc.create_proxy('idl_demo.lua', 'localhost', arg[1], 'colors')
numbers = librpc.create_proxy('idl_demo.lua', 'localhost', arg[2] or (tonumber(arg[1])+1), 'numbers')

color_a = {name='a', rgb={x=1, y=2, z=3}}
color_b = {name='b', rgb={x=10, y=20, z=30}}

print('colors.add(a): ', colors.add(color_a))
print('colors.add(b): ', colors.add(color_b))

ca, namea = colors.get('a')
cb, nameb = colors.get('b')
cc, namec = colors.get('c')

print(string.format("%s: x=%f, y=%f, z=%f", namea, ca.x, ca.y, ca.z))
print(string.format("%s: x=%f, y=%f, z=%f", nameb, cb.x, cb.y, cb.z))
print(string.format("%s: x=%f, y=%f, z=%f", namec, cc.x, cc.y, cc.z))

print('--------------------------------------------------')

print("1.2 + 3.4 = "..numbers.add(1.2, 3.4))
print("dup 3:", numbers.dup(3))
print("swap 5, 6:", numbers.swap(5, 6))

