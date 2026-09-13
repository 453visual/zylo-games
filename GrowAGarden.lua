-- =========================================================================
--  ZYLOHUB UI FRAMEWORK (v3.5 - OFFICIAL PetEggService EDITION)
--  Theme: Deep Obsidian Black & Cosmic Purple
--  Fitur: Auto Farm, Auto Place Egg (13 Titik PetEggService), Pet Team, Utility
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

-- Safe UI Parent
local function getSafeParent()
    local success, pgui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if success and pgui then return pgui end
    return game:GetService("CoreGui")
end

-- =========================================================================
-- [1] STATE & REMOTES
-- =========================================================================
local State = {
    AutoPlant = false,
    AutoHarvest = false,
    AutoSell = false,
    SelectedSeed = "",
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
    
    Walkspeed = false,
    InfJump = false,
    Noclip = false,
    AntiAfk = true,
    SpeedVal = 42
}

local GameEvents = ReplicatedStorage:FindFirstChild("GameEvents") or ReplicatedStorage:WaitForChild("GameEvents", 5)
local Plant_RE = GameEvents and GameEvents:FindFirstChild("Plant_RE")
local Sell_Inventory = GameEvents and GameEvents:FindFirstChild("Sell_Inventory")
local PetEggService = GameEvents and GameEvents:FindFirstChild("PetEggService")
local Farms = workspace:FindFirstChild("Farm")

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

-- =========================================================================
-- [2] BACKGROUND LOOPS (AUTO EGG, FARM, UTILITY)
-- =========================================================================
task.spawn(function()
    while true do
        if State.AutoPlaceEgg and PetEggService then
            pcall(function()
                local eggs = {}
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    for _, tool in ipairs(bp:GetChildren()) do
                        if tool:IsA("Tool") and tool.Name:lower():find("egg") then
                            table.insert(eggs, tool)
                        end
                    end
                end
                
                if #eggs > 0 then
                    local targetEgg = eggs[1]
                    for i = 1, math.min(#EggCFrameList, State.MaxEggPlace) do
                        if not State.AutoPlaceEgg then break end
                        if targetEgg.Parent == bp and Humanoid then
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
                            task.wait(0.05)
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

-- Anti AFK
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if State.AntiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- Noclip & Walkspeed
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

-- =========================================================================
-- [3] UI CONSTRUCTION (DEEP OBSIDIAN & COSMIC PURPLE)
-- =========================================================================
local GUI_NAME = "ZyloHub_v3_5_Repo2"
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
Main.Size = UDim2.new(0, 560, 0, 360)
Main.Position = UDim2.new(0.5, -280, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(7, 9, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local mCorner = Instance.new("UICorner", Main)
mCorner.CornerRadius = UDim.new(0, 12)

local mStroke = Instance.new("UIStroke", Main)
mStroke.Color = Color3.fromRGB(138, 43, 226)
mStroke.Thickness = 1.5

-- TopBar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 42)
Topbar.BackgroundColor3 = Color3.fromRGB(11, 14, 28)
Topbar.BorderSizePixel = 0
local tbCorner = Instance.new("UICorner", Topbar)
tbCorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Topbar)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "ZYLOHUB <font color=\"#AF52FF\">[Grow a Garden]</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(245, 247, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Floating Toggle Z
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0, 44, 0, 44)
FloatBtn.Position = UDim2.new(0, 15, 0.2, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
FloatBtn.Text = "Z"
FloatBtn.TextColor3 = Color3.fromRGB(220, 130, 255)
FloatBtn.Font = Enum.Font.FredokaOne
FloatBtn.TextSize = 22
FloatBtn.Active = true
FloatBtn.Draggable = true
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)
local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = Color3.fromRGB(138, 43, 226)
fbStroke.Thickness = 2

local function toggleUI()
    Main.Visible = not Main.Visible
end
CloseBtn.MouseButton1Click:Connect(toggleUI)
FloatBtn.MouseButton1Click:Connect(toggleUI)

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 120, 1, -48)
Sidebar.Position = UDim2.new(0, 6, 0, 44)
Sidebar.BackgroundColor3 = Color3.fromRGB(9, 12, 24)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding = UDim.new(0, 4)
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 6)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)

-- Container Pages
local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -138, 1, -48)
Container.Position = UDim2.new(0, 132, 0, 44)
Container.BackgroundColor3 = Color3.fromRGB(12, 16, 32)
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 8)

local Tabs = {}
local TabBtns = {}

local function SwitchTab(name)
    for tName, page in pairs(Tabs) do
        page.Visible = (tName == name)
    end
    for tName, btn in pairs(TabBtns) do
        if tName == name then
            btn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
            btn.TextColor3 = Color3.fromRGB(145, 155, 185)
        end
    end
end

local function CreateTab(name, icon, order)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(145, 155, 185)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 10
    btn.LayoutOrder = order
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("ScrollingFrame", Container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
    page.Visible = false
    local pLayout = Instance.new("UIListLayout", page)
    pLayout.Padding = UDim.new(0, 6)
    local pPad = Instance.new("UIPadding", page)
    pPad.PaddingTop = UDim.new(0, 8)
    pPad.PaddingLeft = UDim.new(0, 8)
    pPad.PaddingRight = UDim.new(0, 8)

    Tabs[name] = page
    TabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
    return page
end

local function addToggleRow(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(245, 247, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -56, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(30, 35, 55)
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local val = default
    btn.MouseButton1Click:Connect(function()
        val = not val
        btn.Text = val and "ON" or "OFF"
        btn.BackgroundColor3 = val and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(30, 35, 55)
        callback(val)
    end)
end

-- =============================================================
-- [4] TAB PAGES
-- =============================================================

-- TAB 1: FARM
local farmPage = CreateTab("Farm", "🌿", 1)
addToggleRow(farmPage, "Auto Harvest Tanaman", State.AutoHarvest, function(v) State.AutoHarvest = v end)
addToggleRow(farmPage, "Auto Plant (Tanam Benih)", State.AutoPlant, function(v) State.AutoPlant = v end)
addToggleRow(farmPage, "Auto Sell Otomatis", State.AutoSell, function(v) State.AutoSell = v end)

-- TAB 2: PETS & EGGS (13 Titik PetEggService)
local petPage = CreateTab("Pets", "🐾", 2)
addToggleRow(petPage, "Auto Place Egg (13 Slot PetEggService)", State.AutoPlaceEgg, function(v) State.AutoPlaceEgg = v end)
addToggleRow(petPage, "Auto Hatch (Klaim Telur Menetas)", State.AutoHatch, function(v) State.AutoHatch = v end)
addToggleRow(petPage, "Pet Team Manager (Auto Equip)", State.PetTeamActive, function(v) State.PetTeamActive = v end)

-- TAB 3: UTILITY
local utilPage = CreateTab("Utility", "🔧", 3)
addToggleRow(utilPage, "WalkSpeed Boost (Lari Cepat 42)", State.Walkspeed, function(v)
    State.Walkspeed = v
    if not v and Humanoid then Humanoid.WalkSpeed = 16 end
end)
addToggleRow(utilPage, "Noclip (Tembus Pagar)", State.Noclip, function(v) State.Noclip = v end)
addToggleRow(utilPage, "Anti AFK 20 Menit", State.AntiAfk, function(v) State.AntiAfk = v end)

-- Default Open Tab Pets
SwitchTab("Pets")

-- Toast Notifikasi Sukses
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ZyloHub v3.5",
        Text = "Berhasil dimuat! Klik tombol Z di kiri untuk buka menu.",
        Duration = 6
    })
end)
