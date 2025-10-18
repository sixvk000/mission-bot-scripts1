-- Mission Bot 8.0 (HoHo Hub Style + Auto Farm)
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- CONFIGURAÇÕES
local hoverHeight = 11
local attackRate = 3
local lerpSpeed = 0.3
local attackRemote = ReplicatedStorage:FindFirstChild("AttackEvent")

-- ESTADO
local alvoAtual = nil
local clickActive = false
local flying = false
local hoverConn = nil
local noclipOn = false
local autoClickLoop = nil

-- UTILIDADES
local function safeFindHumanoid(model)
	if not model then return nil end
	local h = model:FindFirstChild("Humanoid")
	return (h and h:IsA("Humanoid")) and h or nil
end

local function findNextByName(name, skipModel)
	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Model") and v.Name == name and v ~= skipModel then
			local h = safeFindHumanoid(v)
			if h and h.Health > 0 then
				return v
			end
		end
	end
	return nil
end

-- Noclip persistente
RunService.Heartbeat:Connect(function()
	if noclipOn then
		for _,p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.CanCollide = false
			end
		end
	end
end)

-- Hover + Auto deitar
local function setLying(state)
	humanoid.PlatformStand = state
end

local function startHover()
	if not alvoAtual or not alvoAtual.Parent then return end
	if hoverConn then return end
	flying = true
	setLying(true)
	hoverConn = RunService.RenderStepped:Connect(function()
		if not flying or not alvoAtual or not alvoAtual.Parent then
			if hoverConn then
				hoverConn:Disconnect()
				hoverConn = nil
			end
			flying = false
			setLying(false)
			return
		end
		local targetHRP = alvoAtual:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end
		local destPos = targetHRP.Position + Vector3.new(0, hoverHeight, 0)
		root.CFrame = root.CFrame:Lerp(CFrame.new(destPos, targetHRP.Position), lerpSpeed)
	end)
end

local function stopHover()
	flying = false
	setLying(false)
	if hoverConn then
		hoverConn:Disconnect()
		hoverConn = nil
	end
end

-- AutoClick confiável
local function autoClick(target)
	if not target or not target.Parent then return end
	-- ClickDetector
	local cd = target:FindFirstChildOfClass("ClickDetector")
	if cd then
		pcall(function() fireclickdetector(cd) end)
	end
	-- AttackEvent
	if attackRemote and attackRemote:IsA("RemoteEvent") then
		pcall(function() attackRemote:FireServer(target) end)
	end
end

local function startAutoClick()
	if autoClickLoop then return end
	autoClickLoop = RunService.Heartbeat:Connect(function()
		if clickActive and alvoAtual and alvoAtual.Parent then
			autoClick(alvoAtual)
		end
	end)
end

local function stopAutoClick()
	if autoClickLoop then
		autoClickLoop:Disconnect()
		autoClickLoop = nil
	end
end

-- Fixar alvo
local function fixarAlvo(model)
	if model and model.Parent then
		alvoAtual = model
	end
end

-- GUI (HoHo Hub Style)
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "MissionBotUI_v8"

-- Botão lateral
local sideBtn = Instance.new("TextButton", screenGui)
sideBtn.Size = UDim2.new(0,40,0,40)
sideBtn.Position = UDim2.new(0,6,0.5,-20)
sideBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
sideBtn.Text = "MB"
sideBtn.Font = Enum.Font.SourceSansBold
sideBtn.TextColor3 = Color3.new(1,1,1)
sideBtn.TextSize = 18

-- Frame principal
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,400,0,500)
frame.Position = UDim2.new(0,56,0.5,-250)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.Visible = false

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Position = UDim2.new(0,0,0,6)
title.BackgroundTransparency = 1
title.Text = "Mission Bot 8.0"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.new(1,1,1)

-- Label alvo
local targetLabel = Instance.new("TextLabel", frame)
targetLabel.Size = UDim2.new(1,0,0,20)
targetLabel.Position = UDim2.new(0,0,0,42)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "Alvo: nenhum"
targetLabel.Font = Enum.Font.SourceSans
targetLabel.TextSize = 14
targetLabel.TextColor3 = Color3.fromRGB(180,180,180)

-- Função botão
local function makeBtn(text,x,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0,180,0,36)
	b.Position = UDim2.new(0,x,0,y)
	b.Text = text
	b.Font = Enum.Font.SourceSans
	b.TextSize = 16
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	return b
end

-- Botões principais
local btnGoto = makeBtn("Voar até alvo",10,70)
local btnAutoClick = makeBtn("AutoClick: OFF",210,70)
local btnNoclip = makeBtn("Noclip: OFF",10,116)
local btnClear = makeBtn("Limpar Alvo",10,162)
local btnMinimize = makeBtn("Minimizar Menu",210,162)
local btnUpdateList = makeBtn("Atualizar Lista",10,210)
btnUpdateList.Size = UDim2.new(0,380,0,36)

-- Frame lista inimigos/missões
local listFrame = Instance.new("Frame", frame)
listFrame.Size = UDim2.new(1,-16,0,220)
listFrame.Position = UDim2.new(0,8,0,260)
listFrame.BackgroundColor3 = Color3.fromRGB(38,38,38)

local scrolling = Instance.new("ScrollingFrame", listFrame)
scrolling.Size = UDim2.new(1,0,1,0)
scrolling.BackgroundTransparency = 1
scrolling.ScrollBarThickness = 6
scrolling.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right

-- Atualiza lista inimigos/missões
local function atualizarListaManual()
	for _,c in ipairs(scrolling:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local y = 0
	local seen = {}
	for _,m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") then
			local h = safeFindHumanoid(m)
			if h and h.Health > 0 and not seen[m.Name] then
				seen[m.Name] = true
				local b = Instance.new("TextButton", scrolling)
				b.Size = UDim2.new(1,0,0,34)
				b.Position = UDim2.new(0,0,0,y)
				b.Text = m.Name
				b.MouseButton1Click:Connect(function()
					fixarAlvo(m)
					targetLabel.Text = "Alvo: "..m.Name
					for _,other in ipairs(scrolling:GetChildren()) do
						if other:IsA("TextButton") then
							other.BackgroundColor3 = Color3.fromRGB(50,50,50)
						end
					end
					b.BackgroundColor3 = Color3.fromRGB(0,255,0)
					startHover()
				end)
				y = y + 36
			end
		end
	end
	scrolling.CanvasSize = UDim2.new(0,0,y)
end

-- Botões eventos
sideBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

btnMinimize.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

btnGoto.MouseButton1Click:Connect(function()
	if flying then stopHover() else startHover() end
end)

btnAutoClick.MouseButton1Click:Connect(function()
	clickActive = not clickActive
	btnAutoClick.Text = clickActive and "AutoClick: ON" or "AutoClick: OFF"
	if clickActive then
		startAutoClick()
	else
		stopAutoClick()
	end
end)

btnNoclip.MouseButton1Click:Connect(function()
	noclipOn = not noclipOn
	btnNoclip.Text = noclipOn and "Noclip: ON" or "Noclip: OFF"
end)

btnClear.MouseButton1Click:Connect(function()
	alvoAtual = nil
	targetLabel.Text = "Alvo: nenhum"
	for _,other in ipairs(scrolling:GetChildren()) do
		if other:IsA("TextButton") then
			other.BackgroundColor3 = Color3.fromRGB(50,50,50)
		end
	end
	stopHover()
end)

btnUpdateList.MouseButton1Click:Connect(atualizarListaManual)

-- Auto trocar alvo após matar
RunService.Heartbeat:Connect(function()
	if alvoAtual then
		local h = safeFindHumanoid(alvoAtual)
		if not h or h.Health <= 0 then
			local nextT = findNextByName(alvoAtual.Name, alvoAtual)
			if nextT then
				fixarAlvo(nextT)
				targetLabel.Text = "Alvo: "..nextT.Name
				for _,btn in ipairs(scrolling:GetChildren()) do
					if btn:IsA("TextButton") and btn.Text == nextT.Name then
						for _,other in ipairs(scrolling:GetChildren()) do
							if other:IsA("TextButton") then
								other.BackgroundColor3 = Color3.fromRGB(50,50,50)
							end
						end
						btn.BackgroundColor3 = Color3.fromRGB(0,255,0)
						break
					end
				end
				startHover()
			else
				alvoAtual = nil
				targetLabel.Text = "Alvo: nenhum"
				stopHover()
			end
		else
			targetLabel.Text = "Alvo: "..alvoAtual.Name
		end
	end
end)

-- Inicializa lista
atualizarListaManual()
