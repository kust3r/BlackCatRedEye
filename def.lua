-- MoonCat Library
local antoralib = loadstring(game:HttpGet("https://raw.githubusercontent.com/kust3r/BlackCatRedEye/refs/heads/main/abc.lua"))()
local Window = antoralib:MakeWindow({
    Title = "Antora",
    SubTitle = "",
    SaveFolder = "Stars.lua"
})

local Main = Window:MakeTab({"Main", "rbxassetid://18759129862"})
Window:AddMinimizeButton({ Button = { Image = "rbxassetid://102148214469417", BackgroundTransparency = 1 } })

-- Utilitários Gerais
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:FindService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- Hooks e Proteções
RunService.RenderStepped:Connect(function()
    for _, c in next, getconnections(game:GetService("ScriptContext").Error) do c:Disable() end
    for _, c in next, getconnections(game:GetService("LogService").MessageOut) do c:Disable() end
end)

-- Remotes Utilitários
local function getRemoteTable()
    local nevermore_modules = rawget(require(ReplicatedStorage.Framework.Nevermore), "_lookupTable")
    local network = rawget(nevermore_modules, "Network")
    local remotes_table = getupvalue(getsenv(network).GetEventHandler, 1)
    local events_table = getupvalue(getsenv(network).GetFunctionHandler, 1)
    local remotes = {}
    table.foreach(remotes_table, function(i, v) if rawget(v, "Remote") then remotes[rawget(v, "Remote")] = i end end)
    table.foreach(events_table, function(i, v) if rawget(v, "Remote") then remotes[rawget(v, "Remote")] = i end end)
    return remotes
end

local function getRemote(name)
    local remotes = getRemoteTable()
    for i, v in pairs(remotes) do if i.Name == name then return i end end
end

-- Proteção contra Kick
local local_player = Players.LocalPlayer
local kick_hook; kick_hook = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local args = {...}
    local self = args[1]
    local namecall_method = getnamecallmethod()
    if not checkcaller() and self == local_player and namecall_method == "Kick" then return end
    return kick_hook(...)
end))

-- Proteção contra funções de punição
for _, b in next, getgc(true) do
    if typeof(b) == 'function' and getinfo(b).name == 'punish' then
        replaceclosure(b, function() return wait(9e9); end)
    end
end

-- Proteção contra LogKick e CreateAntiCheatNotification
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    if self.Name == "LogKick" or self.Name == "CreateAntiCheatNotification" then return end
    return old(self, ...)
end)

-- Proteção contra métodos de kick em tabelas
for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "kick") then v.kick = function() return end end
    if typeof(v) == 'table' and rawget(v, 'getIsBodyMoverCreatedByGame') then v.getIsBodyMoverCreatedByGame = function() return true end end
    if typeof(v) == "table" and rawget(v, "randomDelayKick") then v.randomDelayKick = function() return wait(9e9) end end
end

-- Proteção contra alteração de WalkSpeed
RunService.RenderStepped:Connect(function()
    if Players.LocalPlayer.Character then
        for _, v in pairs(getconnections(Players.LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("WalkSpeed"))) do v:Disable() end
    end
end)

-- Seção Player
local PlayerSection = Main:AddSection({"Player"})
local HideToggle = Main:AddToggle({ Title = "Hide Name", Default = false })
local hidename = false
HideToggle:Callback(function(Value) hidename = Value end)
task.spawn(function()
    RunService.Stepped:Connect(function()
        if hidename then getRemote("UpdateIsCrouching"):FireServer(true) else getRemote("UpdateIsCrouching"):FireServer(false) end
    end)
end)

-- Seção Ragdoll, Stamina, Jump, Fall Damage, Dash, Jump Cooldown, Utilities
local ToggleAntiRagdoll = Main:AddToggle({ Name = "No Ragdoll", Default = false })
local originalToggleRagdoll = {}
local ragdollTables = {}
local function cacheRagdollTables()
  ragdollTables = {}
  for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "toggleRagdoll") then
      table.insert(ragdollTables, v)
      originalToggleRagdoll[v] = v.toggleRagdoll
    end
  end
end
ToggleAntiRagdoll:Callback(function(Value)
  if #ragdollTables == 0 then cacheRagdollTables() end
  if Value then
    for _, v in pairs(ragdollTables) do v.toggleRagdoll = function(a, b) return end end
  else
    for _, v in pairs(ragdollTables) do if originalToggleRagdoll[v] then v.toggleRagdoll = originalToggleRagdoll[v] end end
  end
end)

local ToggleInfStamina = Main:AddToggle({ Name = "Inf Stamina", Default = false })
local originalSetStamina = {}
local staminaTables = {}
local function cacheStaminaTables()
  staminaTables = {}
  for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "_setStamina") then
      table.insert(staminaTables, v)
      originalSetStamina[v] = v._setStamina
    end
  end
end
ToggleInfStamina:Callback(function(Value)
  if #staminaTables == 0 then cacheStaminaTables() end
  if Value then
    for _, v in pairs(staminaTables) do
      v._setStamina = function(a, b)
        a._stamina = math.huge
        a._staminaChangedSignal:Fire(99)
      end
    end
  else
    for _, v in pairs(staminaTables) do if originalSetStamina[v] then v._setStamina = originalSetStamina[v] end end
  end
end)

local ToggleUnlockJump = Main:AddToggle({ Name = "Unlock Jump", Default = false })
local originalGetCanJump = {}
local unlockJumpTables = {}
local toggleActivated = false
local function cacheUnlockJumpTables()
    unlockJumpTables = {}
    for i,v in pairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "getCanJump") then
            table.insert(unlockJumpTables, v)
            originalGetCanJump[v] = v.getCanJump
        end
    end
end
ToggleUnlockJump:Callback(function(Value)
    if not toggleActivated and #unlockJumpTables == 0 then
        cacheUnlockJumpTables()
    end
    if Value then
        toggleActivated = true
        for _, v in pairs(unlockJumpTables) do
            v.getCanJump = function() return true end
        end
    else
        toggleActivated = false
        for _, v in pairs(unlockJumpTables) do
            if originalGetCanJump[v] then
                v.getCanJump = originalGetCanJump[v]
            end
        end
    end
end)

local ToggleNoFallDamage = Main:AddToggle({ Name = "No Fall Damage", Default = false })
local nofall = true
getgenv().fallremote = getRemote("TakeFallDamage")
local methodHook
methodHook = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and getnamecallmethod() == "FireServer" and nofall and self.Name == fallremote.Name then
        return
    end
    return methodHook(self, ...)
end)
ToggleNoFallDamage:Callback(function(Value) nofall = Value end)

local ToggleNoDashCooldown = Main:AddToggle({ Name = "No Dash Cooldown", Default = false })
local originalDashCooldown = {}
local dashCooldownTables = {}
local function cacheDashCooldownTables()
  dashCooldownTables = {}
  for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "DASH_COOLDOWN") then
      table.insert(dashCooldownTables, v)
      originalDashCooldown[v] = v.DASH_COOLDOWN
    end
  end
end
ToggleNoDashCooldown:Callback(function(Value)
  if #dashCooldownTables == 0 then cacheDashCooldownTables() end
  if Value then
    for _, v in pairs(dashCooldownTables) do v.DASH_COOLDOWN = 0 end
  else
    for _, v in pairs(dashCooldownTables) do if originalDashCooldown[v] then v.DASH_COOLDOWN = originalDashCooldown[v] end end
  end
end)

local ToggleNoJumpCooldown = Main:AddToggle({ Name = "No Jump Cooldown", Default = false })
local originalJumpCooldown = {}
local jumpCooldownTables = {}
local function cacheJumpCooldownTables()
  jumpCooldownTables = {}
  for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "JUMP_DELAY_ADD") then
      table.insert(jumpCooldownTables, v)
      originalJumpCooldown[v] = v.JUMP_DELAY_ADD
    end
  end
end
ToggleNoJumpCooldown:Callback(function(Value)
  if #jumpCooldownTables == 0 then cacheJumpCooldownTables() end
  if Value then
    for _, v in pairs(jumpCooldownTables) do v.JUMP_DELAY_ADD = 0 end
  else
    for _, v in pairs(jumpCooldownTables) do if originalJumpCooldown[v] then v.JUMP_DELAY_ADD = originalJumpCooldown[v] end end
  end
end)

local ToggleAntiUtilitiesDamage = Main:AddToggle({ Name = "No Utilities Damage", Default = false })
local UtilidadesSemDano = false
ToggleAntiUtilitiesDamage:Callback(function(Value) UtilidadesSemDano = Value end)
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
  local args = {...}
  if self.Name == "GotHitRE" and UtilidadesSemDano then
    return
  end
  return old(self, ...)
end)

-- Seção Visual (ESP, Highlight, Tracers)
local Visual = Main:AddSection({"Visual"})
local PlayerHighlightToggle = Main:AddToggle({ Name = "ESP Highlight", Default = false })
local function SetupPlayerHighlight()
    local FillColor = Color3.fromRGB(115,112,178)
    local DepthMode = "AlwaysOnTop"
    local FillTransparency = 0.5
    local OutlineColor = Color3.fromRGB(255, 255, 255)
    local OutlineTransparency = 0

    local CoreGui = game:FindService("CoreGui")
    local Players = game:FindService("Players")
    local lp = Players.LocalPlayer
    local connections = {}

    local Storage = Instance.new("Folder")
    Storage.Parent = CoreGui
    Storage.Name = "Highlight_Storage"

    local function Highlight(plr)
        if plr == lp then return end

        local Highlight = Instance.new("Highlight")
        Highlight.Name = plr.Name
        Highlight.FillColor = FillColor
        Highlight.DepthMode = DepthMode
        Highlight.FillTransparency = FillTransparency
        Highlight.OutlineColor = OutlineColor
        Highlight.OutlineTransparency = OutlineTransparency
        Highlight.Parent = Storage
        
        local plrchar = plr.Character
        if plrchar then
            Highlight.Adornee = plrchar
        end

        connections[plr] = plr.CharacterAdded:Connect(function(char)
            Highlight.Adornee = char
        end)
    end

    Players.PlayerAdded:Connect(Highlight)
    for i, v in next, Players:GetPlayers() do
        Highlight(v)
    end

    Players.PlayerRemoving:Connect(function(plr)
        local plrname = plr.Name
        if Storage:FindFirstChild(plrname) then
            Storage[plrname]:Destroy()
        end
        if connections[plr] then
            connections[plr]:Disconnect()
        end
    end)
end
PlayerHighlightToggle:Callback(function(Value)
    if Value then
        SetupPlayerHighlight()
    else
        local CoreGui = game:FindService("CoreGui")
        local Storage = CoreGui:FindFirstChild("Highlight_Storage")
        if Storage then
            Storage:Destroy()
        end
    end
end)

local ToggleESPName = Main:AddToggle({ Name = "ESP Name", Default = false })
local maxDistance = 400
local function applyESPName()
    _G.FriendColor = Color3.fromRGB(0, 0, 255)
    _G.EnemyColor = Color3.fromRGB(255, 0, 0)
    _G.UseTeamColor = true

    local Holder = Instance.new("Folder", game.CoreGui)
    Holder.Name = "ESP"

    local Box = Instance.new("BoxHandleAdornment")
    Box.Name = "nilBox"
    Box.Size = Vector3.new(1, 2, 1)
    Box.Color3 = Color3.new(100 / 255, 100 / 255, 100 / 255)
    Box.Transparency = 0.7
    Box.ZIndex = 0
    Box.AlwaysOnTop = false
    Box.Visible = false

    local NameTag = Instance.new("BillboardGui")
    NameTag.Name = "nilNameTag"
    NameTag.Enabled = false
    NameTag.Size = UDim2.new(0, 200, 0, 30)
    NameTag.AlwaysOnTop = true
    NameTag.StudsOffset = Vector3.new(0, 1.8, 0)
    local Tag = Instance.new("TextLabel", NameTag)
    Tag.Name = "Tag"
    Tag.BackgroundTransparency = 1
    Tag.Position = UDim2.new(0, -50, 0, 0)
    Tag.Size = UDim2.new(0, 300, 0, 20)
    Tag.TextSize = 15
    Tag.TextStrokeColor3 = Color3.new(0, 0, 0)
    Tag.TextStrokeTransparency = 0.4
    Tag.Font = Enum.Font.SourceSansBold
    Tag.TextScaled = false

    local function createGradientTween(textLabel)
        local function tweenColor(startColor, endColor)
            local goal = {TextColor3 = endColor}
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false)
            local tween = TweenService:Create(textLabel, tweenInfo, goal)
            tween.Completed:Connect(function()
                tweenColor(endColor, startColor)
            end)
            tween:Play()
        end
        tweenColor(Color3.fromRGB(210, 89, 163), Color3.fromRGB(111, 95, 216))
    end

    local LoadCharacter = function(v)
        repeat wait() until v.Character ~= nil
        local humanoid = v.Character:WaitForChild("Humanoid")
        local head = v.Character:WaitForChild("Head")

        local vHolder = Holder:FindFirstChild(v.Name)
        if not vHolder then
            vHolder = Instance.new("Folder", Holder)
            vHolder.Name = v.Name
        end

        local b = Box:Clone()
        b.Name = v.Name .. "Box"
        b.Adornee = v.Character
        b.Parent = vHolder

        local t = NameTag:Clone()
        t.Name = v.Name .. "NameTag"
        t.Parent = vHolder
        t.Adornee = head

        createGradientTween(t.Tag)

        local function updateVisibility()
            while true do
                wait(1)
                if v and v.Character and v.Character:IsDescendantOf(game) then
                    local camera = game.Workspace.CurrentCamera
                    local distance = (camera.CFrame.Position - head.Position).Magnitude
                    if distance <= maxDistance then
                        t.Enabled = true
                        t.Tag.Text = v.DisplayName
                    else
                        t.Enabled = false
                    end
                else
                    t.Enabled = false
                    break
                end
            end
        end

        updateVisibility()
    end

    local UnloadCharacter = function(v)
        local vHolder = Holder:FindFirstChild(v.Name)
        if vHolder then
            vHolder:ClearAllChildren()
            vHolder:Destroy()
        end
    end

    local LoadPlayer = function(v)
        if v == game.Players.LocalPlayer then return end
        v.CharacterAdded:Connect(function()
            pcall(LoadCharacter, v)
        end)
        v.CharacterRemoving:Connect(function()
            pcall(UnloadCharacter, v)
        end)
        v.Changed:Connect(function(prop)
            if prop == "TeamColor" then
                UnloadCharacter(v)
                wait()
                LoadCharacter(v)
            end
        end)
        LoadCharacter(v)
    end

    local UnloadPlayer = function(v)
        UnloadCharacter(v)
    end

    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v ~= game.Players.LocalPlayer then
            spawn(function() pcall(LoadPlayer, v) end)
        end
    end

    game:GetService("Players").PlayerAdded:Connect(function(v)
        if v ~= game.Players.LocalPlayer then
            pcall(LoadPlayer, v)
        end
    end)

    game:GetService("Players").PlayerRemoving:Connect(function(v)
        pcall(UnloadPlayer, v)
    end)
end
ToggleESPName:Callback(function(Value)
    if Value then
        applyESPName()
    else
        local ESPFolder = game.CoreGui:FindFirstChild("ESP")
        if ESPFolder then
            ESPFolder:Destroy()
        end
    end
end)

local tracerThickness = 0.1
local ToggleESPTracers = Main:AddToggle({ Name = "ESP Tracers", Default = false })
local playerTracers = {}
local tracerConnection
local function applyESPTracers()
    local lpr = game.Players.LocalPlayer
    local camera = game:GetService("Workspace").CurrentCamera
    local worldToViewportPoint = camera.WorldToViewportPoint

    _G.Teamcheck = false

    local color1 = Color3.fromRGB(210, 89, 163)
    local color2 = Color3.fromRGB(111, 95, 216)

    local function lerpColor(colorA, colorB, t)
        return Color3.new(
            colorA.R + (colorB.R - colorA.R) * t,
            colorA.G + (colorB.G - colorA.G) * t,
            colorA.B + (colorB.B - colorA.B) * t
        )
    end

    local function updateTracers()
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= lpr and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart and lpr.Character and lpr.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (rootPart.Position - lpr.Character.HumanoidRootPart.Position).Magnitude
                    
                    if distance <= 390 then
                        local screenPos, onScreen = worldToViewportPoint(camera, rootPart.Position)
                        
                        if onScreen then
                            local tracer = playerTracers[player]
                            
                            if not tracer then
                                tracer = Drawing.new("Line")
                                playerTracers[player] = tracer
                            end
                            
                            tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            local t = distance / 390
                            tracer.Color = lerpColor(color1, color2, t)
                            tracer.Thickness = tracerThickness
                            tracer.Transparency = 1
                            tracer.Visible = true
                            
                            if _G.Teamcheck and player.Team == lpr.Team then
                                tracer.Visible = false
                            end
                        else
                            if playerTracers[player] then
                                playerTracers[player].Visible = false
                            end
                        end
                    else
                        if playerTracers[player] then
                            playerTracers[player].Visible = false
                        end
                    end
                elseif playerTracers[player] then
                    playerTracers[player].Visible = false
                end
            elseif playerTracers[player] then
                playerTracers[player].Visible = false
            end
        end
    end

    tracerConnection = game:GetService("RunService").RenderStepped:Connect(function()
        updateTracers()
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        if playerTracers[player] then
            playerTracers[player]:Remove()
            playerTracers[player] = nil
        end
    end)
end
ToggleESPTracers:Callback(function(Value)
    if Value then
        applyESPTracers()
    else
        if tracerConnection then
            tracerConnection:Disconnect()
        end
        for _, tracer in pairs(playerTracers) do
            tracer:Remove()
        end
        playerTracers = {}
    end
end)

local Slider = Main:AddSlider({
    Name = "World Time",
    Min = 0,
    Max = 17,
    Increase = 1,
    Default = math.floor(game:GetService("Lighting"):GetMinutesAfterMidnight() / 60),
    Callback = function(Value)
        local Lighting = game:GetService("Lighting")
        Lighting:SetMinutesAfterMidnight(Value * 60)
    end
})

-- Seção Combat (Silent Aim, Wallbang, Auto Play, No Spread, No Recoil)
local Combat = Main:AddSection({"Combat"})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local remotes = {}
local players = {}

local hitpart = "Head"
local ARROW
local bruh = Instance.new("Highlight", game.CoreGui)
local shot = false
local arrowsshooted = 1
local silentaim = true
local wallcheck = false
local friendsCheck = false

local player = Players.LocalPlayer
local screenGui
local circleFrame
local circleRadius = 50

local function createGUI()
    if screenGui then
        screenGui:Destroy()
    end

    screenGui = Instance.new("ScreenGui", player.PlayerGui)
    screenGui.Name = "CentralGui"

    circleFrame = Instance.new("Frame")
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    circleFrame.Size = UDim2.new(0, circleRadius * 2, 0, circleRadius * 2)
    circleFrame.BackgroundTransparency = 1
    circleFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.5, 0)
    uiCorner.Parent = circleFrame

    local border = Instance.new("UIStroke")
    border.Parent = circleFrame
    border.Thickness = 1
    border.Color = Color3.fromRGB(255, 255, 255)
    border.Transparency = 0
end

local function destroyGUI()
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
        circleFrame = nil
    end
end

local function isWithinCircle(point, center, radius)
    return (point - center).Magnitude <= radius
end

local function isInLineOfSight(playerCharacter)
    local characterPosition = playerCharacter.HumanoidRootPart.Position
    local cameraPosition = workspace.CurrentCamera.CFrame.Position
    local direction = (characterPosition - cameraPosition).unit
    local ray = Ray.new(cameraPosition, direction * 500)
    local hit, position = workspace:FindPartOnRay(ray, player.Character)

    return not hit or hit:IsDescendantOf(playerCharacter)
end

local function isFriend(targetPlayer)
    return player:IsFriendsWith(targetPlayer.UserId)
end

local function getClosestPlayerWithinCircle()
    local closestPlayer = nil
    local shortestDistance = math.huge

    if not circleFrame then return nil end

    local circleCenter = Vector2.new(circleFrame.AbsolutePosition.X + circleFrame.AbsoluteSize.X / 2, circleFrame.AbsolutePosition.Y + circleFrame.AbsoluteSize.Y / 2)
    local circleRadius = circleFrame.AbsoluteSize.X / 2

    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer ~= Players.LocalPlayer and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer.Character:FindFirstChild("Humanoid").Health > 0 then
            local characterPosition = targetPlayer.Character.HumanoidRootPart.Position
            local screenPoint = workspace.CurrentCamera:WorldToScreenPoint(characterPosition)
            local point2D = Vector2.new(screenPoint.X, screenPoint.Y)
            
            if isWithinCircle(point2D, circleCenter, circleRadius) then
                if (not friendsCheck or not isFriend(targetPlayer)) and (not wallcheck or isInLineOfSight(targetPlayer.Character)) then
                    local distance = (point2D - circleCenter).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = targetPlayer
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function firehit(character, arrow)
    local fakepos = character[hitpart].Position + Vector3.new(math.random(1, 5), math.random(1, 5), math.random(1, 5))
    local args = {
        [1] = Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"),
        [2] = character[hitpart],
        [3] = fakepos,
        [4] = character[hitpart].CFrame:ToObjectSpace(CFrame.new(fakepos)),
        [5] = fakepos * Vector3.new(math.random(1, 5), math.random(1, 5), math.random(1, 5)),
        [6] = tostring(arrowsshooted)
    }
    if remotes["RangedHit"] then
        remotes["RangedHit"]:FireServer(unpack(args))
    end
end

for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" and rawget(v, "shoot") and typeof(v.shoot) == "function" then
        local Old = v.shoot
        v.shoot = function(tbl)
            shot = true
            arrowsshooted = tbl.shotIdx
            local targetPlayer = getClosestPlayerWithinCircle()
            if targetPlayer then
                return Old(tbl)
            end
            return Old(tbl)
        end
    end
    
    if typeof(v) == "table" and rawget(v, "calculateFireDirection") and typeof(v.calculateFireDirection) == "function" then
        local old = v.calculateFireDirection
        v.calculateFireDirection = function(p3, p4, p5, p6)
            local Tool = Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if not Tool:FindFirstChild("ClientAmmo") then
                return old(p3, p4, p5, p6)
            end
            if silentaim and shot then
                local targetPlayer = getClosestPlayerWithinCircle()
                if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local targetPosition = targetPlayer.Character.Head.Position
                    if hitpart == "Random" then
                        local randomHitPart = math.random(1, 2) == 1 and targetPlayer.Character.Head or targetPlayer.Character.Torso
                        targetPosition = randomHitPart.Position
                    else
                        targetPosition = targetPlayer.Character[hitpart].Position
                    end
                    local toolPosition = Tool.Contents.Handle.FirePoint.WorldCFrame.Position
                    return (CFrame.lookAt(toolPosition, targetPosition)).LookVector * 30
                end
            end
            return old(p3, p4, p5, p6)
        end
    end
end

task.spawn(function()
    while task.wait(0.2) do
        if silentaim then
            pcall(function()
                local bow = Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
                local targetPlayer = getClosestPlayerWithinCircle()
                if targetPlayer then
                    bruh.Adornee = targetPlayer.Character
                    bruh.Enabled = true
                else
                    bruh.Adornee = nil
                    bruh.Enabled = false
                end
                if ARROW and targetPlayer then
                    if (ARROW.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude <= 15 then
                        if silentaim then
                            firehit(targetPlayer.Character, ARROW)
                            ARROW = nil
                            shot = false
                        end
                    end
                end
            end)
        else
            bruh.Adornee = nil
            bruh.Enabled = false
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    if silentaim then
        createGUI()
    end
end)

local SilentCrlh = Main:AddToggle({ Name = "Silent Aim", Default = false })
SilentCrlh:Callback(function(Value)
    silentaim = Value
    if silentaim then
        createGUI()
    else
        destroyGUI()
    end
end)

local Dropdown = Main:AddDropdown({
    Name = "Aim Part",
    Options = {"Torso", "Head", "Random"},
    Default = "Random"
})
Dropdown:Callback(function(Value) hitpart = Value end)

local AimRangeSlider = Main:AddSlider({
    Name = "Aim Range",
    Min = 25,
    Max = 750,
    Default = 75,
    Callback = function(Value)
        circleRadius = Value
        if circleFrame then
            circleFrame.Size = UDim2.new(0, circleRadius * 2, 0, circleRadius * 2)
        end
    end
})

local FriendsCheckToggle = Main:AddToggle({ Name = "Friends Check", Default = false })
FriendsCheckToggle:Callback(function(Value) friendsCheck = Value end)

local WallCheckToggle = Main:AddToggle({ Name = "Wall Check", Default = false })
WallCheckToggle:Callback(function(Value) wallcheck = Value end)

local WallbangEnabled = false
Main:AddToggle({
    Name = "Wallbang",
    Default = false,
    Callback = function(Value)
        WallbangEnabled = Value
        local workspace = game:GetService("Workspace")
        local collectionService = game:GetService("CollectionService")
        local map = workspace.Map

        if WallbangEnabled then
            collectionService:AddTag(map, 'RANGED_CASTER_IGNORE_LIST')
        else
            collectionService:RemoveTag(map, 'RANGED_CASTER_IGNORE_LIST')
        end
    end,
})

local AutoPlayEnabled = false
local autoSpawnRunning = false
local function AutoSpawnScript()
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")

    local function Check()
        if Player.PlayerGui:FindFirstChild("RoactUI") and Player.PlayerGui.RoactUI:FindFirstChild("MainMenu") and Workspace:FindFirstChild("Map") then
            keypress(0x20)
            keyrelease(0x20)
        end
    end

    while autoSpawnRunning do
        if Player.PlayerGui:FindFirstChild("RoactUI") and Player.PlayerGui.RoactUI:FindFirstChild("MainMenu") and Workspace:FindFirstChild("Map") then
            Check()
        end
        task.wait()
    end
end

local AutoPlayToggle = Main:AddToggle({ Name = "Auto Play", Default = false })
AutoPlayToggle:Callback(function(isEnabled)
    autoSpawnRunning = isEnabled
    if isEnabled then
        spawn(AutoSpawnScript)
    end
end)

local originalMaxSpread = {}
local spreadTables = {}
local function cacheSpreadTables()
    spreadTables = {}
    for _, obj in pairs(getgc(true)) do
        if typeof(obj) == 'table' and rawget(obj, 'maxSpread') then
            table.insert(spreadTables, obj)
            originalMaxSpread[obj] = obj.maxSpread
        end
    end
end
local ToggleNoSpread = Main:AddToggle({ Name = "No Spread", Default = false })
ToggleNoSpread:Callback(function(Value)
    if #spreadTables == 0 then cacheSpreadTables() end
    if Value then
        for _, obj in pairs(spreadTables) do obj.maxSpread = 0 end
    else
        for _, obj in pairs(spreadTables) do if originalMaxSpread[obj] then obj.maxSpread = originalMaxSpread[obj] end end
    end
end)

local ToggleNoRecoil = Main:AddToggle({ Name = "No Recoil", Default = false })
local originalRecoilValues = {}
local recoilTables = {}
local function cacheRecoilTables()
    recoilTables = {}
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "recoilAmount") then
            table.insert(recoilTables, v)
            originalRecoilValues[v] = {
                recoilAmount = v.recoilAmount,
                recoilXMin = v.recoilXMin,
                recoilXMax = v.recoilXMax,
                recoilYMin = v.recoilYMin,
                recoilYMax = v.recoilYMax,
                recoilZMin = v.recoilZMin,
                recoilZMax = v.recoilZMax
            }
        end
    end
end
ToggleNoRecoil:Callback(function(Value)
    if #recoilTables == 0 then cacheRecoilTables() end
    if Value then
        for _, v in pairs(recoilTables) do
            v.recoilAmount = 0
            v.recoilXMin = 0
            v.recoilXMax = 0
            v.recoilYMin = 0
            v.recoilYMax = 0
            v.recoilZMin = 0
            v.recoilZMax = 0
        end
    else
        for _, v in pairs(recoilTables) do
            local original = originalRecoilValues[v]
            if original then
                v.recoilAmount = original.recoilAmount
                v.recoilXMin = original.recoilXMin
                v.recoilXMax = original.recoilXMax
                v.recoilYMin = original.recoilYMin
                v.recoilYMax = original.recoilYMax
                v.recoilZMin = original.recoilZMin
                v.recoilZMax = original.recoilZMax
            end
        end
    end
end)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

_G.AirdropAura = false
local function ChmrPrompt()
    while _G.AirdropAura do
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, child in ipairs(map:GetChildren()) do
                if child.Name:match("Airdrop") then
                    local crate = child:FindFirstChild("Crate")
                    if crate then
                        local hitbox = crate:FindFirstChild("Hitbox")
                        if hitbox then
                            local proximityPrompt = hitbox:FindFirstChild("ProximityPrompt")
                            if proximityPrompt then
                                fireproximityprompt(proximityPrompt)
                            end
                        end
                    end
                end
            end
        end
        wait()
    end
end

local Airdrop = Main:AddToggle({ Name = "Airdrop Aura", Default = false })
Airdrop:Callback(function(Value)
    _G.AirdropAura = Value
    if _G.AirdropAura then
        coroutine.wrap(ChmrPrompt)()
    end
end)

local function notifyAirdrop(airdropName)
    game.StarterGui:SetCore("SendNotification", {
        Title = airdropName;
        Text = "has been spawned";
        Duration = 5;
    })
end

local function monitorAirdrops()
    local notifiedAirdrops = {}

    local map = workspace:FindFirstChild("Map")
    if map then
        for _, child in ipairs(map:GetChildren()) do
            if child.Name:match("Airdrop") then
                notifiedAirdrops[child] = true
            end
        end
    end

    while _G.NotifyAirdrop do
        if map then
            for _, child in ipairs(map:GetChildren()) do
                if child.Name:match("Airdrop") and not notifiedAirdrops[child] then
                    notifyAirdrop(child.Name)
                    notifiedAirdrops[child] = true
                end
            end
        end
        wait()
    end
end

local AirdropNotifyToggle = Main:AddToggle({ Name = "Notify Airdrop", Default = false })
AirdropNotifyToggle:Callback(function(Value)
    _G.NotifyAirdrop = Value
    if _G.NotifyAirdrop then
        coroutine.wrap(monitorAirdrops)()
    end
end)

local buttonRespawnGuiElements = {}
local ToggleButtonRespawn = Main:AddToggle({ Name = "Button Respawn", Default = false })
ToggleButtonRespawn:Callback(function(Value)
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function createGuiElement(className, properties)
        local element = Instance.new(className)
        for property, value in pairs(properties) do
            element[property] = value
        end
        table.insert(buttonRespawnGuiElements, element)
        return element
    end

    local function animateTransparency(element, targetTransparency, callback)
        local tween = tweenService:Create(element, tweenInfo, {BackgroundTransparency = targetTransparency})
        tween.Completed:Connect(callback)
        tween:Play()
    end

    local function animateTextTransparency(element, targetTransparency, callback)
        local tween = tweenService:Create(element, tweenInfo, {TextTransparency = targetTransparency})
        tween.Completed:Connect(callback)
        tween:Play()
    end

    if Value then
        local screenGui = Instance.new("ScreenGui")
        screenGui.Parent = game:GetService("CoreGui")
        screenGui.Enabled = true
        table.insert(buttonRespawnGuiElements, screenGui)

        local Fundo = createGuiElement("Frame", {
            Size = UDim2.new(0, 60, 0, 35),
            Position = UDim2.new(0.2, 0, 0.22, 0),
            BackgroundColor3 = Color3.fromRGB(21, 21, 21),
            BackgroundTransparency = 1,
            Parent = screenGui
        })

        local FundoCorner = createGuiElement("UICorner", {
            CornerRadius = UDim.new(0, 17.5),
            Parent = Fundo
        })

        local chamada = createGuiElement("TextButton", {
            Name = "Toggle",
            Text = "Respawn",
            TextSize = 12,
            TextColor3 = Color3.new(1, 1, 1),
            TextTransparency = 1,
            Font = Enum.Font.GothamBold,
            Size = UDim2.new(0, 60, 0, 35),
            Position = UDim2.new(0.2, 0, 0.22, 0),
            BackgroundTransparency = 1,
            Parent = screenGui,
            Draggable = true
        })

        local respawnGradient = Instance.new("UIGradient")
        respawnGradient.Rotation = 90
        respawnGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 89, 163)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(111, 95, 216))
        })
        respawnGradient.Parent = chamada
        table.insert(buttonRespawnGuiElements, respawnGradient)

        chamada.MouseEnter:Connect(function()
            respawnGradient.Rotation = 0
        end)

        chamada.MouseLeave:Connect(function()
            respawnGradient.Rotation = 0
        end)

        chamada.MouseButton1Click:Connect(function()
            local nevermore_modules = rawget(require(game.ReplicatedStorage.Framework.Nevermore), "_lookupTable")
            local network = rawget(nevermore_modules, "Network")
            local remotes_table = getupvalue(getsenv(network).GetEventHandler, 1)
            local events_table = getupvalue(getsenv(network).GetFunctionHandler, 1)
            local remotes = {}

            table.foreach(remotes_table, function(i, v)
                if rawget(v, "Remote") then
                    remotes[rawget(v, "Remote")] = i
                end
            end)

            table.foreach(events_table, function(i, v)
                if rawget(v, "Remote") then
                    remotes[rawget(v, "Remote")] = i
                end
            end)

            local pog
            pog = hookmetamethod(game, "__index", function(self, key)
                if (key == "Name" or key == "name") and remotes[self] then
                    return remotes[self]
                end

                return pog(self, key)
            end)

            pcall(function()
                for i = 1, 25 do
                    getRemote("StartFastRespawn"):FireServer()
                    getRemote("CompleteFastRespawn"):FireServer()
                end
            end)

            chamada.TextColor3 = Color3.fromRGB(111, 95, 216)
            wait(0.1)
            chamada.TextColor3 = Color3.new(1, 1, 1)
        end)

        animateTransparency(Fundo, 0)
        animateTextTransparency(chamada, 0)
    else
        for _, element in ipairs(buttonRespawnGuiElements) do
            if element:IsA("GuiObject") then
                animateTransparency(element, 1, function()
                    element:Destroy()
                end)
                if element:IsA("TextButton") or element:IsA("TextLabel") then
                    animateTextTransparency(element, 1, function()
                        element:Destroy()
                    end)
                end
            else
                element:Destroy()
            end
        end
        buttonRespawnGuiElements = {}
    end
end)

local ToggleInstaFastRespawn = Main:AddToggle({ Name = "Insta Fast Respawn", Default = false })
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local isScriptEnabled = false
local characterAddedConnection

local function getRemote(name)
    local nevermore_modules = rawget(require(game.ReplicatedStorage.Framework.Nevermore), "_lookupTable")
    local network = rawget(nevermore_modules, "Network")
    local remotes_table = getupvalue(getsenv(network).GetEventHandler, 1)
    local events_table = getupvalue(getsenv(network).GetFunctionHandler, 1)
    local remotes = {}

    table.foreach(remotes_table, function(i, v)
        if rawget(v, "Remote") then
            remotes[rawget(v, "Remote")] = i
        end
    end)

    table.foreach(events_table, function(i, v)
        if rawget(v, "Remote") then
            remotes[rawget(v, "Remote")] = i
        end
    end)

    for i, v in pairs(remotes) do
        if i.Name == name then
            return i
        end
    end
end

local function onCharacterAdded(character)
    if not isScriptEnabled then return end

    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if not isScriptEnabled then return end

        local startRemote = getRemote("StartFastRespawn")
        local completeRemote = getRemote("CompleteFastRespawn")

        if startRemote and completeRemote then
            for i = 1, 25 do
                startRemote:FireServer()
                completeRemote:FireServer()
                wait()
            end
        end
    end)
end

ToggleInstaFastRespawn:Callback(function(Value)
    isScriptEnabled = Value

    if isScriptEnabled then
        if LocalPlayer.Character then
            onCharacterAdded(LocalPlayer.Character)
        end
        if not characterAddedConnection then
            characterAddedConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
        end
    else
        if characterAddedConnection then
            characterAddedConnection:Disconnect()
            characterAddedConnection = nil
        end
    end
end)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

local HitboxSize = 5
local HitboxExpanderEnabled = false
local SelectedPart = "Torso"
local FriendsCheck = false
local UpdateInterval = 1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local alteredParts = {}

local function ResetPart(part)
    if part then
        local defaultSize = part.Name == "Torso" and Vector3.new(2, 2, 1) or Vector3.new(2, 1, 1)
        if part.Size ~= defaultSize then
            part.Size = defaultSize
            part.Transparency = 0
            part.CanCollide = true
            part.Massless = false
            alteredParts[part] = nil
        end
    end
end

local function ResetHitbox(player)
    if player ~= Players.LocalPlayer then
        local head = player.Character and player.Character:FindFirstChild("Head")
        local torso = player.Character and player.Character:FindFirstChild("Torso")
        ResetPart(head)
        ResetPart(torso)
    end
end

local function ApplyHitboxExpander(player)
    if player ~= Players.LocalPlayer and player.Character and not (FriendsCheck and Players.LocalPlayer:IsFriendsWith(player.UserId)) then
        local partToExpand = SelectedPart == "Torso" and player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("Head")
        local otherPart = SelectedPart == "Torso" and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("Torso")
        
        -- Reseta a outra parte para garantir que só a selecionada seja alterada
        ResetPart(otherPart)

        -- Aplica a expansão na parte selecionada
        if partToExpand and (partToExpand.Size ~= Vector3.new(HitboxSize, HitboxSize, HitboxSize) or not alteredParts[partToExpand]) then
            partToExpand.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
            partToExpand.Transparency = 1
            partToExpand.CanCollide = false
            partToExpand.Massless = true
            alteredParts[partToExpand] = true
        end
    end
end

local function UpdateAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            if HitboxExpanderEnabled and player ~= Players.LocalPlayer then
                ApplyHitboxExpander(player)
            else
                ResetHitbox(player)
            end
        end)
    end
end

local function RemoveHitboxForFriends()
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            if player ~= Players.LocalPlayer and Players.LocalPlayer:IsFriendsWith(player.UserId) then
                ResetHitbox(player)
            end
        end)
    end
end

local function HitboxExpanderScript()
    while HitboxExpanderEnabled do
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                ApplyHitboxExpander(player)
            end)
        end
        RunService.Heartbeat:Wait(UpdateInterval)
    end
end

Main:AddToggle({
    Name = "Hitbox Expander",
    Default = false,
    Callback = function(Value)
        HitboxExpanderEnabled = Value
        if Value then
            coroutine.wrap(HitboxExpanderScript)()
        else
            UpdateAllHitboxes()
        end
    end,
})

Main:AddSlider({
    Name = "Hitbox Size",
    Min = 2,
    Max = 15,
    Increase = 1,
    Default = 5,
    Callback = function(Value)
        HitboxSize = Value
        if HitboxExpanderEnabled then
            UpdateAllHitboxes()
        end
    end,
})

Main:AddDropdown({
    Name = "Hitbox Part",
    Options = {"Torso", "Head"},
    Default = "Torso",
    Flag = "HitboxPartSelection",
    Callback = function(Value)
        if SelectedPart ~= Value then
            local previousPart = SelectedPart
            SelectedPart = Value
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function()
                    if HitboxExpanderEnabled and player ~= Players.LocalPlayer then
                        local previousSelectedPart = previousPart == "Torso" and player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("Head")
                        ResetPart(previousSelectedPart)
                        ApplyHitboxExpander(player)
                    end
                end)
            end
        end
    end,
})

Main:AddToggle({
    Name = "Friends Check",
    Default = false,
    Callback = function(Value)
        FriendsCheck = Value
        RemoveHitboxForFriends()
        if HitboxExpanderEnabled then
            UpdateAllHitboxes()
        end
    end,
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        UpdateAllHitboxes()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    ResetHitbox(player)
end)
