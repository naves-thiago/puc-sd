-- Lua 5.1
local Tabuleiro = {
	corPreto = {79 / 255, 54 / 255, 7 / 255},
	corBranco = {216 / 255, 183 / 255, 121 / 255},
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
	-- TODO: Testar
	local p = self.pecas[x][y]
	if not p then return end
	if self.pecas[nx][ny] then return end

	self.pecas[x][y] = nil
	self.pecas[nx][ny] = p
	p.x, p.y = self.centro(nx, ny)
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
	-- TODO: Testar
	return math.floor(x / self.casaW),
		   math.floor(y / self.casaH)
end

local Peca = {
	corPreto = {0, 0, 0},
	corBranco = {1, 1, 1},
}

function Peca:draw()
	-- TODO: Graficos diferentes para pecas e damas
	love.graphics.setColor(unpack(self.cor))
	love.graphics.circle("fill", self.x, self.y, self.raio, 20)
end

function Peca.new(x, y, cor)
	assert(x)
	assert(y)
	assert(type(cor) == "table")
	return setmetatable({
		x = x,
		y = y,
		cor = cor,
		dama = false,
	}, {__index=Peca})
end

function criaPecas()
	for y = 0, 2 do
		for x = 1, 7, 2 do
			local px, py = Tabuleiro:centro(x - y % 2, y)
			local p = Peca.new(px, py, Peca.corPreto)
			Tabuleiro.pecas[x - y % 2][y] = p

			local y2 = y + 5
			px, py = Tabuleiro:centro(x - y2 % 2, y2)
			p = Peca.new(px, py, Peca.corBranco)
			Tabuleiro.pecas[x - y2 % 2][y2] = p
		end
	end
end

function love.load()
	Tabuleiro.init()
	Peca.raio = math.min(Tabuleiro.casaW, Tabuleiro.casaH) * 0.4
	criaPecas()
end

function love.update(dt)

end

function love.draw()
	Tabuleiro:draw()
	for y, linha in pairs(Tabuleiro.pecas) do
		for x, peca in pairs(linha) do
			peca:draw()
		end
	end
end
