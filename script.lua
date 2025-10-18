-- Mission Bot 9.1 (Hover + AutoClick Funcional + AutoSwitch)
-- LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- CONFIGURAÇÕES
local hoverHeight = 10
local attackRate = 3 -- ataques por segundo
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
	return (h and h:IsA("Humanoid") and h.Health > 0) and h or nil
end

local function findNextByName(name, skipModel)
	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Model") and v.Name == name and v ~= skipModel then
			local h = safeFindHumanoid(v)
			if h then return v end
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

-- Hover e PlatformStand
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
			stopHover()
			return
		end
		local targetHRP = alvoAtual:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end
		root.CFrame = root.CFrame:Lerp(CFrame.new(targetHRP.Position + Vector3.new(0, hoverHeight, 0), targetHRP.Position), lerpSpeed)
		Camera.CFrame = CFrame.new(root.Position + Vector3.new(0,5,10), root.Position)
	end)
end

local function stopHover()
	flying = false
	setLying(false)
	if hoverConn then hoverConn:Disconnect() hoverConn=nil end
end

-- AutoClick funcional com cooldown
local function autoClickLoopFunc()
	while clickActive do
		if alvoAtual and alvoAtual.Parent then
			local cd = alvoAtual:FindFirstChildOfClass("ClickDetector")
			if cd then pcall(function() fireclickdetector(cd) end) end
			if attackRemote and attackRemote:IsA("RemoteEvent") then
				pcall(function() attackRemote:FireServer(alvoAtual) end)
			end
		else
			-- Troca para próximo inimigo automaticamente
			if alvoAtual then
				local nextT = findNextByName(alvoAtual.Name, alvoAtual)
				if nextT then alvoAtual = nextT else alvoAtual = nil end
			end
		end
		wait(1/attackRate)
	end
end

local function startAutoClick()
	if autoClickLoop then return end
	autoClickLoop = coroutine.wrap(autoClickLoopFunc)
	autoClickLoop()
end

local function stopAutoClick()
	clickActive = false
end

-- Fixar alvo
local function fixarAlvo(model)
	if model and model.Parent then
		alvoAtual = model
	end
end

-- Exemplo de GUI simplificada (pode expandir para missões)
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "MissionBotUI_v9"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0,400,0,550)
frame.Position = UDim2.new(0,50,0,50)
frame.BackgroundColor3 = Color3.fromRGB(28,28,28)
frame.Visible = true

local targetLabel = Instance.new("TextLabel", frame)
targetLabel.Size = UDim2.new(1,0,0,20)
targetLabel.Position = UDim2.new(0,0,0,10)
targetLabel.Text = "Alvo: nenhum"
targetLabel.TextColor3 = Color3.new(1,1,1)

local function makeBtn(text,x,y)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(0,180,0,36)
	b.Position = UDim2.new(0,x,0,y)
	b.Text = text
	return b
end

local btnGoto = makeBtn("Voar até alvo",10,50)
local btnAutoClick = makeBtn("AutoClick: OFF",210,50)
local btnClear = makeBtn("Limpar Alvo",10,100)

btnGoto.MouseButton1Click:Connect(function()
	if flying then stopHover() else startHover() end
end)

btnAutoClick.MouseButton1Click:Connect(function()
	clickActive = not clickActive
	btnAutoClick.Text = clickActive and "AutoClick: ON" or "AutoClick: OFF"
	if clickActive then startAutoClick() else stopAutoClick() end
end)

btnClear.MouseButton1Click:Connect(function()
	alvoAtual = nil
	targetLabel.Text = "Alvo: nenhum"
end)

-- Atualização automática de alvo
RunService.Heartbeat:Connect(function()
	if alvoAtual then
		local h = safeFindHumanoid(alvoAtual)
		if not h then
			local nextT = findNextByName(alvoAtual.Name, alvoAtual)
			alvoAtual = nextT
		end
		targetLabel.Text = alvoAtual and "Alvo: "..alvoAtual.Name or "Alvo: nenhum"
	end
end)
