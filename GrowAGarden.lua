-- =========================================================================
--  ZYLOHUB - GROW A GARDEN ENGINE (v3.5 OFFICIAL)
--  Powered by ZyloLib Engine (Clean 0 Register Overflow Architecture)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- [1] LOAD ZYLOLIB FRAMEWORK
local ZyloLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/ZyloLib.lua"))()

-- [2] STATE & REMOTES
local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents") or ReplicatedStorage:WaitForChild("GameEvents", 6)
local Plant_RE = GameEvents and (GameEvents:FindFirstChild("Plant_RE") or GameEvents:WaitForChild("Plant_RE", 4))
local Sell_Inventory = GameEvents and (GameEvents:FindFirstChild("Sell_Inventory") or GameEvents:WaitForChild("Sell_Inventory", 4))
local PetEggService = GameEvents and (GameEvents:FindFirstChild("PetEggService") or GameEvents:WaitForChild("PetEggService", 4))
local Farms = workspace:FindFirstChild("Farm")

local State = {
    AutoPlant = false,
    AutoHarvest = false,
    AutoSell = false,
    SelectedSeed = "",
    SearchSeedQuery = "",
    SellThreshold = 15,
    PlantMode = "UnderPlayer",

    SelectedEgg = "All Eggs",
    PlacePosition = "Good Position",
    AutoPlaceEgg = false,
    MaxEggPlace = 13,
    FarmEggCount = 0,

    AutoHatch = false,
    PetTeamActive = false,
    CurrentTeam = "Main Team",
    DelayEquip = 0,
    DelayUnequip = 1,
    PetSearchQuery = "",
    Teams = {
        ["Main Team"] = {},
        ["Bronto Team"] = {},
        ["Hatch Team"] = {},
        ["Sell Team"] = {}
    },

    Walkspeed = false,
    InfJump = false,
    Noclip = false,
    AntiAfk = true,
    SpeedVal = 42
}

local function GetFarm()
    if not Farms then return nil end
    for _, farm in ipairs(Farms:GetChildren()) do
        local imp = farm:FindFirstChild("Important")
        local data = imp and imp:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and (owner.Value == LocalPlayer.Name or owner.Value == LocalPlayer.UserId) then
            return farm
        end
    end
    return nil
end

local function GetCanPlantParts()
    local parts = {}
    local farm = GetFarm()
    if not farm then return parts end
    local imp = farm:FindFirstChild("Important")
    local plantLocs = imp and imp:FindFirstChild("Plant_Locations")
    if not plantLocs then return parts end
    for _, obj in ipairs(plantLocs:GetChildren()) do
        if obj:IsA("BasePart") then table.insert(parts, obj) end
    end
    return parts
end

-- 13 Titik Slot Telur Resmi
local EggCFrameList = {
    CFrame.new(72.7, 3.5, -9.1), CFrame.new(72.7, 3.5, -5.9),
    CFrame.new(72.7, 3.5, -2.7), CFrame.new(72.7, 3.5, 0.5),
    CFrame.new(72.7, 3.5, 3.7),  CFrame.new(72.7, 3.5, 6.9),
    CFrame.new(72.7, 3.5, 10.1), CFrame.new(72.7, 3.5, 13.3),
    CFrame.new(72.7, 3.5, 16.5), CFrame.new(72.7, 3.5, 19.7),
    CFrame.new(72.7, 3.5, 22.9), CFrame.new(72.7, 3.5, 26.1),
    CFrame.new(72.7, 3.5, 29.3)
}

-- [3] WORKER LOOPS
task.spawn(function()
    while true do
        if State.AutoPlaceEgg and PetEggService then
            pcall(function()
                local bp = LocalPlayer:FindFirstChild("Backpack")
                local eggTool = nil
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") and t.Name:lower():find("egg") and not t.Name:lower():find("eggplant") then
                            eggTool = t break
                        end
                    end
                end

                if eggTool and Humanoid then
                    for i = 1, math.min(#EggCFrameList, State.MaxEggPlace) do
                        if not State.AutoPlaceEgg then break end
                        if eggTool.Parent == bp then Humanoid:EquipTool(eggTool) task.wait(0.1) end
                        PetEggService:FireServer("CreateEgg", EggCFrameList[i].Position)
                        task.wait(0.35)
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while true do
        if State.AutoHarvest then
            pcall(function()
                local farm = GetFarm()
                local imp = farm and farm:FindFirstChild("Important")
                local plants = imp and imp:FindFirstChild("Plants_Physical")
                if plants then
                    for _, plant in ipairs(plants:GetChildren()) do
                        if not State.AutoHarvest then break end
                        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            prompt.HoldDuration = 0
                            if fireproximityprompt then fireproximityprompt(prompt) end
                            task.wait(0.04)
                        end
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- Anti AFK, Noclip, Mobility
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if State.AntiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
    UserInputService.JumpRequest:Connect(function()
        if State.InfJump and Character then
            local h = Character:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end)

RunService.Stepped:Connect(function()
    if State.Noclip and Character then
        for _, p in ipairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if State.Walkspeed and Humanoid then
        Humanoid.WalkSpeed = State.SpeedVal
    end
end)

-- [4] MEMBANGUN UI DENGAN ZYLOLIB
local Window = ZyloLib:CreateWindow({
    Title = "ZYLOHUB",
    SubTitle = "Grow a Garden",
    Version = "v3.5"
})

-- Buat 9 Tab Resmi ZyloHub
local TabHome      = Window:CreateTab("Home", "🏠", 1, 300)
local TabFarm      = Window:CreateTab("Farm", "🌿", 2, 450)
local TabPets      = Window:CreateTab("Pets", "🐾", 3, 450)
local TabUtility   = Window:CreateTab("Utility", "🔧", 4, 300)
local TabShop      = Window:CreateTab("Shop", "🛒", 5, 200)
local TabConfig    = Window:CreateTab("Config", "⚙️", 6, 200)
local TabEvent     = Window:CreateTab("Event", "⭐", 7, 200)
local TabInventory = Window:CreateTab("Inventory", "🎒", 8, 200)
local TabWebhook   = Window:CreateTab("Webhook", "🔗", 9, 200)

-- Helper Row
local function addRow(parent, y, text, default, cb)
    local r = Instance.new("Frame", parent)
    r.Position = UDim2.new(0, 12, 0, y)
    r.Size = UDim2.new(1, -24, 0, 32)
    r.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", r)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(245, 247, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9.5
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sw = ZyloLib:CreatePillSwitch(r, default, cb)
    sw.Position = UDim2.new(1, -42, 0.5, -10)
    return r
end

-- TAB FARM
local fCard = Instance.new("Frame", TabFarm.Page)
fCard.Size = UDim2.new(1, 0, 0, 260)
fCard.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
Instance.new("UICorner", fCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", fCard).Color = Color3.fromRGB(30, 36, 68)

local fcTitle = Instance.new("TextLabel", fCard)
fcTitle.Position = UDim2.new(0, 12, 0, 10)
fcTitle.Size = UDim2.new(1, -24, 0, 14)
fcTitle.BackgroundTransparency = 1
fcTitle.Text = "🌱  AUTO PLANT & HARVEST ENGINE"
fcTitle.TextColor3 = Color3.fromRGB(175, 82, 255)
fcTitle.Font = Enum.Font.GothamBold
fcTitle.TextSize = 11
fcTitle.TextXAlignment = Enum.TextXAlignment.Left

addRow(fCard, 36, "Auto Harvest (Panen Cepat & Mulus)", State.AutoHarvest, function(v) State.AutoHarvest = v end)
addRow(fCard, 76, "Auto Plant (Tanam + Auto Equip)", State.AutoPlant, function(v) State.AutoPlant = v end)
addRow(fCard, 116, "Auto Sell Otomatis", State.AutoSell, function(v) State.AutoSell = v end)

-- TAB PETS (13 Titik PetEggService)
local pCard = Instance.new("Frame", TabPets.Page)
pCard.Size = UDim2.new(1, 0, 0, 260)
pCard.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
Instance.new("UICorner", pCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", pCard).Color = Color3.fromRGB(30, 36, 68)

local pcTitle = Instance.new("TextLabel", pCard)
pcTitle.Position = UDim2.new(0, 12, 0, 10)
pcTitle.Size = UDim2.new(1, -24, 0, 14)
pcTitle.BackgroundTransparency = 1
pcTitle.Text = "🐾  AUTO PLACE EGG & PET TEAM"
pcTitle.TextColor3 = Color3.fromRGB(175, 82, 255)
pcTitle.Font = Enum.Font.GothamBold
pcTitle.TextSize = 11
pcTitle.TextXAlignment = Enum.TextXAlignment.Left

addRow(pCard, 36, "Auto Place Egg (13 Titik PetEggService)", State.AutoPlaceEgg, function(v) State.AutoPlaceEgg = v end)
addRow(pCard, 76, "Auto Hatch & Tetaskan Telur", State.AutoHatch, function(v) State.AutoHatch = v end)
addRow(pCard, 116, "Pet Team Manager (Auto Equip Team)", State.PetTeamActive, function(v) State.PetTeamActive = v end)

-- TAB UTILITY
local uCard = Instance.new("Frame", TabUtility.Page)
uCard.Size = UDim2.new(1, 0, 0, 220)
uCard.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
Instance.new("UICorner", uCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", uCard).Color = Color3.fromRGB(30, 36, 68)

local ucTitle = Instance.new("TextLabel", uCard)
ucTitle.Position = UDim2.new(0, 12, 0, 10)
ucTitle.Size = UDim2.new(1, -24, 0, 14)
ucTitle.BackgroundTransparency = 1
ucTitle.Text = "⚡  PLAYER UTILITY"
ucTitle.TextColor3 = Color3.fromRGB(175, 82, 255)
ucTitle.Font = Enum.Font.GothamBold
ucTitle.TextSize = 11
ucTitle.TextXAlignment = Enum.TextXAlignment.Left

addRow(uCard, 34, "Infinite Jump (Lompat Tanpa Batas)", State.InfJump, function(v) State.InfJump = v end)
addRow(uCard, 72, "Noclip (Tembus Dinding & Pagar)", State.Noclip, function(v) State.Noclip = v end)
addRow(uCard, 110, "Anti-AFK 20 Menit", State.AntiAfk, function(v) State.AntiAfk = v end)
addRow(uCard, 148, "WalkSpeed Boost (Lari Cepat 42 Studs)", State.Walkspeed, function(v)
    State.Walkspeed = v
    if not v and Humanoid then Humanoid.WalkSpeed = 16 end
end)

-- Default Buka Tab Pets
Window:SelectTab("Pets")

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ZyloHub v3.5",
        Text = "ZyloLib Engine Loaded! Klik tombol Z untuk buka.",
        Duration = 6
    })
end)
