local antoralib = loadstring(game:HttpGet("https://raw.githubusercontent.com/kust3r/BlackCatRedEye/refs/heads/main/abc.lua"))()
local Window = antoralib:MakeWindow({
    Title = "MoonCat",
    SubTitle = "",
    SaveFolder = "Stars.lua"
})

local Main = Window:MakeTab({"Main", "rbxassetid://18759129862"})

Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://102148214469417", BackgroundTransparency = 1 }
})

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
