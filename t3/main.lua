-- Lua 5.1
local mqtt = require'mqtt'
local binser = require'binser'
local mime = require'mime'
local ioloop_get = require("mqtt.ioloop").get
local Tabuleiro = {
	corPreto = {79 / 255, 54 / 255, 7 / 255},
	corBranco = {216 / 255, 183 / 255, 121 / 255},
}

local Mosquitto = {
	client = {}
}

local Peca = {
	corPreto = {0, 0, 0},
	corBranco = {1, 1, 1},
}

function Tabuleiro:draw()
	for cor = 0, 1 do
		local c = cor == 0 and self.corBranco or self.corPreto
		love.graphics.setColor(unpack(c))
		for x = 0, 6, 2 do
			for y = 0, 7 do
				love.graphics.rectangle("fill",
					self.casaW * (x + (y + cor) % 2), self.casaH * y,
					self.casaW, self.casaH)
			end
		end
	end
end

function Tabuleiro.init()
	Tabuleiro.casaW = math.floor(love.graphics.getWidth() / 8)
	Tabuleiro.casaH = math.floor(love.graphics.getHeight() / 8)
	local p = {}
	for i = 0, 7 do
		p[i] = {}
	end
	Tabuleiro.pecas = p -- pecas[x][y] == alguma peca ou nil
end

-- x, y, nx, ny sao indices
-- x, y - posicao atual
-- nx, ny - nova posicao
function Tabuleiro:movePeca(x, y, nx, ny)
	local p = self.pecas[x][y]
	if not p then return end
	if not self:validaJogada(x, y, nx, ny, p) then
		p:move(x, y)
		return
	end
	self.pecas[x][y] = nil
	self.pecas[nx][ny] = p
	p:move(nx, ny)
	return true
end

-- Retorna o centro (em pixels) da casa
-- x, y = indices (0-7) da casa
function Tabuleiro:centro(x, y)
	return math.floor((x + 0.5) * self.casaW),
		   math.floor((y + 0.5) * self.casaH)
end

-- Retorna os indices da casa
-- x, y = posicao em pixels
function Tabuleiro:indiceCasa(x, y)
	return math.floor(x / self.casaW),
		   math.floor(y / self.casaH)
end

function Tabuleiro:validaJogada(x, y, nx, ny, peca)
	if x == nx and y == ny then return false end
	if self.pecas[nx][ny] then return false end

	-- Movimento apenas na diagonal
	if math.abs(nx - x) ~= math.abs(ny - y) then return false end

	-- So dama pode andar para tras
	if not peca.dama then
		if peca.cor == Peca.corPreto and ny < y then return false end
		if peca.cor == Peca.corBranco and ny > y then return false end
	end

	-- So dama pode andar mais de uma casa
	if math.abs(x - nx) > 2 and not peca.dama then return false end

	-- Comeu outra?
	local dirX = nx > x and 1 or -1
	local dirY = ny > y and 1 or -1
	if peca.dama then
		-- Damas pode comer exatamente 1 peca a qualquer distancia
		-- Nao pode passar por cima de uma peca do mesmo jogador
		local distancia = math.abs(x - nx)
		local comida
		for passo = 1, distancia -1 do
			local peca2 = self.pecas[x + passo * dirX][y + passo * dirY]
			if peca2 and comida then return false end
			comida = comida or peca2
			if peca2 and peca2.cor == peca.cor then return false end
		end
		if comida then
			self.pecas[comida.x][comida.y] = nil
		end
	else
		-- So pode andar mais de 1 comendo
		if math.abs(x - nx) == 2 then
			local peca2 = self.pecas[x + dirX][y + dirY]
			if not peca2 or peca2.cor == peca.cor then return false end
			self.pecas[x + dirX][y + dirY] = nil
		end
	end

	-- Virou dama?
	if (peca.cor == Peca.corBranco and ny == 0) or
	   (peca.cor == Peca.corPreto  and ny == 7) then
		peca.dama = true
	end

	return true
end

function Mosquitto:movepeca(x, y, nx, ny)
	assert(self.client:publish{
		topic='t/a',
		payload = mime.b64(binser.serialize(x, y, nx, ny) .. '\n'),
		qos = 0})
end

function Mosquitto.init(uri, id)
	assert(uri, 'uri is a mandotory parameter')
	assert(id, 'id is a mandotory parameter')
	Mosquitto.client = mqtt.client{
		uri = uri,
		id = id,
		clean = true,
	}
	Mosquitto.client:on{
		connect = function(connack)
			if connack.rc ~= 0 then
				print("connection failed", connack)
				return
			end
			assert(Mosquitto.client:subscribe{ topic="t/a", qos = 0, callback = function(suback) assert(suback) end,})
		end,

		message = function(msg)
			local data = mime.unb64(msg.payload)
			local received = binser.deserialize(data)
			local x, y = received[1], received[2]
			local nx, ny = received[3], received[4]
			Tabuleiro:movePeca(x, y, nx, ny)
			assert(Mosquitto.client:acknowledge(msg))
		end,

		error = function(err)
			print("MQTT error", err)
		end,
	}
	Mosquitto.client:start_connecting()
end

function Peca:move(x, y)
	self.x, self.y = x, y
	self.posX, self.posY = Tabuleiro:centro(x, y)
end

function Peca:draw()
	love.graphics.setColor(unpack(self.cor))
	love.graphics.circle("fill", self.posX, self.posY, self.raio, 20)

	if self.dama then
		local corListra = self.cor == Peca.corPreto and Peca.corBranco
				or Peca.corPreto
		love.graphics.setColor(unpack(corListra))
		love.graphics.circle("fill", self.posX, self.posY, self.raio * 0.8, 20)
		love.graphics.setColor(unpack(self.cor))
		love.graphics.circle("fill", self.posX, self.posY, self.raio * 0.7, 20)
	end
end

function Peca.new(x, y, cor)
	assert(x)
	assert(y)
	assert(type(cor) == "table")
	local p = setmetatable({
		cor = cor,
		dama = false,
	}, {__index=Peca})
	p:move(x, y)
	return p
end

function criaPecas()
	for y = 0, 2 do
		for x = 1, 7, 2 do
			local px = x - y % 2
			local p = Peca.new(px, y, Peca.corPreto)
			Tabuleiro.pecas[x - y % 2][y] = p

			local y2 = y + 5
			px = x - y2 % 2
			p = Peca.new(px, y2, Peca.corBranco)
			Tabuleiro.pecas[x - y2 % 2][y2] = p
		end
	end
end

Movimento = {
	movendo = false,
	peca = nil,
	clickX = 0,
	clickY = 0,
	fimCallback = nil,
}

function Movimento:update()
	if not self.movendo then return end
	self.peca.posX = love.mouse.getX() - self.difX
	self.peca.posY = love.mouse.getY() - self.difY
end

function love.mousepressed(x, y, button, istouch)
	if button ~= 1 then return end
	local casaX, casaY = Tabuleiro:indiceCasa(x, y)
	local peca = Tabuleiro.pecas[casaX][casaY]
	if not peca then return end
	Movimento.movendo = true
	Movimento.difX = x - peca.posX
	Movimento.difY = y - peca.posY
	Movimento.peca = peca
end

function love.mousereleased(x, y, button, istouch)
	if button ~= 1 then return end
	if not Movimento.movendo then return end
	local casaX, casaY = Tabuleiro:indiceCasa(x, y)
	local peca = Movimento.peca
	Mosquitto:movepeca(peca.x, peca.y, casaX, casaY)
	Movimento.peca = nil
	Movimento.movendo = false
end

function love.load()
	Tabuleiro.init()
	Mosquitto.init('localhost', 'lua love ' .. tostring(arg[2]))
	Peca.raio = math.min(Tabuleiro.casaW, Tabuleiro.casaH) * 0.4
	criaPecas()
end

function love.update(dt)
	Movimento:update()
	local loop = ioloop_get()
	loop:add(Mosquitto.client)
	loop:iteration()
end

function love.draw()
	Tabuleiro:draw()
	for y, linha in pairs(Tabuleiro.pecas) do
		for x, peca in pairs(linha) do
			peca:draw()
		end
	end
end
