local mqtt = require'mqtt'
client = mqtt.client{
	uri = 'localhost',
	username = 'a',
	clean = true
}
print('created')

function tacb(suback)
end

client:on{
	connect = function(connack)
		if connack.rc ~= 0 then
			print("connection failed", connack)
			return
		end

		assert(client:subscribe{ topic="t/a", qos = 0, callback = tacb })
	end,

	message = function(msg)
		assert(client:acknowledge(msg))
	end,

	error = function(err)
		print("MQTT error", err)
	end,
}

mqtt.run_ioloop(client)
