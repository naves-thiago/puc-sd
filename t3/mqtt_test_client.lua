local mqtt = require'mqtt'
local socket = require'socket'
local starttimes = {}
local endtimes = {}
local tries = 1000000
local sum = 0
local iarrived = 1
client = mqtt.client{
	uri = 'localhost',
	username = 'a',
	clean = true
}

function tacb(suback)
	local maxtimetaken = 0
	local timetaken = 0
	for i = 1, tries do
		starttimes[i] = socket.gettime() * 1000
		assert(client:publish{
			topic='t/a',
			payload = 'hello',
			qos = 0})
	end
end

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("connection failed", connack)
			return
		end
		print("Connected", connack)

		assert(client:subscribe{ topic="t/a", qos = 0, callback = tacb })
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
		endtimes[iarrived] = socket.gettime() * 1000
		if tries == iarrived then
			for i = 1, tries do
				sum = sum + endtimes[i] - starttimes[i]
			end
			print('mean time', sum / (tries))
			assert(client:disconnect())
		end
		iarrived = iarrived + 1
	end,

	error = function(err)
		print("MQTT error", err)
	end,
}

mqtt.run_ioloop(client)
