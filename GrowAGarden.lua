-- =============================================================
-- [PET TEAM MANAGER UI - PERSIS GAMBAR REFERENSI]
-- Diletakkan tepat di bawah Accordion Auto Hatch pada PagePets
-- =============================================================

-- 1. State Tambahan untuk Team Manager
State.ActiveTeam = "Main Team"
State.TeamDelayEquip = { ["Main Team"] = 0, ["Bronto Team"] = 0, ["Hatch Team"] = 0, ["Sell Team"] = 0 }
State.TeamDelayUnequip = { ["Main Team"] = 1, ["Bronto Team"] = 1, ["Hatch Team"] = 1, ["Sell Team"] = 1 }
State.SelectedPets = { ["Main Team"] = {}, ["Bronto Team"] = {}, ["Hatch Team"] = {}, ["Sell Team"] = {} }
State.TeamSearchQuery = ""
State.IsTeamRunning = false

-- 2. Card Container Utama Pet Team Manager
local TeamCard = Instance.new("Frame", PagePets)
TeamCard.Name = "PetTeamManagerCard"
TeamCard.Size = UDim2.new(1, 0, 0, 360)
TeamCard.BackgroundColor3 = C.CARD
Instance.new("UICorner", TeamCard).CornerRadius = UDim.new(0, 10)
local tcStroke = Instance.new("UIStroke", TeamCard)
tcStroke.Color = Color3.fromRGB(240, 185, 40) -- Aksen Gold sesuai referensi
tcStroke.Thickness = 1.5

-- [A] SUB-TABS ROW (Main Team, Bronto Team, Hatch Team, Sell Team, Config, Gear)
local SubTabRow = Instance.new("ScrollingFrame", TeamCard)
SubTabRow.Position = UDim2.new(0, 10, 0, 10)
SubTabRow.Size = UDim2.new(1, -20, 0, 30)
SubTabRow.BackgroundTransparency = 1
SubTabRow.ScrollBarThickness = 0
SubTabRow.CanvasSize = UDim2.new(0, 480, 0, 0)

local stLayout = Instance.new("UIListLayout", SubTabRow)
stLayout.FillDirection = Enum.FillDirection.Horizontal
stLayout.Padding = UDim.new(0, 6)

local subTabs = { "Main Team", "Bronto Team", "Hatch Team", "Sell Team", "Config" }
local subTabBtns = {}

-- Header Text Reference untuk Delay Settings
local DelayHeaderLbl = nil
local SelPetTitle = nil

local function updateSubTabs()
    for name, btn in pairs(subTabBtns) do
        local isAct = (State.ActiveTeam == name)
        btn.BackgroundColor3 = isAct and Color3.fromRGB(28, 24, 16) or Color3.fromRGB(16, 20, 36)
        btn.TextColor3 = isAct and Color3.fromRGB(255, 215, 80) or C.TEXT_M
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = isAct and Color3.fromRGB(240, 185, 40) or Color3.fromRGB(40, 48, 75)
            stroke.Thickness = isAct and 1.5 or 1
        end
    end
    if DelayHeaderLbl then
        DelayHeaderLbl.Text = "( " .. State.ActiveTeam .. " ) Delay Settings"
    end
    if SelPetTitle then
        SelPetTitle.Text = "Select Pet (" .. State.ActiveTeam .. ")"
    end
end

for _, tabName in ipairs(subTabs) do
    local sBtn = Instance.new("TextButton", SubTabRow)
    sBtn.Size = UDim2.new(0, (tabName == "Config") and 68 or 88, 1, 0)
    sBtn.BackgroundColor3 = (State.ActiveTeam == tabName) and Color3.fromRGB(28, 24, 16) or Color3.fromRGB(16, 20, 36)
    sBtn.Text = tabName
    sBtn.TextColor3 = (State.ActiveTeam == tabName) and Color3.fromRGB(255, 215, 80) or C.TEXT_M
    sBtn.Font = Enum.Font.GothamBold
    sBtn.TextSize = 9.5
    Instance.new("UICorner", sBtn).CornerRadius = UDim.new(1, 0) -- Style Pill Bulat
    local bStroke = Instance.new("UIStroke", sBtn)
    bStroke.Color = (State.ActiveTeam == tabName) and Color3.fromRGB(240, 185, 40) or Color3.fromRGB(40, 48, 75)

    sBtn.MouseButton1Click:Connect(function()
        State.ActiveTeam = tabName
        updateSubTabs()
    end)
    subTabBtns[tabName] = sBtn
end

-- Tombol Gear Icon di samping Tab
local GearBtn = Instance.new("TextButton", SubTabRow)
GearBtn.Size = UDim2.new(0, 32, 1, 0)
GearBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
GearBtn.Text = "⚙"
GearBtn.TextColor3 = C.TEXT_M
GearBtn.Font = Enum.Font.GothamBold
GearBtn.TextSize = 12
Instance.new("UICorner", GearBtn).CornerRadius = UDim.new(1, 0)
local gbStroke = Instance.new("UIStroke", GearBtn)
gbStroke.Color = Color3.fromRGB(40, 48, 75)

-- [B] DELAY SETTINGS ACCORDION HEADER
local DelayHeader = Instance.new("Frame", TeamCard)
DelayHeader.Position = UDim2.new(0, 10, 0, 48)
DelayHeader.Size = UDim2.new(1, -20, 0, 26)
DelayHeader.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Instance.new("UICorner", DelayHeader).CornerRadius = UDim.new(0, 6)
local dhStroke = Instance.new("UIStroke", DelayHeader)
dhStroke.Color = Color3.fromRGB(240, 185, 40)
dhStroke.Thickness = 1

DelayHeaderLbl = Instance.new("TextLabel", DelayHeader)
DelayHeaderLbl.Position = UDim2.new(0, 10, 0, 0)
DelayHeaderLbl.Size = UDim2.new(1, -35, 1, 0)
DelayHeaderLbl.BackgroundTransparency = 1
DelayHeaderLbl.Text = "( " .. State.ActiveTeam .. " ) Delay Settings"
DelayHeaderLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
DelayHeaderLbl.Font = Enum.Font.GothamBold
DelayHeaderLbl.TextSize = 9.5
DelayHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left

local DhArrow = Instance.new("TextLabel", DelayHeader)
DhArrow.Position = UDim2.new(1, -22, 0, 0)
DhArrow.Size = UDim2.new(0, 16, 1, 0)
DhArrow.BackgroundTransparency = 1
DhArrow.Text = "▼"
DhArrow.TextColor3 = Color3.fromRGB(255, 215, 80)
DhArrow.Font = Enum.Font.GothamBold
DhArrow.TextSize = 8

-- [C] STATUS COUNTER ROW (Main (0), Bronto (0), Hatch (0), Sell (0))
local CounterRow = Instance.new("Frame", TeamCard)
CounterRow.Position = UDim2.new(0, 12, 0, 80)
CounterRow.Size = UDim2.new(1, -24, 0, 18)
CounterRow.BackgroundTransparency = 1

local cntLayout = Instance.new("UIListLayout", CounterRow)
cntLayout.FillDirection = Enum.FillDirection.Horizontal
cntLayout.Padding = UDim.new(0, 12)

local function makeCounterLabel(icon, name, count)
    local lbl = Instance.new("TextLabel", CounterRow)
    lbl.Size = UDim2.new(0, 78, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. " " .. name .. " (" .. tostring(count) .. ")"
    lbl.TextColor3 = C.TEXT_M
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local cMain   = makeCounterLabel("🦹", "Main", 0)
local cBronto = makeCounterLabel("🦕", "Bronto", 0)
local cHatch  = makeCounterLabel("🥚", "Hatch", 0)
local cSell   = makeCounterLabel("💰", "Sell", 0)

-- [D] DELAY EQUIP (sec) ROW
local RowEquip = Instance.new("Frame", TeamCard)
RowEquip.Position = UDim2.new(0, 12, 0, 104)
RowEquip.Size = UDim2.new(1, -24, 0, 26)
RowEquip.BackgroundTransparency = 1

local eqLbl = Instance.new("TextLabel", RowEquip)
eqLbl.Size = UDim2.new(0.6, 0, 1, 0)
eqLbl.BackgroundTransparency = 1
eqLbl.Text = "Delay Equip (sec)"
eqLbl.TextColor3 = C.TEXT_M
eqLbl.Font = Enum.Font.GothamMedium
eqLbl.TextSize = 9.5
eqLbl.TextXAlignment = Enum.TextXAlignment.Left

local eqBox = Instance.new("TextBox", RowEquip)
eqBox.Position = UDim2.new(1, -75, 0, 0)
eqBox.Size = UDim2.new(0, 75, 1, 0)
eqBox.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
eqBox.Text = "0"
eqBox.TextColor3 = C.TEXT_W
eqBox.Font = Enum.Font.GothamBold
eqBox.TextSize = 9.5
Instance.new("UICorner", eqBox).CornerRadius = UDim.new(0, 6)
local eqBoxStroke = Instance.new("UIStroke", eqBox)
eqBoxStroke.Color = Color3.fromRGB(40, 48, 75)

eqBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(eqBox.Text)
    if val and State.TeamDelayEquip[State.ActiveTeam] then
        State.TeamDelayEquip[State.ActiveTeam] = val
    end
end)

-- [E] DELAY UNEQUIP (sec) ROW
local RowUnequip = Instance.new("Frame", TeamCard)
RowUnequip.Position = UDim2.new(0, 12, 0, 136)
RowUnequip.Size = UDim2.new(1, -24, 0, 26)
RowUnequip.BackgroundTransparency = 1

local uqLbl = Instance.new("TextLabel", RowUnequip)
uqLbl.Size = UDim2.new(0.6, 0, 1, 0)
uqLbl.BackgroundTransparency = 1
uqLbl.Text = "Delay Unequip (sec)"
uqLbl.TextColor3 = C.TEXT_M
uqLbl.Font = Enum.Font.GothamMedium
uqLbl.TextSize = 9.5
uqLbl.TextXAlignment = Enum.TextXAlignment.Left

local uqBox = Instance.new("TextBox", RowUnequip)
uqBox.Position = UDim2.new(1, -75, 0, 0)
uqBox.Size = UDim2.new(0, 75, 1, 0)
uqBox.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
uqBox.Text = "1"
uqBox.TextColor3 = C.TEXT_W
uqBox.Font = Enum.Font.GothamBold
uqBox.TextSize = 9.5
Instance.new("UICorner", uqBox).CornerRadius = UDim.new(0, 6)
local uqBoxStroke = Instance.new("UIStroke", uqBox)
uqBoxStroke.Color = Color3.fromRGB(40, 48, 75)

uqBox:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(uqBox.Text)
    if val and State.TeamDelayUnequip[State.ActiveTeam] then
        State.TeamDelayUnequip[State.ActiveTeam] = val
    end
end)

-- [F] SELECT PET LIST CONTAINER
SelPetTitle = Instance.new("TextLabel", TeamCard)
SelPetTitle.Position = UDim2.new(0, 12, 0, 168)
SelPetTitle.Size = UDim2.new(1, -24, 0, 16)
SelPetTitle.BackgroundTransparency = 1
SelPetTitle.Text = "Select Pet (" .. State.ActiveTeam .. ")"
SelPetTitle.TextColor3 = C.TEXT_M
SelPetTitle.Font = Enum.Font.GothamMedium
SelPetTitle.TextSize = 9.5
SelPetTitle.TextXAlignment = Enum.TextXAlignment.Left

local PetListFrame = Instance.new("Frame", TeamCard)
PetListFrame.Position = UDim2.new(0, 10, 0, 188)
PetListFrame.Size = UDim2.new(1, -20, 0, 120)
PetListFrame.BackgroundColor3 = Color3.fromRGB(10, 13, 24)
Instance.new("UICorner", PetListFrame).CornerRadius = UDim.new(0, 6)
local plStroke = Instance.new("UIStroke", PetListFrame)
plStroke.Color = Color3.fromRGB(32, 40, 65)

local SearchBox = Instance.new("TextBox", PetListFrame)
SearchBox.Position = UDim2.new(0, 8, 0, 6)
SearchBox.Size = UDim2.new(1, -16, 0, 22)
SearchBox.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
SearchBox.PlaceholderText = "Search..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 110, 140)
SearchBox.Text = ""
SearchBox.TextColor3 = C.TEXT_W
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.TextSize = 9
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

local PetScroll = Instance.new("ScrollingFrame", PetListFrame)
PetScroll.Position = UDim2.new(0, 8, 0, 32)
PetScroll.Size = UDim2.new(1, -16, 1, -38)
PetScroll.BackgroundTransparency = 1
PetScroll.ScrollBarThickness = 2
PetScroll.CanvasSize = UDim2.new(0, 0, 0, 90)

local psLayout = Instance.new("UIListLayout", PetScroll)
psLayout.Padding = UDim.new(0, 3)

-- Contoh Item Placeholder Sesuai Gambar (Nanti dihubungkan ke Dataset Game Asli)
local dummyPets = {
    "Bald Eagle | Age 46 | 4.98 KG",
    "Spider | Age 15 | 3.37 KG"
}

for _, petStr in ipairs(dummyPets) do
    local petItem = Instance.new("TextButton", PetScroll)
    petItem.Size = UDim2.new(1, -4, 0, 22)
    petItem.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    petItem.Text = "   " .. petStr
    petItem.TextColor3 = C.TEXT_M
    petItem.Font = Enum.Font.GothamMedium
    petItem.TextSize = 9
    petItem.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", petItem).CornerRadius = UDim.new(0, 4)
end

-- [G] ACTION BUTTONS ROW (START & STOP)
local BtnRow = Instance.new("Frame", TeamCard)
BtnRow.Position = UDim2.new(0, 10, 1, -40)
BtnRow.Size = UDim2.new(1, -20, 0, 30)
BtnRow.BackgroundTransparency = 1

local StartBtn = Instance.new("TextButton", BtnRow)
StartBtn.Size = UDim2.new(0, 80, 1, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 14)
StartBtn.Text = "⚡ START"
StartBtn.TextColor3 = Color3.fromRGB(255, 215, 80)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 10
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(1, 0)
local sbStroke = Instance.new("UIStroke", StartBtn)
sbStroke.Color = Color3.fromRGB(240, 185, 40)
sbStroke.Thickness = 1.5

local StopBtn = Instance.new("TextButton", BtnRow)
StopBtn.Position = UDim2.new(0, 88, 0, 0)
StopBtn.Size = UDim2.new(0, 72, 1, 0)
StopBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 34)
StopBtn.Text = "STOP"
StopBtn.TextColor3 = C.TEXT_M
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 10
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(1, 0)
local stpStroke = Instance.new("UIStroke", StopBtn)
stpStroke.Color = Color3.fromRGB(45, 52, 75)

-- Event Toggle START / STOP
StartBtn.MouseButton1Click:Connect(function()
    State.IsTeamRunning = true
    StartBtn.BackgroundColor3 = Color3.fromRGB(240, 185, 40)
    StartBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 34)
    StopBtn.TextColor3 = C.TEXT_M
    stpStroke.Color = Color3.fromRGB(45, 52, 75)
end)

StopBtn.MouseButton1Click:Connect(function()
    State.IsTeamRunning = false
    StartBtn.BackgroundColor3 = Color3.fromRGB(24, 20, 14)
    StartBtn.TextColor3 = Color3.fromRGB(255, 215, 80)
    StopBtn.BackgroundColor3 = Color3.fromRGB(36, 18, 24)
    StopBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    stpStroke.Color = Color3.fromRGB(200, 60, 60)
end)
