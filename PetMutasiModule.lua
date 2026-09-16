-- =========================================================================
--  ZYLOHUB - AUTO MUTASI MODULE (OFFICIAL EXTENSION v3.6.4)
--  Repository: zylo-games/PetMutasiModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Tabs: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config
--  Mode Pipeline: Modal Popup Selector (Mode A - F) dengan Penjelasan Lengkap
--  Presisi Penuh (Full Width hingga Titik Kanan) & Tombol START / STOP
-- =========================================================================

return function(ParentContainer, State, ZyloLib, Main)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local C = ZyloLib.Colors

    -- State Inisialisasi Mutasi
    State.MutasiActiveCategory = State.MutasiActiveCategory or "Elephant"
    State.MutasiEquipAge = State.MutasiEquipAge or 20
    State.MutasiUnequipAge = State.MutasiUnequipAge or 0
    State.MutasiMode = State.MutasiMode or "Mode: A"
    State.MutasiRunning = State.MutasiRunning or false
    State.MutasiSelectedPets = State.MutasiSelectedPets or {}
    State.MutasiSearchQuery = State.MutasiSearchQuery or ""

    -- Container Utama
    local MutasiWrapper = Instance.new("Frame", ParentContainer)
    MutasiWrapper.Size = UDim2.new(1, 0, 0, 440)
    MutasiWrapper.BackgroundTransparency = 1

    local MutasiLayout = Instance.new("UIListLayout", MutasiWrapper)
    MutasiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MutasiLayout.Padding = UDim.new(0, 6)

    -- =====================================================================
    -- 1. SUB-NAVIGASI KATEGORI (FULL WIDTH PILLS ROW)
    -- Urutan: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config + ⚙
    -- Dibuat Presisi Penuh (Full-Width) pas dari ujung kiri sampai titik kanan
    -- =====================================================================
    local NavRow = Instance.new("Frame", MutasiWrapper)
    NavRow.Size = UDim2.new(1, 0, 0, 28)
    NavRow.BackgroundTransparency = 1
    NavRow.BorderSizePixel = 0
    NavRow.ClipsDescendants = false
    NavRow.LayoutOrder = 1

    -- Container Pills Kategori (Mengisi seluruh ruang kecuali tombol Gear di ujung kanan)
    local PillsContainer = Instance.new("Frame", NavRow)
    PillsContainer.Size = UDim2.new(1, -32, 1, 0)
    PillsContainer.Position = UDim2.new(0, 0, 0, 0)
    PillsContainer.BackgroundTransparency = 1
    PillsContainer.BorderSizePixel = 0
    PillsContainer.ClipsDescendants = false

    local NavList = Instance.new("UIListLayout", PillsContainer)
    NavList.FillDirection = Enum.FillDirection.Horizontal
    NavList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    NavList.VerticalAlignment = Enum.VerticalAlignment.Center
    NavList.Padding = UDim.new(0, 5)

    local Categories = {
        { name = "Elephant",  weight = 1.05 },
        { name = "Machine",   weight = 1.05 },
        { name = "Nightmare", weight = 1.25 },
        { name = "100 Age",   weight = 1.05 },
        { name = "XP",        weight = 0.75 },
        { name = "GBXP",      weight = 0.85 },
        { name = "Config",    weight = 1.00 }
    }
    local totalWeight = 7.0 -- Total bobot rasio lebar otomatis

    local CategoryButtons = {}
    local updateThresholdTitle
    local updateActionButton
    local refreshPetList

    for _, catData in ipairs(Categories) do
        local catName = catData.name
        local wScale = catData.weight / totalWeight

        local btn = Instance.new("TextButton", PillsContainer)
        -- Lebar dinamis responsif dengan kompensasi padding 5px (-4px offset)
        btn.Size = UDim2.new(wScale, -4, 0, 26)
        btn.BackgroundColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
        btn.Text = catName
        btn.TextColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 8.5
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 13)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = (State.MutasiActiveCategory == catName) and C.PURPLE or Color3.fromRGB(38, 45, 70)
        stroke.Thickness = (State.MutasiActiveCategory == catName) and 1.5 or 1

        CategoryButtons[catName] = { btn = btn, stroke = stroke }

        btn.MouseButton1Click:Connect(function()
            State.MutasiActiveCategory = catName
            for cName, data in pairs(CategoryButtons) do
                local isActive = (cName == catName)
                data.btn.BackgroundColor3 = isActive and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
                data.btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or C.TEXT_M
                data.stroke.Color = isActive and C.PURPLE or Color3.fromRGB(38, 45, 70)
                data.stroke.Thickness = isActive and 1.5 or 1
            end
            if updateThresholdTitle then updateThresholdTitle() end
            if updateActionButton then updateActionButton() end
            if refreshPetList then refreshPetList() end
        end)
    end

    -- Tombol ⚙ (Settings Gear di Ujung Kanan Presisi, Pas Titik Merah)
    local GearBtn = Instance.new("TextButton", NavRow)
    GearBtn.Size = UDim2.new(0, 26, 0, 26)
    GearBtn.Position = UDim2.new(1, -26, 0.5, -13)
    GearBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 34)
    GearBtn.Text = "⚙"
    GearBtn.TextColor3 = C.TEXT_M
    GearBtn.Font = Enum.Font.GothamBold
    GearBtn.TextSize = 12
    Instance.new("UICorner", GearBtn).CornerRadius = UDim.new(0, 13)
    local gearStroke = Instance.new("UIStroke", GearBtn)
    gearStroke.Color = Color3.fromRGB(38, 45, 70)

    GearBtn.MouseButton1Click:Connect(function()
        print("[ZyloHub] Settings button clicked")
    end)

    -- =====================================================================
    -- 2. DROPDOWN HEADER: ( [Category] Team ) Threshold Age & Kg
    -- =====================================================================
    local ThreshHeader = Instance.new("TextButton", MutasiWrapper)
    ThreshHeader.Size = UDim2.new(1, 0, 0, 30)
    ThreshHeader.BackgroundColor3 = Color3.fromRGB(13, 16, 32)
    ThreshHeader.Text = ""
    ThreshHeader.LayoutOrder = 2
    Instance.new("UICorner", ThreshHeader).CornerRadius = UDim.new(0, 8)
    local thStroke = Instance.new("UIStroke", ThreshHeader)
    thStroke.Color = Color3.fromRGB(38, 45, 72)

    local thTitle = Instance.new("TextLabel", ThreshHeader)
    thTitle.Position = UDim2.new(0, 10, 0, 0)
    thTitle.Size = UDim2.new(1, -40, 1, 0)
    thTitle.BackgroundTransparency = 1
    thTitle.Text = "( " .. State.MutasiActiveCategory .. " Team ) Threshold Age & Kg"
    thTitle.TextColor3 = C.TEXT_W
    thTitle.Font = Enum.Font.GothamBold
    thTitle.TextSize = 9.5
    thTitle.TextXAlignment = Enum.TextXAlignment.Left

    updateThresholdTitle = function()
        thTitle.Text = "( " .. State.MutasiActiveCategory .. " Team ) Threshold Age & Kg"
    end

    local thArrow = Instance.new("TextLabel", ThreshHeader)
    thArrow.Position = UDim2.new(1, -26, 0, 0)
    thArrow.Size = UDim2.new(0, 20, 1, 0)
    thArrow.BackgroundTransparency = 1
    thArrow.Text = "▼"
    thArrow.TextColor3 = C.PURPLE_L
    thArrow.Font = Enum.Font.GothamBold
    thArrow.TextSize = 9

    -- =====================================================================
    -- 3. BODY COLLAPSIBLE: STATS ROW + EQUIP/UNEQUIP AGE INPUTS
    -- =====================================================================
    local ThreshBody = Instance.new("Frame", MutasiWrapper)
    ThreshBody.Size = UDim2.new(1, 0, 0, 86)
    ThreshBody.BackgroundTransparency = 1
    ThreshBody.LayoutOrder = 3

    local TbLayout = Instance.new("UIListLayout", ThreshBody)
    TbLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TbLayout.Padding = UDim.new(0, 4)

    -- Toggle Buka / Tutup Threshold
    local isThreshOpen = true
    ThreshHeader.MouseButton1Click:Connect(function()
        isThreshOpen = not isThreshOpen
        ThreshBody.Visible = isThreshOpen
        thArrow.Text = isThreshOpen and "▼" or "▶"
    end)

    -- Row 3A: Inline Stats Row (Horizontal Scrollable dengan Canvas Height Tetap 22px)
    local StatsScroll = Instance.new("ScrollingFrame", ThreshBody)
    StatsScroll.Size = UDim2.new(1, 0, 0, 22)
    StatsScroll.BackgroundTransparency = 1
    StatsScroll.BorderSizePixel = 0
    StatsScroll.ScrollBarThickness = 0
    StatsScroll.ScrollingDirection = Enum.ScrollingDirection.X
    StatsScroll.CanvasSize = UDim2.new(0, 480, 0, 22)
    StatsScroll.LayoutOrder = 1

    local StatsLayout = Instance.new("UIListLayout", StatsScroll)
    StatsLayout.FillDirection = Enum.FillDirection.Horizontal
    StatsLayout.Padding = UDim.new(0, 10)
    StatsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function CreateStatItem(parent, icon, name, initialVal, accentColor, itemWidth)
        local item = Instance.new("TextLabel", parent)
        item.Size = UDim2.new(0, itemWidth or 78, 1, 0)
        item.BackgroundTransparency = 1
        item.Text = icon .. " " .. name .. " (" .. tostring(initialVal) .. ")"
        item.TextColor3 = accentColor or C.TEXT_M
        item.Font = Enum.Font.GothamMedium
        item.TextSize = 8.5
        item.TextXAlignment = Enum.TextXAlignment.Left
        return item
    end

    local statEle  = CreateStatItem(StatsScroll, "🐘", "Elephant", 0, Color3.fromRGB(150, 210, 255), 78)
    local statMac  = CreateStatItem(StatsScroll, "⚙️", "Machine", 0, Color3.fromRGB(255, 185, 100), 76)
    local statNM   = CreateStatItem(StatsScroll, "🌙", "Nightmare", 0, C.PURPLE_L, 82)
    local stat100  = CreateStatItem(StatsScroll, "💯", "100 Age", 0, C.CYAN, 74)
    local statXP   = CreateStatItem(StatsScroll, "📘", "XP", 0, Color3.fromRGB(130, 200, 255), 62)
    local statGBXP = CreateStatItem(StatsScroll, "🧪", "GBXP", 0, Color3.fromRGB(180, 140, 255), 72)

    -- Row 3B: Equip Age
    local RowEq = Instance.new("Frame", ThreshBody)
    RowEq.Size = UDim2.new(1, 0, 0, 26)
    RowEq.BackgroundTransparency = 1
    RowEq.LayoutOrder = 2

    local EqLabel = Instance.new("TextLabel", RowEq)
    EqLabel.Position = UDim2.new(0, 4, 0, 0)
    EqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    EqLabel.BackgroundTransparency = 1
    EqLabel.Text = "Equip Age"
    EqLabel.TextColor3 = C.TEXT_W
    EqLabel.Font = Enum.Font.GothamMedium
    EqLabel.TextSize = 9.5
    EqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local EqBox = Instance.new("TextBox", RowEq)
    EqBox.Position = UDim2.new(1, -85, 0.5, -12)
    EqBox.Size = UDim2.new(0, 85, 0, 24)
    EqBox.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    EqBox.Text = tostring(State.MutasiEquipAge)
    EqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    EqBox.Font = Enum.Font.GothamBold
    EqBox.TextSize = 9.5
    Instance.new("UICorner", EqBox).CornerRadius = UDim.new(0, 6)
    local eqStroke = Instance.new("UIStroke", EqBox)
    eqStroke.Color = Color3.fromRGB(42, 50, 78)

    EqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(EqBox.Text)
        if num then State.MutasiEquipAge = num end
    end)

    -- Row 3C: Unequip Age
    local RowUneq = Instance.new("Frame", ThreshBody)
    RowUneq.Size = UDim2.new(1, 0, 0, 26)
    RowUneq.BackgroundTransparency = 1
    RowUneq.LayoutOrder = 3

    local UneqLabel = Instance.new("TextLabel", RowUneq)
    UneqLabel.Position = UDim2.new(0, 4, 0, 0)
    UneqLabel.Size = UDim2.new(0.6, 0, 1, 0)
    UneqLabel.BackgroundTransparency = 1
    UneqLabel.Text = "Unequip Age"
    UneqLabel.TextColor3 = C.TEXT_W
    UneqLabel.Font = Enum.Font.GothamMedium
    UneqLabel.TextSize = 9.5
    UneqLabel.TextXAlignment = Enum.TextXAlignment.Left

    local UneqBox = Instance.new("TextBox", RowUneq)
    UneqBox.Position = UDim2.new(1, -85, 0.5, -12)
    UneqBox.Size = UDim2.new(0, 85, 0, 24)
    UneqBox.BackgroundColor3 = Color3.fromRGB(16, 20, 36)
    UneqBox.Text = tostring(State.MutasiUnequipAge)
    UneqBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UneqBox.Font = Enum.Font.GothamBold
    UneqBox.TextSize = 9.5
    Instance.new("UICorner", UneqBox).CornerRadius = UDim.new(0, 6)
    local unStroke = Instance.new("UIStroke", UneqBox)
    unStroke.Color = Color3.fromRGB(42, 50, 78)

    UneqBox:GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(UneqBox.Text)
        if num then State.MutasiUnequipAge = num end
    end)

    -- =====================================================================
    -- 4. SECTION HEADER: Select Pet [Category] Team (Favorite List)
    -- =====================================================================
    local PetListHeader = Instance.new("Frame", MutasiWrapper)
    PetListHeader.Size = UDim2.new(1, 0, 0, 22)
    PetListHeader.BackgroundTransparency = 1
    PetListHeader.LayoutOrder = 4

    local ListTitle = Instance.new("TextLabel", PetListHeader)
    ListTitle.Position = UDim2.new(0, 4, 0, 0)
    ListTitle.Size = UDim2.new(1, -8, 1, 0)
    ListTitle.BackgroundTransparency = 1
    ListTitle.Text = "Select Pet " .. State.MutasiActiveCategory .. " Team (Favorite List)"
    ListTitle.TextColor3 = C.TEXT_M
    ListTitle.Font = Enum.Font.GothamMedium
    ListTitle.TextSize = 9
    ListTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- =====================================================================
    -- 5. DAFTAR PET (CARD LIST SESUAI SCREENSHOT DENGAN FILTER PURE PET)
    -- =====================================================================
    local PetListScroll = Instance.new("ScrollingFrame", MutasiWrapper)
    PetListScroll.Size = UDim2.new(1, 0, 0, 165)
    PetListScroll.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    PetListScroll.ScrollBarThickness = 3
    PetListScroll.ScrollBarImageColor3 = C.PURPLE
    PetListScroll.LayoutOrder = 5
    Instance.new("UICorner", PetListScroll).CornerRadius = UDim.new(0, 8)
    local plsStroke = Instance.new("UIStroke", PetListScroll)
    plsStroke.Color = Color3.fromRGB(30, 36, 60)

    local PlsLayout = Instance.new("UIListLayout", PetListScroll)
    PlsLayout.Padding = UDim.new(0, 4)
    local PlsPadding = Instance.new("UIPadding", PetListScroll)
    PlsPadding.PaddingTop = UDim.new(0, 6)
    PlsPadding.PaddingBottom = UDim.new(0, 6)
    PlsPadding.PaddingLeft = UDim.new(0, 6)
    PlsPadding.PaddingRight = UDim.new(0, 6)

    -- Filter item consumable
    local BLACKLIST_ITEM_KEYWORDS = {
        "shard", "treat", "reroll", "pack", "bundle", "crate", "chest", "box", "gift", 
        "potion", "elixir", "scroll", "book", "tome", "ticket", "token", "pass", "badge",
        "watering can", "sprinkler", "shovel", "hoe", "net", "fertilizer"
    }

    local function isPurePetTool(tool)
        if not tool:IsA("Tool") then return false end
        if tool:FindFirstChild("Item_String") then return false end
        local nLower = tool.Name:lower()
        if nLower:find("seed") or nLower:find("egg") then return false end
        for _, kw in ipairs(BLACKLIST_ITEM_KEYWORDS) do
            if nLower:find(kw) then return false end
        end
        return (tool:FindFirstChild("PetData") ~= nil) or (not tool:FindFirstChild("PetEggToolLocal"))
    end

    local function GetBackpackPets()
        local pets = {}
        local bp = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer and LocalPlayer.Character
        local function scan(container)
            if not container then return end
            for _, tool in ipairs(container:GetChildren()) do
                if isPurePetTool(tool) then
                    local pName = tool.Name:gsub("%[.-%]", ""):gsub("^%s*(.-)%s*$", "%1")
                    local mutation = tool:GetAttribute("Mutation") or (tool.Name:match("%[(.-)%]") or "Normal")
                    local age = tool:GetAttribute("Age") or tonumber(tool.Name:match("Age%s*(%d+)")) or 1
                    local weight = tool:GetAttribute("Weight") or tonumber(tool.Name:match("(%d+%.?%d*)%s*KG")) or 5.0
                    local uuid = tool:GetAttribute("UUID") or tool.Name

                    table.insert(pets, {
                        UUID = uuid,
                        Name = pName,
                        Mutation = mutation,
                        Age = age,
                        Weight = weight,
                        Tool = tool
                    })
                end
            end
        end
        scan(bp)
        scan(char)
        return pets
    end

    refreshPetList = function()
        ListTitle.Text = "Select Pet " .. State.MutasiActiveCategory .. " Team (Favorite List)"

        for _, c in ipairs(PetListScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end

        local pets = GetBackpackPets()
        local count = 0

        -- Update status counter untuk seluruh 6 kategori
        local cEle, cMac, cNM, c100, cXP, cGBXP = 0, 0, 0, 0, 0, 0
        for _, p in ipairs(pets) do
            local pNameLow = p.Name:lower()
            local mLow = p.Mutation:lower()
            if pNameLow:find("elephant") or mLow:find("elephant") then cEle = cEle + 1 end
            if pNameLow:find("machine") or mLow:find("machine") or mLow:find("mechanic") then cMac = cMac + 1 end
            if mLow:find("nightmare") or mLow:find("mutasi") then cNM = cNM + 1 end
            if p.Age >= 100 then c100 = c100 + 1 end
            if mLow:find("xp") and not mLow:find("gbxp") then cXP = cXP + 1 end
            if mLow:find("gbxp") then cGBXP = cGBXP + 1 end
        end
        statEle.Text  = "🐘 Elephant (" .. cEle .. ")"
        statMac.Text  = "⚙️ Machine (" .. cMac .. ")"
        statNM.Text   = "🌙 Nightmare (" .. cNM .. ")"
        stat100.Text  = "💯 100 Age (" .. c100 .. ")"
        statXP.Text   = "📘 XP (" .. cXP .. ")"
        statGBXP.Text = "🧪 GBXP (" .. cGBXP .. ")"

        for _, pet in ipairs(pets) do
            count = count + 1
            local isSelected = State.MutasiSelectedPets[pet.UUID] or false
            local displayText = string.format("[%s] %s | Age %s | %.2f KG", pet.Mutation, pet.Name, tostring(pet.Age), pet.Weight)

            local itemBtn = Instance.new("TextButton", PetListScroll)
            itemBtn.Size = UDim2.new(1, 0, 0, 26)
            itemBtn.BackgroundColor3 = isSelected and Color3.fromRGB(68, 28, 115) or Color3.fromRGB(15, 19, 36)
            itemBtn.Text = displayText
            itemBtn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 225, 245)
            itemBtn.Font = Enum.Font.GothamBold
            itemBtn.TextSize = 8.5
            itemBtn.TextXAlignment = Enum.TextXAlignment.Center
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

            local iStroke = Instance.new("UIStroke", itemBtn)
            iStroke.Color = isSelected and C.PURPLE_L or Color3.fromRGB(35, 42, 65)
            iStroke.Thickness = isSelected and 1.5 or 1

            itemBtn.MouseButton1Click:Connect(function()
                State.MutasiSelectedPets[pet.UUID] = not State.MutasiSelectedPets[pet.UUID]
                refreshPetList()
            end)
        end

        if count == 0 then
            local empty = Instance.new("TextLabel", PetListScroll)
            empty.Size = UDim2.new(1, 0, 1, 0)
            empty.BackgroundTransparency = 1
            empty.Text = "Belum ada pet murni terdeteksi di Backpack / Karakter."
            empty.TextColor3 = C.TEXT_M
            empty.Font = Enum.Font.GothamMedium
            empty.TextSize = 8.5
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        else
            PetListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 30 + 12)
        end
    end

    task.defer(refreshPetList)

    -- =====================================================================
    -- 6. BOTTOM ACTION BUTTONS: [ ⚡ START ] [ STOP ] [ Mode: A ▾ ]
    -- =====================================================================
    local ActionRow = Instance.new("Frame", MutasiWrapper)
    ActionRow.Size = UDim2.new(1, 0, 0, 32)
    ActionRow.BackgroundTransparency = 1
    ActionRow.LayoutOrder = 6

    local ActLayout = Instance.new("UIListLayout", ActionRow)
    ActLayout.FillDirection = Enum.FillDirection.Horizontal
    ActLayout.Padding = UDim.new(0, 8)
    ActLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    ActLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Tombol 1: START Action (Hanya "⚡ START")
    local StartBtn = Instance.new("TextButton", ActionRow)
    StartBtn.Size = UDim2.new(0.42, -5, 0, 30)
    StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StartBtn.Text = "⚡ START"
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 9.5
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 15)
    local startStroke = Instance.new("UIStroke", StartBtn)
    startStroke.Color = C.PURPLE
    startStroke.Thickness = 1.5

    updateActionButton = function()
        if not State.MutasiRunning then
            StartBtn.Text = "⚡ START"
        end
    end

    -- Tombol 2: STOP Action (Hanya "STOP")
    local StopBtn = Instance.new("TextButton", ActionRow)
    StopBtn.Size = UDim2.new(0.34, -5, 0, 30)
    StopBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StopBtn.Text = "STOP"
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 9.5
    Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 15)
    local stopStroke = Instance.new("UIStroke", StopBtn)
    stopStroke.Color = Color3.fromRGB(50, 58, 88)
    stopStroke.Thickness = 1.5

    -- Tombol 3: Mode Button dengan Indikator Dropdown (Tampilkan / Sembunyikan)
    local ModeBtn = Instance.new("TextButton", ActionRow)
    ModeBtn.Size = UDim2.new(0.24, -5, 0, 30)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    ModeBtn.Text = State.MutasiMode .. " ▾"
    ModeBtn.TextColor3 = C.CYAN
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 9
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 15)
    local modeStroke = Instance.new("UIStroke", ModeBtn)
    modeStroke.Color = Color3.fromRGB(50, 58, 88)
    modeStroke.Thickness = 1.5

    -- =====================================================================
    -- 7. MODAL POPUP: PILIHAN MODE PIPELINE (HIDE & TAMPILKAN)
    -- Mode A s/d Mode F Lengkap dengan Rute Alur & Penjelasan
    -- Diletakkan mengambang (ZIndex tinggi) tepat di atas area pet list
    -- =====================================================================
    local ModePopup = Instance.new("Frame", ParentContainer)
    ModePopup.Size = UDim2.new(1, 0, 0, 235)
    ModePopup.Position = UDim2.new(0, 0, 1, -268)
    ModePopup.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    ModePopup.BorderSizePixel = 0
    ModePopup.ZIndex = 40
    ModePopup.Visible = false
    Instance.new("UICorner", ModePopup).CornerRadius = UDim.new(0, 8)
    local mpStroke = Instance.new("UIStroke", ModePopup)
    mpStroke.Color = C.PURPLE
    mpStroke.Thickness = 1.5

    -- Header Modal Popup
    local MpHeader = Instance.new("Frame", ModePopup)
    MpHeader.Size = UDim2.new(1, 0, 0, 28)
    MpHeader.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
    MpHeader.BorderSizePixel = 0
    MpHeader.ZIndex = 41
    Instance.new("UICorner", MpHeader).CornerRadius = UDim.new(0, 8)

    local MpTitle = Instance.new("TextLabel", MpHeader)
    MpTitle.Position = UDim2.new(0, 10, 0, 0)
    MpTitle.Size = UDim2.new(1, -40, 1, 0)
    MpTitle.BackgroundTransparency = 1
    MpTitle.Text = "PILIH MODE PIPELINE MUTASI"
    MpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MpTitle.Font = Enum.Font.GothamBold
    MpTitle.TextSize = 9.5
    MpTitle.TextXAlignment = Enum.TextXAlignment.Left
    MpTitle.ZIndex = 42

    local MpClose = Instance.new("TextButton", MpHeader)
    MpClose.Position = UDim2.new(1, -26, 0.5, -10)
    MpClose.Size = UDim2.new(0, 20, 0, 20)
    MpClose.BackgroundColor3 = Color3.fromRGB(28, 20, 36)
    MpClose.Text = "✕"
    MpClose.TextColor3 = Color3.fromRGB(220, 180, 255)
    MpClose.Font = Enum.Font.GothamBold
    MpClose.TextSize = 10
    MpClose.ZIndex = 42
    Instance.new("UICorner", MpClose).CornerRadius = UDim.new(0, 10)

    -- Scrollable List Pilihan Mode
    local MpScroll = Instance.new("ScrollingFrame", ModePopup)
    MpScroll.Position = UDim2.new(0, 6, 0, 32)
    MpScroll.Size = UDim2.new(1, -12, 1, -38)
    MpScroll.BackgroundTransparency = 1
    MpScroll.BorderSizePixel = 0
    MpScroll.ScrollBarThickness = 3
    MpScroll.ScrollBarImageColor3 = C.PURPLE
    MpScroll.ZIndex = 41
    MpScroll.CanvasSize = UDim2.new(0, 0, 0, 290)

    local MpList = Instance.new("UIListLayout", MpScroll)
    MpList.SortOrder = Enum.SortOrder.LayoutOrder
    MpList.Padding = UDim.new(0, 5)

    local PipelineModes = {
        {
            id = "Mode: A",
            letter = "MODE A",
            route = "GBXP > XP > 100 AGE > INVENTORY FAVORIT",
            desc = "Khusus nge-push pet agar cepat menyentuh Age 100–500.",
            order = 1
        },
        {
            id = "Mode: B",
            letter = "MODE B",
            route = "GBXP > XP > NIGHTMARE > INVENTORY FAVORIT",
            desc = "Khusus pet yang hanya diincar mutasinya secara cepat via skill pet.",
            order = 2
        },
        {
            id = "Mode: C",
            letter = "MODE C",
            route = "GBXP > XP > MACHINE > INVENTORY FAVORIT",
            desc = "Khusus pet yang hanya diincar mutasinya secara cepat via mesin mutasi.",
            order = 3
        },
        {
            id = "Mode: D",
            letter = "MODE D",
            route = "GBXP > XP > ELEPHANT > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet (Base max + Age tinggi).",
            order = 4
        },
        {
            id = "Mode: E",
            letter = "MODE E",
            route = "GBXP > XP > ELEPHANT > NIGHTMARE > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet sempurna dari nol (Base max + Mutasi Skill + Age tinggi).",
            order = 5
        },
        {
            id = "Mode: F",
            letter = "MODE F",
            route = "GBXP > XP > ELEPHANT > MACHINE > 100 AGE > INVENTORY FAVORIT",
            desc = "Membangun pet sempurna dari nol (Base max + Mutasi Mesin + Age tinggi).",
            order = 6
        }
    }

    local ModeItemElements = {}

    local function updateModeSelectionUI()
        ModeBtn.Text = State.MutasiMode .. (ModePopup.Visible and " ▴" or " ▾")
        for mId, elem in pairs(ModeItemElements) do
            local isSelected = (State.MutasiMode == mId)
            elem.btn.BackgroundColor3 = isSelected and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
            elem.stroke.Color = isSelected and C.PURPLE or Color3.fromRGB(38, 45, 70)
            elem.stroke.Thickness = isSelected and 1.5 or 1
            elem.title.TextColor3 = isSelected and C.PURPLE_L or C.TEXT_W
            elem.check.Visible = isSelected
        end
    end

    for _, m in ipairs(PipelineModes) do
        local mBtn = Instance.new("TextButton", MpScroll)
        mBtn.Size = UDim2.new(1, -4, 0, 42)
        mBtn.BackgroundColor3 = (State.MutasiMode == m.id) and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
        mBtn.Text = ""
        mBtn.AutoButtonColor = false
        mBtn.LayoutOrder = m.order
        mBtn.ZIndex = 42
        Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0, 6)
        local mStroke = Instance.new("UIStroke", mBtn)
        mStroke.Color = (State.MutasiMode == m.id) and C.PURPLE or Color3.fromRGB(38, 45, 70)
        mStroke.Thickness = (State.MutasiMode == m.id) and 1.5 or 1

        -- Judul Mode
        local mLblTitle = Instance.new("TextLabel", mBtn)
        mLblTitle.Position = UDim2.new(0, 8, 0, 3)
        mLblTitle.Size = UDim2.new(1, -40, 0, 13)
        mLblTitle.BackgroundTransparency = 1
        mLblTitle.Text = m.letter .. ": (" .. m.route .. ")"
        mLblTitle.TextColor3 = (State.MutasiMode == m.id) and C.PURPLE_L or C.TEXT_W
        mLblTitle.Font = Enum.Font.GothamBold
        mLblTitle.TextSize = 8.5
        mLblTitle.TextXAlignment = Enum.TextXAlignment.Left
        mLblTitle.ZIndex = 43

        -- Deskripsi Mode
        local mLblDesc = Instance.new("TextLabel", mBtn)
        mLblDesc.Position = UDim2.new(0, 8, 0, 18)
        mLblDesc.Size = UDim2.new(1, -40, 0, 20)
        mLblDesc.BackgroundTransparency = 1
        mLblDesc.Text = m.desc
        mLblDesc.TextColor3 = C.TEXT_M
        mLblDesc.Font = Enum.Font.GothamMedium
        mLblDesc.TextSize = 8
        mLblDesc.TextWrapped = true
        mLblDesc.TextXAlignment = Enum.TextXAlignment.Left
        mLblDesc.TextYAlignment = Enum.TextYAlignment.Top
        mLblDesc.ZIndex = 43

        -- Badge Checkmark
        local mCheck = Instance.new("TextLabel", mBtn)
        mCheck.Position = UDim2.new(1, -24, 0.5, -8)
        mCheck.Size = UDim2.new(0, 16, 0, 16)
        mCheck.BackgroundTransparency = 1
        mCheck.Text = "✓"
        mCheck.TextColor3 = C.CYAN
        mCheck.Font = Enum.Font.GothamBold
        mCheck.TextSize = 11
        mCheck.Visible = (State.MutasiMode == m.id)
        mCheck.ZIndex = 43

        ModeItemElements[m.id] = {
            btn = mBtn,
            stroke = mStroke,
            title = mLblTitle,
            check = mCheck
        }

        mBtn.MouseButton1Click:Connect(function()
            State.MutasiMode = m.id
            ModePopup.Visible = false
            updateModeSelectionUI()
            print("[ZyloHub] Mode dipilih: " .. m.letter .. " - " .. m.desc)
        end)
    end

    -- Toggle Tampilkan / Sembunyikan Popup Modal
    ModeBtn.MouseButton1Click:Connect(function()
        ModePopup.Visible = not ModePopup.Visible
        updateModeSelectionUI()
    end)

    MpClose.MouseButton1Click:Connect(function()
        ModePopup.Visible = false
        updateModeSelectionUI()
    end)

    StartBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = true
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        StartBtn.Text = "RUNNING (" .. State.MutasiMode .. ")"
        print("[ZyloHub] Auto Mutasi started: " .. State.MutasiActiveCategory .. " [" .. State.MutasiMode .. "]")
    end)

    StopBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = false
        StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
        StartBtn.Text = "⚡ START"
        print("[ZyloHub] Auto Mutasi stopped")
    end)

    return {
        Refresh = refreshPetList,
        Wrapper = MutasiWrapper
    }
end
