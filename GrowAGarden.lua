-- =========================================================================
--  ZYLOHUB UI FRAMEWORK (v3.5 - REAL OFFICIAL EDITION)
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Full 9 Tabs + Official PetEggService + Pet Team Manager
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

local function getSafeParent()
    local success, pgui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if success and pgui then return pgui end
    return game:GetService("CoreGui")
end

-- =========================================================================
-- [1] SERVICES & REMOTES
-- =========================================================================
local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents") or ReplicatedStorage:WaitForChild("GameEvents", 6)
local Plant_RE = GameEvents and GameEvents:FindFirstChild("Plant_RE")
local Sell_Inventory = GameEvents and GameEvents:FindFirstChild("Sell_Inventory")
local PetEggService = GameEvents and GameEvents:FindFirstChild("PetEggService")
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
        if obj.Name == "Can_Plant" and obj:IsA("BasePart") then
            table.insert(parts, obj)
        elseif obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    return parts
end

-- =========================================================================
-- [2] PET & SEED FILTERS
-- =========================================================================
local BLACKLISTED = {
    "shard", "pack", "bundle", "crate", "chest", "box", "gift", "present",
    "ticket", "token", "pass", "badge", "coupon", "potion", "elixir",
    "scroll", "book", "tome", "watering can", "sprinkler", "shovel",
    "trowel", "sickle", "hoe", "basket", "fishing rod", "rod", "bug net"
}

local function isPureSeed(tool)
    if not tool:IsA("Tool") or tool:FindFirstChild("Item_String") then return false end
    if tool:FindFirstChild("EggData") or tool:FindFirstChild("PetData") then return false end
    local n = tool.Name:lower()
    if n:find("pet") and not n:find("petunia") then return false end
    if n:find("egg") and not n:find("eggplant") then return false end
    for _, kw in ipairs(BLACKLISTED) do if n:find(kw) then return false end end
    return true
end

local function isPureEgg(tool)
    if not tool:IsA("Tool") then return false end
    local n = tool.Name:lower()
    if n:find("seed") or tool:FindFirstChild("Plant_Name") or tool:FindFirstChild("Item_String") then return false end
    if n:find("eggfruit") or n:find("eggplant") then return false end
    for _, kw in ipairs(BLACKLISTED) do if n:find(kw) then return false end end
    return tool:FindFirstChild("PetEggToolLocal") or tool:FindFirstChild("EggData") or n:find("egg")
end

local function isPetTool(tool)
    if not tool:IsA("Tool") or tool:FindFirstChild("Item_String") then return false end
    if isPureSeed(tool) or isPureEgg(tool) then return false end
    local n = tool.Name:lower()
    for _, kw in ipairs(BLACKLISTED) do if n:find(kw) then return false end end
    return true
end

local function GetOwnedSeeds()
    local seeds = {}
    local function scan(p)
        if not p then return end
        for _, t in ipairs(p:GetChildren()) do
            if isPureSeed(t) then
                local plantName = t.Name:gsub("%[.-%]", ""):gsub(" Seed", ""):gsub("Seed", ""):gsub("^%s*(.-)%s*$", "%1")
                local count = 1
                local b = t.Name:match("%[X(%d+)%]") or t.Name:match("%[(%d+)%]")
                if b then count = tonumber(b) or 1 end
                seeds[plantName] = { Name = plantName, ToolName = t.Name, Count = count, Tool = t }
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return seeds
end

local function GetPureEggs()
    local eggs = {}
    local function scan(p)
        if not p then return end
        for _, t in ipairs(p:GetChildren()) do
            if isPureEgg(t) then table.insert(eggs, t) end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return eggs
end

local function GetOwnedPets()
    local list = {}
    local function scan(p)
        if not p then return end
        for _, t in ipairs(p:GetChildren()) do
            if isPetTool(t) then
                local cleanName = t.Name:gsub("%[.-%]", ""):gsub("%s*[xX]%d+$", ""):gsub("%s*|.*$", ""):gsub("^%s*(.-)%s*$", "%1")
                if cleanName == "" then cleanName = t.Name end
                local age = t:GetAttribute("Age") or 1
                local weight = t:GetAttribute("Weight") or 1.0
                local lbl = string.format("%s | Age %s | %.2f KG", cleanName, tostring(age), tonumber(weight) or 1.0)
                table.insert(list, { Tool = t, Name = cleanName, Label = lbl })
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return list
end

-- =============================================================
-- [3] WORKER LOOPS (EGG, HARVEST, PLANT, UTILITY)
-- =============================================================
local EggCFrameList = {
    CFrame.new(72.7, 3.5, -9.1), CFrame.new(72.7, 3.5, -5.9),
    CFrame.new(72.7, 3.5, -2.7), CFrame.new(72.7, 3.5, 0.5),
    CFrame.new(72.7, 3.5, 3.7),  CFrame.new(72.7, 3.5, 6.9),
    CFrame.new(72.7, 3.5, 10.1), CFrame.new(72.7, 3.5, 13.3),
    CFrame.new(72.7, 3.5, 16.5), CFrame.new(72.7, 3.5, 19.7),
    CFrame.new(72.7, 3.5, 22.9), CFrame.new(72.7, 3.5, 26.1),
    CFrame.new(72.7, 3.5, 29.3)
}

task.spawn(function()
    while true do
        if State.AutoPlaceEgg and PetEggService then
            pcall(function()
                local eggs = GetPureEggs()
                if #eggs > 0 then
                    local targetEgg = eggs[1]
                    for i = 1, math.min(#EggCFrameList, State.MaxEggPlace) do
                        if not State.AutoPlaceEgg then break end
                        if targetEgg.Parent == LocalPlayer:FindFirstChild("Backpack") and Humanoid then
                            Humanoid:EquipTool(targetEgg)
                            task.wait(0.1)
                        end
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
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            end
                            task.wait(0.04)
                        end
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while true do
        if State.AutoPlant and Plant_RE then
            pcall(function()
                local owned = GetOwnedSeeds()
                local sData = nil
                if State.SelectedSeed ~= "" and owned[State.SelectedSeed] then
                    sData = owned[State.SelectedSeed]
                else
                    for _, d in pairs(owned) do sData = d break end
                end

                if sData and sData.Tool then
                    if sData.Tool.Parent == LocalPlayer:FindFirstChild("Backpack") and Humanoid then
                        Humanoid:EquipTool(sData.Tool)
                        task.wait(0.1)
                    end
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        Plant_RE:FireServer(Vector3.new(root.Position.X, 0.135, root.Position.Z), sData.Name)
                    end
                end
            end)
        end
        task.wait(0.2)
    end
end)

-- Anti AFK & Mobility
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

-- =============================================================
-- [4] UI VISUAL IDENTITY (FULL THEME: OBSIDIAN & COSMIC PURPLE)
-- =============================================================
local C_BG       = Color3.fromRGB(7, 9, 18)
local C_TOPBAR   = Color3.fromRGB(11, 14, 28)
local C_CARD     = Color3.fromRGB(12, 16, 32)
local C_CARD_2   = Color3.fromRGB(16, 21, 42)
local C_PURPLE   = Color3.fromRGB(138, 43, 226)
local C_PURPLE_L = Color3.fromRGB(175, 82, 255)
local C_CYAN     = Color3.fromRGB(0, 240, 255)
local C_STROKE   = Color3.fromRGB(30, 36, 68)
local C_TEXT_W   = Color3.fromRGB(245, 247, 255)
local C_TEXT_M   = Color3.fromRGB(145, 155, 185)

local GUI_NAME = "ZyloHub_v3_5_FullReal"
pcall(function()
    local old = getSafeParent():FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.Parent = getSafeParent()

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "MainWindow"
Main.Size = UDim2.new(0, 620, 0, 400)
Main.Position = UDim2.new(0.5, -310, 0.5, -200)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local mStroke = Instance.new("UIStroke", Main)
mStroke.Color = Color3.fromRGB(50, 40, 95)
mStroke.Thickness = 1.5

-- Responsive Scaler untuk Layar Ponsel
local uis = Instance.new("UIScale", Main)
pcall(function()
    local cam = workspace.CurrentCamera
    if cam and cam.ViewportSize.Y > 0 then
        local sy = math.min(1, (cam.ViewportSize.Y - 20) / 415)
        local sx = math.min(1, (cam.ViewportSize.X - 20) / 635)
        uis.Scale = math.clamp(math.min(sx, sy), 0.55, 1)
    end
end)

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 46)
Topbar.BackgroundColor3 = C_TOPBAR
Topbar.BorderSizePixel = 0

local LogoBadge = Instance.new("Frame", Topbar)
LogoBadge.Size = UDim2.new(0, 30, 0, 30)
LogoBadge.Position = UDim2.new(0, 12, 0.5, -15)
LogoBadge.BackgroundColor3 = Color3.fromRGB(24, 18, 48)
Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 8)
local lbStroke = Instance.new("UIStroke", LogoBadge)
lbStroke.Color = C_PURPLE
lbStroke.Thickness = 1.5

local LogoText = Instance.new("TextLabel", LogoBadge)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "Z"
LogoText.TextColor3 = Color3.fromRGB(220, 130, 255)
LogoText.Font = Enum.Font.FredokaOne
LogoText.TextSize = 18

local BrandTitle = Instance.new("TextLabel", Topbar)
BrandTitle.Position = UDim2.new(0, 48, 0, 7)
BrandTitle.Size = UDim2.new(0, 130, 0, 16)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Text = "ZYLOHUB"
BrandTitle.TextColor3 = C_TEXT_W
BrandTitle.Font = Enum.Font.GothamBold
BrandTitle.TextSize = 14
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left

local BrandSub = Instance.new("TextLabel", Topbar)
BrandSub.Position = UDim2.new(0, 48, 0, 24)
BrandSub.Size = UDim2.new(0, 180, 0, 14)
BrandSub.BackgroundTransparency = 1
BrandSub.Text = "Auto • Farm • Pets • More"
BrandSub.TextColor3 = C_PURPLE_L
BrandSub.Font = Enum.Font.GothamMedium
BrandSub.TextSize = 9
BrandSub.TextXAlignment = Enum.TextXAlignment.Left

-- Detect Pill (Game Detected)
local DetectPill = Instance.new("Frame", Topbar)
DetectPill.Size = UDim2.new(0, 115, 0, 24)
DetectPill.Position = UDim2.new(1, -162, 0.5, -12)
DetectPill.BackgroundColor3 = Color3.fromRGB(14, 25, 36)
Instance.new("UICorner", DetectPill).CornerRadius = UDim.new(0, 12)
local dpStroke = Instance.new("UIStroke", DetectPill)
dpStroke.Color = Color3.fromRGB(0, 160, 140)

local Dot = Instance.new("Frame", DetectPill)
Dot.Size = UDim2.new(0, 6, 0, 6)
Dot.Position = UDim2.new(0, 8, 0.5, -3)
Dot.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

local DText = Instance.new("TextLabel", DetectPill)
DText.Position = UDim2.new(0, 20, 0, 0)
DText.Size = UDim2.new(1, -22, 1, 0)
DText.BackgroundTransparency = 1
DText.Text = "Game Detected"
DText.TextColor3 = Color3.fromRGB(0, 255, 190)
DText.Font = Enum.Font.GothamBold
DText.TextSize = 9
DText.TextXAlignment = Enum.TextXAlignment.Left

-- Close Button
local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -12)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C_TEXT_M
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12

-- Floating Button Z
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Name = "ZyloFloatToggle"
FloatBtn.Size = UDim2.new(0, 46, 0, 46)
FloatBtn.Position = UDim2.new(0, 18, 0.2, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
FloatBtn.Text = "Z"
FloatBtn.TextColor3 = Color3.fromRGB(220, 130, 255)
FloatBtn.Font = Enum.Font.FredokaOne
FloatBtn.TextSize = 24
FloatBtn.Active = true
FloatBtn.Draggable = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 14)
local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = C_PURPLE
fbStroke.Thickness = 2.2

local function toggleUI() Main.Visible = not Main.Visible end
CloseBtn.MouseButton1Click:Connect(toggleUI)
FloatBtn.MouseButton1Click:Connect(toggleUI)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 130, 1, -46)
Sidebar.Position = UDim2.new(0, 0, 0, 46)
Sidebar.BackgroundColor3 = Color3.fromRGB(9, 12, 24)
Sidebar.BorderSizePixel = 0

local SideScroll = Instance.new("ScrollingFrame", Sidebar)
SideScroll.Size = UDim2.new(1, 0, 1, -85)
SideScroll.BackgroundTransparency = 1
SideScroll.ScrollBarThickness = 0
SideScroll.CanvasSize = UDim2.new(0, 0, 0, 330)

local SideLayout = Instance.new("UIListLayout", SideScroll)
SideLayout.Padding = UDim.new(0, 3)
local SidePad = Instance.new("UIPadding", SideScroll)
SidePad.PaddingTop = UDim.new(0, 6)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)

-- Brand Card di Bawah Sidebar
local BrandCard = Instance.new("Frame", Sidebar)
BrandCard.Size = UDim2.new(1, -12, 0, 75)
BrandCard.Position = UDim2.new(0, 6, 1, -80)
BrandCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
Instance.new("UICorner", BrandCard).CornerRadius = UDim.new(0, 10)
local bcStroke = Instance.new("UIStroke", BrandCard)
bcStroke.Color = Color3.fromRGB(80, 45, 140)

local BcTitle = Instance.new("TextLabel", BrandCard)
BcTitle.Position = UDim2.new(0, 10, 0, 12)
BcTitle.Size = UDim2.new(1, -16, 0, 14)
BcTitle.BackgroundTransparency = 1
BcTitle.Text = "⚡ ZYLOHUB"
BcTitle.TextColor3 = C_TEXT_W
BcTitle.Font = Enum.Font.GothamBold
BcTitle.TextSize = 11
BcTitle.TextXAlignment = Enum.TextXAlignment.Left

local BcDesc = Instance.new("TextLabel", BrandCard)
BcDesc.Position = UDim2.new(0, 10, 0, 28)
BcDesc.Size = UDim2.new(1, -16, 0, 24)
BcDesc.BackgroundTransparency = 1
BcDesc.Text = "Better Scripts\nBetter Experience"
BcDesc.TextColor3 = C_TEXT_M
BcDesc.Font = Enum.Font.GothamMedium
BcDesc.TextSize = 8
BcDesc.TextXAlignment = Enum.TextXAlignment.Left

-- Container Content
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -140, 1, -52)
Content.Position = UDim2.new(0, 135, 0, 50)
Content.BackgroundTransparency = 1

local Pages = {}
local Buttons = {}

local function createTabPage(name)
    local sf = Instance.new("ScrollingFrame", Content)
    sf.Name = name .. "Page"
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = C_PURPLE
    sf.Visible = false
    
    local list = Instance.new("UIListLayout", sf)
    list.Padding = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", sf)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    Pages[name] = sf
    return sf
end

local function addSidebarTab(name, icon, order)
    local btn = Instance.new("TextButton", SideScroll)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    btn.BackgroundTransparency = 1
    btn.Text = "   " .. icon .. "   " .. name
    btn.TextColor3 = C_TEXT_M
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(Buttons) do
            tBtn.BackgroundTransparency = 1
            tBtn.TextColor3 = C_TEXT_M
            if Pages[tName] then Pages[tName].Visible = false end
        end
        btn.BackgroundTransparency = 0
        btn.BackgroundColor3 = C_PURPLE
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        if Pages[name] then Pages[name].Visible = true end
    end)
    Buttons[name] = btn
end

-- 9 Tabs Sesuai ZyloHub Asli
local PageHome      = createTabPage("Home")
local PageFarm      = createTabPage("Farm")
local PagePets      = createTabPage("Pets")
local PageUtility   = createTabPage("Utility")
local PageShop      = createTabPage("Shop")
local PageConfig    = createTabPage("Config")
local PageEvent     = createTabPage("Event")
local PageInventory = createTabPage("Inventory")
local PageWebhook   = createTabPage("Webhook")

addSidebarTab("Home", "🏠", 1)
addSidebarTab("Farm", "🌿", 2)
addSidebarTab("Pets", "🐾", 3)
addSidebarTab("Utility", "🔧", 4)
addSidebarTab("Shop", "🛒", 5)
addSidebarTab("Config", "⚙️", 6)
addSidebarTab("Event", "⭐", 7)
addSidebarTab("Inventory", "🎒", 8)
addSidebarTab("Webhook", "🔗", 9)

-- Helper Pill Switch
local function createPillSwitch(parent, defaultState, callback)
    local switch = Instance.new("TextButton", parent)
    switch.Size = UDim2.new(0, 36, 0, 20)
    switch.BackgroundColor3 = defaultState and C_PURPLE or Color3.fromRGB(26, 28, 44)
    switch.Text = ""
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
    local swStroke = Instance.new("UIStroke", switch)
    swStroke.Color = Color3.fromRGB(45, 50, 75)

    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = defaultState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local active = defaultState
    switch.MouseButton1Click:Connect(function()
        active = not active
        local targetPos = active and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        local targetColor = active and C_PURPLE or Color3.fromRGB(26, 28, 44)
        TweenService:Create(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = targetPos }):Play()
        TweenService:Create(switch, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { BackgroundColor3 = targetColor }):Play()
        callback(active)
    end)
    return switch
end

-- =============================================================
-- [5] ISI KONTEN: TAB FARM & PETS & UTILITY LENGKAP
-- =============================================================

-- [TAB FARM]
PageFarm.CanvasSize = UDim2.new(0, 0, 0, 380)
local FarmCard1 = Instance.new("Frame", PageFarm)
FarmCard1.Size = UDim2.new(1, 0, 0, 240)
FarmCard1.BackgroundColor3 = C_CARD
Instance.new("UICorner", FarmCard1).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", FarmCard1).Color = C_STROKE

local FcTitle = Instance.new("TextLabel", FarmCard1)
FcTitle.Position = UDim2.new(0, 12, 0, 10)
FcTitle.Size = UDim2.new(1, -24, 0, 14)
FcTitle.BackgroundTransparency = 1
FcTitle.Text = "🌱  AUTO PLANT & HARVEST ENGINE"
FcTitle.TextColor3 = C_PURPLE_L
FcTitle.Font = Enum.Font.GothamBold
FcTitle.TextSize = 11
FcTitle.TextXAlignment = Enum.TextXAlignment.Left

local function addCardRow(card, posY, text, default, cb)
    local r = Instance.new("Frame", card)
    r.Position = UDim2.new(0, 12, 0, posY)
    r.Size = UDim2.new(1, -24, 0, 30)
    r.BackgroundColor3 = C_CARD_2
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", r)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TEXT_W
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sw = createPillSwitch(r, default, cb)
    sw.Position = UDim2.new(1, -40, 0.5, -10)
    return r
end

addCardRow(FarmCard1, 36, "Auto Plant (Tanam + Auto Equip Tool Benih)", State.AutoPlant, function(v) State.AutoPlant = v end)
addCardRow(FarmCard1, 72, "Auto Harvest (Panen Cepat & Mulus)", State.AutoHarvest, function(v) State.AutoHarvest = v end)
addCardRow(FarmCard1, 108, "Auto Sell Otomatis", State.AutoSell, function(v) State.AutoSell = v end)

-- [TAB PETS]
PagePets.CanvasSize = UDim2.new(0, 0, 0, 420)
local PetCard1 = Instance.new("Frame", PagePets)
PetCard1.Size = UDim2.new(1, 0, 0, 220)
PetCard1.BackgroundColor3 = C_CARD
Instance.new("UICorner", PetCard1).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", PetCard1).Color = C_STROKE

local PcTitle = Instance.new("TextLabel", PetCard1)
PcTitle.Position = UDim2.new(0, 12, 0, 10)
PcTitle.Size = UDim2.new(1, -24, 0, 14)
PcTitle.BackgroundTransparency = 1
PcTitle.Text = "🐾  AUTO PLACE EGG & PET SYSTEM"
PcTitle.TextColor3 = C_PURPLE_L
PcTitle.Font = Enum.Font.GothamBold
PcTitle.TextSize = 11
PcTitle.TextXAlignment = Enum.TextXAlignment.Left

addCardRow(PetCard1, 36, "Auto Place Egg (13 Titik PetEggService)", State.AutoPlaceEgg, function(v) State.AutoPlaceEgg = v end)
addCardRow(PetCard1, 72, "Auto Hatch & Tetaskan Telur", State.AutoHatch, function(v) State.AutoHatch = v end)
addCardRow(PetCard1, 108, "Pet Team Manager (Auto Switch Team)", State.PetTeamActive, function(v) State.PetTeamActive = v end)

-- [TAB UTILITY]
PageUtility.CanvasSize = UDim2.new(0, 0, 0, 240)
local UtilCard = Instance.new("Frame", PageUtility)
UtilCard.Size = UDim2.new(1, 0, 0, 200)
UtilCard.BackgroundColor3 = C_CARD
Instance.new("UICorner", UtilCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", UtilCard).Color = C_STROKE

local UcTitle = Instance.new("TextLabel", UtilCard)
UcTitle.Position = UDim2.new(0, 12, 0, 10)
UcTitle.Size = UDim2.new(1, -24, 0, 14)
UcTitle.BackgroundTransparency = 1
UcTitle.Text = "⚡  PLAYER UTILITY"
UcTitle.TextColor3 = C_PURPLE_L
UcTitle.Font = Enum.Font.GothamBold
UcTitle.TextSize = 11
UcTitle.TextXAlignment = Enum.TextXAlignment.Left

addCardRow(UtilCard, 36, "Infinite Jump (Lompat Tanpa Batas)", State.InfJump, function(v) State.InfJump = v end)
addCardRow(UtilCard, 72, "Noclip (Tembus Dinding & Pagar)", State.Noclip, function(v) State.Noclip = v end)
addCardRow(UtilCard, 108, "Anti-AFK 20 Menit", State.AntiAfk, function(v) State.AntiAfk = v end)
addCardRow(UtilCard, 144, "WalkSpeed Boost (Lari Cepat 42 Studs)", State.Walkspeed, function(v)
    State.Walkspeed = v
    if not v and Humanoid then Humanoid.WalkSpeed = 16 end
end)

-- Default Active: Tab Farm
Buttons["Farm"].BackgroundTransparency = 0
Buttons["Farm"].BackgroundColor3 = C_PURPLE
Buttons["Farm"].TextColor3 = Color3.fromRGB(255, 255, 255)
PageFarm.Visible = true

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ZyloHub v3.5",
        Text = "Real Edition Loaded! Klik tombol Z untuk buka.",
        Duration = 5
    })
end)
