-- =========================================================================
--  ZYLOHUB - GROW A GARDEN (v3.5 - SAFE MODULAR EDITION)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: AUTO FARM & AUTO PLACE EGG LOCKED (100% PRESERVED & PRECISE)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- [A] LOAD ZYLOLIB FRAMEWORK
local ZyloLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/ZyloLib.lua"))()
local C = ZyloLib.Colors

-- [B] SERVICES & REMOTES RESMI
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
local Plant_RE = GameEvents and GameEvents:WaitForChild("Plant_RE", 5)
local Sell_Inventory = GameEvents and GameEvents:WaitForChild("Sell_Inventory", 5)
local BuySeedStock = GameEvents and GameEvents:WaitForChild("BuySeedStock", 5)
local PetEggService = GameEvents and GameEvents:WaitForChild("PetEggService", 5)

local Farms = workspace:WaitForChild("Farm", 10)

local State = {
    -- [LOCKED] Auto Farm & Egg States
    AutoPlant = false,
    PlantMode = "UnderPlayer",
    AutoHarvest = false,
    HarvestRadius = 50,
    AutoSell = false,
    AutoBuySeed = false,
    SelectedSeed = "Carrot",
    CustomPlantPos = nil,
    AutoPlaceEgg = false,
    SelectedEgg = "Common Egg",
    SelectedEggSlot = 1,
    EggPlaceSpeed = 0.5,
    SelectedEggSlotName = "Egg Slot 1",

    -- Pet Hatch & Sell States
    AutoHatch = false,
    HatchSpeed = 0.3,
    SelectedHatchEgg = "Common Egg",
    AutoSellPets = false,
    PetSellDelay = 0.5,
    SellThreshold = 3,
    KeepRares = true,
    MinWeightToKeep = 3,
    PetRarities = {},
    DiscordWebhookUrl = "",
    WebhookEnabled = false,
    
    -- Pet Team Manager States
    CurrentEquippedPets = {},
    TeamMainPets = {},
    TeamBrontoPets = {},
    TeamHatchPets = {},
    TeamSellPets = {},
    ActiveTeam = "Main Team",
    IsFarmingRunning = false
}

-- Anti-Afk
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =========================================================================
-- [FUNGSI ASLI 100% FARMING & LOGIKA RESMI]
-- =========================================================================

local function GetMyFarm()
    if not Farms then return nil end
    for _, farm in ipairs(Farms:GetChildren()) do
        local owner = farm:FindFirstChild("Owner")
        if owner and owner.Value == LocalPlayer then
            return farm
        end
        if farm.Name:find(LocalPlayer.Name) then
            return farm
        end
    end
    return Farms:FindFirstChild("Farm1") or Farms:GetChildren()[1]
end

local function PlantSeed(seedName, targetCFrame)
    if not Plant_RE then return end
    pcall(function()
        Plant_RE:FireServer(seedName, targetCFrame)
    end)
end

local function HarvestCrop(cropModel)
    local prompt = cropModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    end
end

local function SellInventory()
    if not Sell_Inventory then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local oldPos = hrp and hrp.CFrame

    pcall(function()
        local npc = workspace:FindFirstChild("SellNPC") or workspace:FindFirstChild("NPCs"):FindFirstChild("Sell")
        if npc and hrp then
            local targetPos = npc:GetPivot()
            hrp.CFrame = targetPos + Vector3.new(0, 0, 3)
            task.wait(0.3)
        end
        Sell_Inventory:FireServer()
        task.wait(0.3)
        if oldPos and hrp then
            hrp.CFrame = oldPos
        end
    end)
end

local function BuySeeds(seedName, amount)
    if not BuySeedStock then return end
    pcall(function()
        BuySeedStock:FireServer(seedName, amount or 1)
    end)
end

local function GetEggModelFromBackpack(eggName)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if char then
        local inHand = char:FindFirstChild(eggName)
        if inHand then return inHand end
    end
    if bp then
        local inBp = bp:FindFirstChild(eggName)
        if inBp then return inBp end
    end
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item.Name:lower():find(eggName:lower()) then
                return item
            end
        end
    end
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(eggName:lower()) then
                return item
            end
        end
    end
    return nil
end

local function EquipEggTool(eggTool)
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid and eggTool.Parent ~= char then
        humanoid:EquipTool(eggTool)
        task.wait(0.2)
    end
end

local function PlaceEggAtLocation(eggName, targetCFrame, slotIndex)
    if PetEggService then
        pcall(function()
            PetEggService:FireServer("PlaceEgg", eggName, targetCFrame, slotIndex or 1)
        end)
    else
        local eggTool = GetEggModelFromBackpack(eggName)
        if eggTool then
            EquipEggTool(eggTool)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local prevCF = hrp.CFrame
                hrp.CFrame = targetCFrame + Vector3.new(0, 2, 0)
                task.wait(0.15)
                eggTool:Activate()
                task.wait(0.15)
                hrp.CFrame = prevCF
            end
        end
    end
end

-- THREAD FARM LOOP
task.spawn(function()
    while true do
        task.wait(0.2)
        if State.AutoPlant then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local targetCF
                if State.PlantMode == "UnderPlayer" then
                    targetCF = hrp.CFrame - Vector3.new(0, 2.5, 0)
                elseif State.PlantMode == "Custom" and State.CustomPlantPos then
                    targetCF = CFrame.new(State.CustomPlantPos)
                else
                    local myFarm = GetMyFarm()
                    if myFarm then
                        local plot = myFarm:FindFirstChild("Plots") or myFarm:FindFirstChild("Dirt") or myFarm
                        targetCF = plot:GetPivot() - Vector3.new(0, 1, 0)
                    else
                        targetCF = hrp.CFrame - Vector3.new(0, 2.5, 0)
                    end
                end
                PlantSeed(State.SelectedSeed, targetCF)
            end
        end
        if State.AutoHarvest then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local myFarm = GetMyFarm()
                local searchArea = myFarm or workspace
                for _, obj in ipairs(searchArea:GetDescendants()) do
                    if obj:IsA("Model") and (obj:FindFirstChild("Harvestable") or obj.Name:find("Crop") or obj.Name:find("Plant")) then
                        local pivot = obj:GetPivot()
                        local dist = (pivot.Position - hrp.Position).Magnitude
                        if dist <= State.HarvestRadius then
                            HarvestCrop(obj)
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

-- THREAD PLACE EGG LOOP
task.spawn(function()
    while true do
        task.wait(State.EggPlaceSpeed or 0.5)
        if State.AutoPlaceEgg then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local myFarm = GetMyFarm()
                local placeCF
                if myFarm then
                    local eggSlots = myFarm:FindFirstChild("EggSlots") or myFarm:FindFirstChild("Eggs")
                    if eggSlots then
                        local slot = eggSlots:FindFirstChild("Slot" .. tostring(State.SelectedEggSlot)) 
                                  or eggSlots:FindFirstChild(tostring(State.SelectedEggSlot))
                                  or eggSlots:GetChildren()[State.SelectedEggSlot]
                        if slot then
                            placeCF = slot:GetPivot()
                        end
                    end
                    if not placeCF then
                        placeCF = myFarm:GetPivot() + Vector3.new(0, 0.5, 0)
                    end
                else
                    placeCF = hrp.CFrame + hrp.CFrame.LookVector * 3 - Vector3.new(0, 2, 0)
                end
                PlaceEggAtLocation(State.SelectedEgg, placeCF, State.SelectedEggSlot)
            end
        end
    end
end)

-- =========================================================================
-- [C] INISIALISASI TAMPILAN WINDOW UTAMA
-- =========================================================================
local Window = ZyloLib:CreateWindow("ZyloHub", "v3.5 - Safe Edition", "Grow a Garden", 460, 480)
local Main = Window.MainFrame

-- 9 Tabs Resmi ZyloHub
local PageHome      = Window:CreateTab("Home", "🏠", 1)
local PageFarm      = Window:CreateTab("Farm", "🍃", 2, 480)
local PagePets      = Window:CreateTab("Pets", "🐾", 3, 750)
local PageUtility   = Window:CreateTab("Utility", "🔧", 4, 240)
local PageShop      = Window:CreateTab("Shop", "🛒", 5)
local PageConfig    = Window:CreateTab("Config", "⚙️", 6)
local PageEvents    = Window:CreateTab("Events", "🎪", 7)
local PageDev       = Window:CreateTab("Dev", "🛠️", 8)
local PageDiscord   = Window:CreateTab("Discord", "💬", 9)

-- =============================================================
-- [PETS PAGE CONTENT: AUTO PLACE EGG (PERSIS 100% KODE ASLI & LOCKED)]
-- =============================================================
local accPlaceEgg, bodyPlaceEgg = ZyloLib:CreateAccordion(PagePets, "Auto Place Egg", true, 200)

local RowEggTog = Instance.new("Frame", bodyPlaceEgg)
RowEggTog.Size = UDim2.new(1, -20, 0, 26)
RowEggTog.Position = UDim2.new(0, 10, 0, 6)
RowEggTog.BackgroundTransparency = 1

local TogEggLabel = Instance.new("TextLabel", RowEggTog)
TogEggLabel.Size = UDim2.new(0.65, 0, 1, 0)
TogEggLabel.BackgroundTransparency = 1
TogEggLabel.Text = "Enable Auto Place Egg"
TogEggLabel.TextColor3 = C.TEXT
TogEggLabel.Font = Enum.Font.GothamMedium
TogEggLabel.TextSize = 8.5
TogEggLabel.TextXAlignment = Enum.TextXAlignment.Left

local TogEggSwitch = ZyloLib:CreatePillSwitch(RowEggTog, State.AutoPlaceEgg, function(v)
    State.AutoPlaceEgg = v
end)
TogEggSwitch.Position = UDim2.new(1, -38, 0.5, -9)

local EggList = {
    "Common Egg", "Rare Egg", "Epic Egg", "Legendary Egg", "Mythic Egg",
    "Bug Egg", "Bee Egg", "Anti Bee Egg", "Oasis Egg", "Nightmare Egg",
    "Prismatic Egg", "Easter Egg", "Ghost Egg", "Dino Egg"
}
local EggDrop = ZyloLib:CreateDropdown(bodyPlaceEgg, "Pilih Jenis Telur", EggList, State.SelectedEgg, function(val)
    State.SelectedEgg = val
end)
EggDrop.Position = UDim2.new(0, 10, 0, 36)
EggDrop.Size = UDim2.new(1, -20, 0, 26)

local SlotList = {
    "Egg Slot 1", "Egg Slot 2", "Egg Slot 3", "Egg Slot 4",
    "Egg Slot 5", "Egg Slot 6", "Egg Slot 7", "Egg Slot 8"
}
local SlotDrop = ZyloLib:CreateDropdown(bodyPlaceEgg, "Pilih Slot Tanam Telur", SlotList, State.SelectedEggSlotName, function(val)
    State.SelectedEggSlotName = val
    local num = tonumber(val:match("%d+")) or 1
    State.SelectedEggSlot = num
end)
SlotDrop.Position = UDim2.new(0, 10, 0, 68)
SlotDrop.Size = UDim2.new(1, -20, 0, 26)

local RowEggSpd = Instance.new("Frame", bodyPlaceEgg)
RowEggSpd.Size = UDim2.new(1, -20, 0, 22)
RowEggSpd.Position = UDim2.new(0, 10, 0, 100)
RowEggSpd.BackgroundTransparency = 1

local SpdEggLabel = Instance.new("TextLabel", RowEggSpd)
SpdEggLabel.Size = UDim2.new(0.5, 0, 1, 0)
SpdEggLabel.BackgroundTransparency = 1
SpdEggLabel.Text = "Kecepatan Place Egg:"
SpdEggLabel.TextColor3 = C.TEXT_M
SpdEggLabel.Font = Enum.Font.Gotham
SpdEggLabel.TextSize = 8
SpdEggLabel.TextXAlignment = Enum.TextXAlignment.Left

local SpdEggVal = Instance.new("TextLabel", RowEggSpd)
SpdEggVal.Size = UDim2.new(0.5, 0, 1, 0)
SpdEggVal.Position = UDim2.new(0.5, 0, 0, 0)
SpdEggVal.BackgroundTransparency = 1
SpdEggVal.Text = string.format("%.1f s", State.EggPlaceSpeed)
SpdEggVal.TextColor3 = C.PURPLE_L
SpdEggVal.Font = Enum.Font.GothamBold
SpdEggVal.TextSize = 8
SpdEggVal.TextXAlignment = Enum.TextXAlignment.Right

local EggSpdSlider = Instance.new("Frame", bodyPlaceEgg)
EggSpdSlider.Size = UDim2.new(1, -20, 0, 5)
EggSpdSlider.Position = UDim2.new(0, 10, 0, 126)
EggSpdSlider.BackgroundColor3 = C.CARD_2
EggSpdSlider.BorderSizePixel = 0
Instance.new("UICorner", EggSpdSlider).CornerRadius = UDim.new(1, 0)

local EggSpdFill = Instance.new("Frame", EggSpdSlider)
local initEggRatio = math.clamp((State.EggPlaceSpeed - 0.1) / (3.0 - 0.1), 0, 1)
EggSpdFill.Size = UDim2.new(initEggRatio, 0, 1, 0)
EggSpdFill.BackgroundColor3 = C.PURPLE
EggSpdFill.BorderSizePixel = 0
Instance.new("UICorner", EggSpdFill).CornerRadius = UDim.new(1, 0)

local draggingEggSlider = false
EggSpdSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingEggSlider = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingEggSlider = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingEggSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local absPos = EggSpdSlider.AbsolutePosition.X
        local absSize = EggSpdSlider.AbsoluteSize.X
        local mouseX = input.Position.X
        local ratio = math.clamp((mouseX - absPos) / absSize, 0, 1)
        EggSpdFill.Size = UDim2.new(ratio, 0, 1, 0)
        local val = 0.1 + (ratio * (3.0 - 0.1))
        State.EggPlaceSpeed = math.floor(val * 10) / 10
        SpdEggVal.Text = string.format("%.1f s", State.EggPlaceSpeed)
    end
end)

local InstantEggBtn = Instance.new("TextButton", bodyPlaceEgg)
InstantEggBtn.Size = UDim2.new(1, -20, 0, 26)
InstantEggBtn.Position = UDim2.new(0, 10, 0, 140)
InstantEggBtn.BackgroundColor3 = C.CARD_2
InstantEggBtn.Text = "⚡ Place Telur Sekali Sekarang (Manual)"
InstantEggBtn.TextColor3 = C.TEXT
InstantEggBtn.Font = Enum.Font.GothamMedium
InstantEggBtn.TextSize = 8.5
Instance.new("UICorner", InstantEggBtn).CornerRadius = UDim.new(0, 6)
local IeStroke = Instance.new("UIStroke", InstantEggBtn)
IeStroke.Color = C.PURPLE

InstantEggBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local myFarm = GetMyFarm()
        local placeCF = myFarm and (myFarm:GetPivot() + Vector3.new(0, 0.5, 0)) or (hrp.CFrame + Vector3.new(0, -2, 0))
        PlaceEggAtLocation(State.SelectedEgg, placeCF, State.SelectedEggSlot)
        ZyloLib:Notify("Egg Placed", "Telur " .. State.SelectedEgg .. " ditaruh di Slot " .. tostring(State.SelectedEggSlot), 2)
    end
end)

-- =============================================================
-- [PEMANGGILAN MODUL 1: PET HATCH & TEAM MANAGER]
-- =============================================================
local PetHatchModule = nil
local okHatch, errHatch = pcall(function()
    local raw = game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/PetHatchModule.lua")
    local fn = loadstring(raw)
    if fn then
        PetHatchModule = fn()(PagePets, State, ZyloLib, Main)
    end
end)
if not okHatch then
    warn("[ZyloHub] PetHatchModule note:", errHatch)
end

-- =============================================================
-- [ACCORDION PET LAINNYA]
-- =============================================================
local accMutasi, bodyMutasi = ZyloLib:CreateAccordion(PagePets, "Auto Mutasi", false, 85)
local accEle, bodyEle = ZyloLib:CreateAccordion(PagePets, "Auto Elephant", false, 85)

-- =============================================================
-- [FARM PAGE CONTENT - 100% PERSIS KODE ASLI & LOCKED]
-- =============================================================
local FarmCard1 = Instance.new("Frame", PageFarm)
FarmCard1.Size = UDim2.new(1, 0, 0, 300)
FarmCard1.BackgroundColor3 = C.CARD
Instance.new("UICorner", FarmCard1).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard1).Color = C.STROKE

local FcTitle = Instance.new("TextLabel", FarmCard1)
FcTitle.Position = UDim2.new(0, 12, 0, 10)
FcTitle.Size = UDim2.new(1, -24, 0, 14)
FcTitle.BackgroundTransparency = 1
FcTitle.Text = "🌱  AUTO PLANT & HARVEST ENGINE"
FcTitle.TextColor3 = C.PURPLE_L
FcTitle.Font = Enum.Font.GothamBold
FcTitle.TextSize = 9.5
FcTitle.TextXAlignment = Enum.TextXAlignment.Left

local PlantRow = Instance.new("Frame", FarmCard1)
PlantRow.Position = UDim2.new(0, 12, 0, 30)
PlantRow.Size = UDim2.new(1, -24, 0, 32)
PlantRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", PlantRow).CornerRadius = UDim.new(0, 6)

local PlLabel = Instance.new("TextLabel", PlantRow)
PlLabel.Position = UDim2.new(0, 10, 0, 0)
PlLabel.Size = UDim2.new(0.6, 0, 1, 0)
PlLabel.BackgroundTransparency = 1
PlLabel.Text = "Enable Auto Plant"
PlLabel.TextColor3 = C.TEXT
PlLabel.Font = Enum.Font.GothamMedium
PlLabel.TextSize = 9
PlLabel.TextXAlignment = Enum.TextXAlignment.Left

local PlSwitch = ZyloLib:CreatePillSwitch(PlantRow, State.AutoPlant, function(v) State.AutoPlant = v end)
PlSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local SeedsList = {
    "Carrot", "Tomato", "Wheat", "Potato", "Corn",
    "Pumpkin", "Watermelon", "Strawberry", "Grape", "Blueberry"
}
local SeedDrop = ZyloLib:CreateDropdown(FarmCard1, "Pilih Jenis Bibit", SeedsList, State.SelectedSeed, function(val)
    State.SelectedSeed = val
end)
SeedDrop.Position = UDim2.new(0, 12, 0, 68)
SeedDrop.Size = UDim2.new(1, -24, 0, 30)

local ModeList = {"UnderPlayer", "FarmPlot", "Custom"}
local ModeDrop = ZyloLib:CreateDropdown(FarmCard1, "Mode Area Tanam", ModeList, State.PlantMode, function(val)
    State.PlantMode = val
end)
ModeDrop.Position = UDim2.new(0, 12, 0, 104)
ModeDrop.Size = UDim2.new(1, -24, 0, 30)

local SetCustomPosBtn = Instance.new("TextButton", FarmCard1)
SetCustomPosBtn.Position = UDim2.new(0, 12, 0, 140)
SetCustomPosBtn.Size = UDim2.new(1, -24, 0, 26)
SetCustomPosBtn.BackgroundColor3 = C.CARD_2
SetCustomPosBtn.Text = "📍 Simpan Posisi Berdiri Saat Ini sebagai Titik Tanam"
SetCustomPosBtn.TextColor3 = C.TEXT_M
SetCustomPosBtn.Font = Enum.Font.Gotham
SetCustomPosBtn.TextSize = 8
Instance.new("UICorner", SetCustomPosBtn).CornerRadius = UDim.new(0, 5)

SetCustomPosBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        State.CustomPlantPos = hrp.Position - Vector3.new(0, 2.5, 0)
        SetCustomPosBtn.Text = "✅ Posisi Tersimpan: " .. string.format("%.1f, %.1f, %.1f", State.CustomPlantPos.X, State.CustomPlantPos.Y, State.CustomPlantPos.Z)
        SetCustomPosBtn.TextColor3 = C.GREEN
    end
end)

local HarvestRow = Instance.new("Frame", FarmCard1)
HarvestRow.Position = UDim2.new(0, 12, 0, 172)
HarvestRow.Size = UDim2.new(1, -24, 0, 32)
HarvestRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", HarvestRow).CornerRadius = UDim.new(0, 6)

local HvLabel = Instance.new("TextLabel", HarvestRow)
HvLabel.Position = UDim2.new(0, 10, 0, 0)
HvLabel.Size = UDim2.new(0.6, 0, 1, 0)
HvLabel.BackgroundTransparency = 1
HvLabel.Text = "Enable Auto Harvest (Panen)"
HvLabel.TextColor3 = C.TEXT
HvLabel.Font = Enum.Font.GothamMedium
HvLabel.TextSize = 9
HvLabel.TextXAlignment = Enum.TextXAlignment.Left

local HvSwitch = ZyloLib:CreatePillSwitch(HarvestRow, State.AutoHarvest, function(v) State.AutoHarvest = v end)
HvSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local RadHeader = Instance.new("Frame", FarmCard1)
RadHeader.Position = UDim2.new(0, 12, 0, 210)
RadHeader.Size = UDim2.new(1, -24, 0, 14)
RadHeader.BackgroundTransparency = 1

local RadTitle = Instance.new("TextLabel", RadHeader)
RadTitle.Size = UDim2.new(0.5, 0, 1, 0)
RadTitle.BackgroundTransparency = 1
RadTitle.Text = "Radius Jarak Panen:"
RadTitle.TextColor3 = C.TEXT_M
RadTitle.Font = Enum.Font.Gotham
RadTitle.TextSize = 8
RadTitle.TextXAlignment = Enum.TextXAlignment.Left

local RadVal = Instance.new("TextLabel", RadHeader)
RadVal.Position = UDim2.new(0.5, 0, 0, 0)
RadVal.Size = UDim2.new(0.5, 0, 1, 0)
RadVal.BackgroundTransparency = 1
RadVal.Text = tostring(State.HarvestRadius) .. " Studs"
RadVal.TextColor3 = C.PURPLE_L
RadVal.Font = Enum.Font.GothamBold
RadVal.TextSize = 8
RadVal.TextXAlignment = Enum.TextXAlignment.Right

local RadSlider = Instance.new("Frame", FarmCard1)
RadSlider.Position = UDim2.new(0, 12, 0, 230)
RadSlider.Size = UDim2.new(1, -24, 0, 6)
RadSlider.BackgroundColor3 = C.CARD_2
RadSlider.BorderSizePixel = 0
Instance.new("UICorner", RadSlider).CornerRadius = UDim.new(1, 0)

local RadFill = Instance.new("Frame", RadSlider)
local initRatio = math.clamp((State.HarvestRadius - 10) / (200 - 10), 0, 1)
RadFill.Size = UDim2.new(initRatio, 0, 1, 0)
RadFill.BackgroundColor3 = C.PURPLE
RadFill.BorderSizePixel = 0
Instance.new("UICorner", RadFill).CornerRadius = UDim.new(1, 0)

local draggingRad = false
RadSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingRad = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingRad = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingRad and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local absPos = RadSlider.AbsolutePosition.X
        local absSize = RadSlider.AbsoluteSize.X
        local mouseX = input.Position.X
        local ratio = math.clamp((mouseX - absPos) / absSize, 0, 1)
        RadFill.Size = UDim2.new(ratio, 0, 1, 0)
        local val = math.floor(10 + (ratio * (200 - 10)))
        State.HarvestRadius = val
        RadVal.Text = tostring(val) .. " Studs"
    end
end)

local FarmCard2 = Instance.new("Frame", PageFarm)
FarmCard2.Position = UDim2.new(0, 0, 0, 310)
FarmCard2.Size = UDim2.new(1, 0, 0, 120)
FarmCard2.BackgroundColor3 = C.CARD
Instance.new("UICorner", FarmCard2).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard2).Color = C.STROKE

local Fc2Title = Instance.new("TextLabel", FarmCard2)
Fc2Title.Position = UDim2.new(0, 12, 0, 10)
Fc2Title.Size = UDim2.new(1, -24, 0, 14)
Fc2Title.BackgroundTransparency = 1
Fc2Title.Text = "💰  AUTO SELL INVENTORY"
Fc2Title.TextColor3 = C.PURPLE_L
Fc2Title.Font = Enum.Font.GothamBold
Fc2Title.TextSize = 9.5
Fc2Title.TextXAlignment = Enum.TextXAlignment.Left

local SellRow = Instance.new("Frame", FarmCard2)
SellRow.Position = UDim2.new(0, 12, 0, 32)
SellRow.Size = UDim2.new(1, -24, 0, 32)
SellRow.BackgroundColor3 = C.CARD_2
Instance.new("UICorner", SellRow).CornerRadius = UDim.new(0, 6)

local SrLabel = Instance.new("TextLabel", SellRow)
SrLabel.Position = UDim2.new(0, 10, 0, 0)
SrLabel.Size = UDim2.new(0.6, 0, 1, 0)
SrLabel.BackgroundTransparency = 1
SrLabel.Text = "Auto Sell Saat Inventory Penuh"
SrLabel.TextColor3 = C.TEXT
SrLabel.Font = Enum.Font.GothamMedium
SrLabel.TextSize = 9
SrLabel.TextXAlignment = Enum.TextXAlignment.Left

local SrSwitch = ZyloLib:CreatePillSwitch(SellRow, State.AutoSell, function(v) State.AutoSell = v end)
SrSwitch.Position = UDim2.new(1, -40, 0.5, -10)

local ManualSellBtn = Instance.new("TextButton", FarmCard2)
ManualSellBtn.Position = UDim2.new(0, 12, 0, 74)
ManualSellBtn.Size = UDim2.new(1, -24, 0, 34)
ManualSellBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 54)
ManualSellBtn.Text = "⚡ Jual Semua Hasil Panen Sekarang (Teleport NPC & Balik)"
ManualSellBtn.TextColor3 = C.CYAN
ManualSellBtn.Font = Enum.Font.GothamBold
ManualSellBtn.TextSize = 10
Instance.new("UICorner", ManualSellBtn).CornerRadius = UDim.new(0, 6)
local MsStroke = Instance.new("UIStroke", ManualSellBtn)
MsStroke.Color = Color3.fromRGB(0, 180, 200)

ManualSellBtn.MouseButton1Click:Connect(function()
    State.AutoSell = true
    SellInventory()
end)

-- Default Active: Tab Pets
Window:SelectTab("Pets")

print("[ZyloHub v3.5 - Modular] UI BERHASIL MUNCUL 100%!")
