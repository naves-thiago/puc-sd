-- Lua 5.1
local Tabuleiro = {
	corPreto = {79 / 255, 54 / 255, 7 / 255},
	corBranco = {216 / 255, 183 / 255, 121 / 255},
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
	if self.pecas[nx][ny] then return end
	if not self:validaJogada(x, y, nx, ny, p) then return end
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
	-- Virou dama?
	if (peca.cor == Peca.corBranco and ny == 0) or
	   (peca.cor == Peca.corPreto  and ny == 7) then
		peca.dama = true
	end

	return true
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
	if not Tabuleiro:movePeca(peca.x, peca.y, casaX, casaY) then
		peca:move(peca.x, peca.y)
	end

	Movimento.peca = nil
	Movimento.movendo = false
end

function love.load()
	Tabuleiro.init()
	Peca.raio = math.min(Tabuleiro.casaW, Tabuleiro.casaH) * 0.4
	criaPecas()
end

function love.update(dt)
	Movimento:update()
end

function love.draw()
	Tabuleiro:draw()
	for y, linha in pairs(Tabuleiro.pecas) do
		for x, peca in pairs(linha) do
			peca:draw()
		end
	end
end
