MenuData = {}
MenuData.__index = MenuData

function MenuData:new()
	local M = {}
	setmetatable(M, MenuData)
	
	M.active = true
	
	M.textBoxPos = {}
	M.textBoxSelected = 0
	
	M.menuFunction = {}
	
	M.resolutionsAvailable = readListOfResolutionsFile()
	
	return M
end

function MenuData:checkSelection()
	-- coloca a origem do cursor como sendo o centro da janela
	local cursorPos = Vector:new(input.pointerPos.x - screen.width / 2, -(input.pointerPos.y - screen.height / 2))
	
	local selection = false
	local i = 1
	
	-- procura em cada caixa de texto qual esta sendo selecionada
	while i <= table.getn(self.textBoxPos) and not selection do
		if self.textBoxPos[i]:pointInside(cursorPos) then
			if i ~= self.textBoxSelected then
				if self.textBoxSelected ~= 0 then
					interface.textTable[self.textBoxSelected]:removeSelection()
				end
				
				self.textBoxSelected = i
				interface.textTable[self.textBoxSelected]:selection()
			end
			
			selection = true
		else
			i = i + 1
		end
	end
	
	if not selection and self.textBoxSelected ~= 0 then
		interface.textTable[self.textBoxSelected]:removeSelection()
		
		self.textBoxSelected = 0
	end
end

function MenuData:checkPressed()
	-- checa se houve o click
	if input.pointerPressed then
		input.pointerPressed = false
		
		-- checa se tem algo selecionado
		if self.textBoxSelected ~= 0 then
			-- realiza a funcao do menu selecionado
			self.menuFunction[self.textBoxSelected](self)
		end
	end
end

function MenuData:createMainMenu()
	-- limpa o menu anterior (se houver)
	self:cleanMenu()
	
	texts = {}		-- contem as strings que parecem no menu
	table.insert(texts, "Novo Jogo")
	table.insert(texts, "Como Jogar")
	table.insert(texts, "Maior Pontuação")
	table.insert(texts, "Opções")
	table.insert(texts, "Sair")
	
	-- cria um novo menu
	interface:createMenu(texts)
	
	-- cria as caixas de texto para selecionar
	self:createBoxesMenu(5)
	
	-- define o que cada item do menu vai fazer
	table.insert(self.menuFunction, function() self:newGame() end)
	table.insert(self.menuFunction, function() self:createHowToPlayMenu() end)
	table.insert(self.menuFunction, function() self:createScoreMenu() end)
	table.insert(self.menuFunction, function() self:createOptionsMenu() end)
	table.insert(self.menuFunction, function() self:exitGame() end)
end

function MenuData:createScoreMenu()
	self:cleanMenu()
	
	local score = readScoreFile()
	
	texts = {}
	table.insert(texts, score .. " pontos")
	table.insert(texts, "Voltar")
	
	interface:createMenu(texts)
	
	interface.textTable[1].selectable = false
	
	self:createBoxesMenu(2)
	
	table.insert(self.menuFunction, function()  end)
	table.insert(self.menuFunction, function() self:createMainMenu() end)
end

function MenuData:createOptionsMenu()
	self:cleanMenu()
	
	local width = math.floor(screen.width)
	local height = math.floor(screen.height)

	texts = {}
	table.insert(texts, "Reinicie para aplicar alterações")
	table.insert(texts, "Resolução (atual " .. width .. "x" .. height .. ")")
	table.insert(texts, "Voltar")
	
	interface:createMenu(texts)
	
	interface.textTable[1].selectable = false
	
	self:createBoxesMenu(3)
	
	table.insert(self.menuFunction, function()  end)
	table.insert(self.menuFunction, function() self:createResolutionsMenu() end)
	table.insert(self.menuFunction, function() self:createMainMenu() end)
end

function MenuData:createResolutionsMenu()
	self:cleanMenu()
	
	-- tabela contendo todos os textos que apareceram no menu
	local resolutionsTexts = {}
	
	for i = 1, table.getn(self.resolutionsAvailable), 1 do
		
		table.insert(self.menuFunction, function()
			writeResolutionFile(self.resolutionsAvailable[i])
			
			self:createOptionsMenu()
		end)
		
		local width = math.floor(self.resolutionsAvailable[i].x)
		local height = math.floor(self.resolutionsAvailable[i].y)
		
		table.insert(resolutionsTexts, width .. "x" .. height)
	end
	
	-- inclui no final a opcao de voltar
	table.insert(self.menuFunction, function() self:createOptionsMenu() end)
	table.insert(resolutionsTexts, "Voltar")
	
	self:createBoxesMenu(table.getn(resolutionsTexts))
	
	interface:createMenu(resolutionsTexts)
end

function MenuData:createHowToPlayMenu()
	self:cleanMenu()
	
	texts = {}
	table.insert(texts, "Ganhe pontos eliminando naves")
	table.insert(texts, "Voltar")
	
	interface:createMenu(texts, -0.7 * screen.height/2)
	
	interface.textTable[1].selectable = false
	
	self:createBoxesMenuCustomStart(-0.7 * screen.height/2, 2)
	
	table.insert(self.menuFunction, function()  end)
	table.insert(self.menuFunction, function() self:createMainMenu() end)
	
	interface:showHowToPlay()
end

function MenuData:createBoxesMenu(n)
	-- cria "n" caixas de texto para selecionar
	
	for i = 1, n, 1 do
		local center = Vector:new(0, interface.textStart - (i - 1) * interface.textGap)
		
		local box = Rectangle:new(center, Vector:new(screen.width / 2, interface.textSize / 2))
	
		table.insert(self.textBoxPos, box)
	end
end

function MenuData:createBoxesMenuCustomStart(start, n)
	-- cria "n" caixas de texto para selecionar
	
	for i = 1, n, 1 do
		local center = Vector:new(0, start - (i - 1) * interface.textGap)
		
		local box = Rectangle:new(center, Vector:new(screen.width / 2, interface.textSize / 2))
	
		table.insert(self.textBoxPos, box)
	end
end

function MenuData:newGame()
	self.active = false
	
	interface:clean()
	
	local gameThread = MOAICoroutine.new()
	gameThread:run(gameLoop)
end

function MenuData:exitGame()
	os.exit(0)
end

function MenuData:cleanMenu()
	interface:cleanMenu()
	
	self.textBoxSelected = 0
	
	for i = 1, table.getn(self.textBoxPos), 1 do
		table.remove(self.textBoxPos, 1)
	end
	
	for i = 1, table.getn(self.menuFunction), 1 do
		table.remove(self.menuFunction, 1)
	end
end