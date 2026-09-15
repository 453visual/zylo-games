-- =========================================================================
--  ZYLOHUB - AUTO MUTASI MODULE (OFFICIAL EXTENSION v3.6)
--  Repository: zylo-games/PetMutasiModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Tabs: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config
--  Presisi 100% Sesuai Screenshot Referensi (Tanpa Warna Kuning)
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
    -- 1. SUB-NAVIGASI KATEGORI (HORIZONTAL SCROLLING PILLS)
    -- Urutan: Elephant > Machine > Nightmare > 100 Age > XP > GBXP > Config + ⚙
    -- =====================================================================
    local NavScroll = Instance.new("ScrollingFrame", MutasiWrapper)
    NavScroll.Size = UDim2.new(1, 0, 0, 30)
    NavScroll.BackgroundTransparency = 1
    NavScroll.ScrollBarThickness = 0
    NavScroll.ScrollingDirection = Enum.ScrollingDirection.Horizontal
    NavScroll.LayoutOrder = 1

    local NavList = Instance.new("UIListLayout", NavScroll)
    NavList.FillDirection = Enum.FillDirection.Horizontal
    NavList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    NavList.VerticalAlignment = Enum.VerticalAlignment.Center
    NavList.Padding = UDim.new(0, 6)

    local Categories = { "Elephant", "Machine", "Nightmare", "100 Age", "XP", "GBXP", "Config" }
    local CategoryButtons = {}
    local updateThresholdTitle
    local updateActionButton
    local refreshPetList

    local totalNavWidth = 0
    for _, catName in ipairs(Categories) do
        local btnW = (catName == "Nightmare" and 76) or (catName == "Elephant" and 68) or (catName == "Machine" and 66) or (catName == "100 Age" and 64) or (catName == "Config" and 54) or 46
        totalNavWidth = totalNavWidth + btnW + 6

        local btn = Instance.new("TextButton", NavScroll)
        btn.Size = UDim2.new(0, btnW, 0, 26)
        btn.BackgroundColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(48, 24, 80) or Color3.fromRGB(15, 18, 34)
        btn.Text = catName
        btn.TextColor3 = (State.MutasiActiveCategory == catName) and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
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

    -- Tombol ⚙ (Settings Gear di Ujung Kanan)
    local GearBtn = Instance.new("TextButton", NavScroll)
    GearBtn.Size = UDim2.new(0, 26, 0, 26)
    GearBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 34)
    GearBtn.Text = "⚙"
    GearBtn.TextColor3 = C.TEXT_M
    GearBtn.Font = Enum.Font.GothamBold
    GearBtn.TextSize = 12
    Instance.new("UICorner", GearBtn).CornerRadius = UDim.new(0, 13)
    local gearStroke = Instance.new("UIStroke", GearBtn)
    gearStroke.Color = Color3.fromRGB(38, 45, 70)
    totalNavWidth = totalNavWidth + 32
    NavScroll.CanvasSize = UDim2.new(0, totalNavWidth + 10, 0, 0)

    GearBtn.MouseButton1Click:Connect(function()
        ZyloLib:Notify("Settings", "Pengaturan konfigurasi mutasi aktif.", 2)
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

    -- Row 3A: Inline Stats Row (Horizontal Scrollable agar muat 6 Counter Lengkap)
    local StatsScroll = Instance.new("ScrollingFrame", ThreshBody)
    StatsScroll.Size = UDim2.new(1, 0, 0, 22)
    StatsScroll.BackgroundTransparency = 1
    StatsScroll.ScrollBarThickness = 0
    StatsScroll.ScrollingDirection = Enum.ScrollingDirection.Horizontal
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
    StatsScroll.CanvasSize = UDim2.new(0, 480, 0, 0)

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

    -- Filter agar item consumable (treat, shard, reroller) tidak ikut masuk
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
        return tool:FindFirstChild("PetData") or (not tool:FindFirstChild("PetEggToolLocal"))
    end

    local function GetBackpackPets()
        local pets = {}
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
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

        -- Update status counter untuk semua kategori
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
            -- Tema ZyloHub: Deep Obsidian vs Cosmic Purple
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
    -- 6. BOTTOM ACTION BUTTONS: [ ⚡ START NM+LVL ] [ STOP NM+LVL ] [ Mode: A ]
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

    -- Tombol 1: START Action (Dinamis sesuai Tab Aktif)
    local StartBtn = Instance.new("TextButton", ActionRow)
    StartBtn.Size = UDim2.new(0.42, -5, 0, 30)
    StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StartBtn.Text = "⚡ START " .. State.MutasiActiveCategory:upper()
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 9
    Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 15)
    local startStroke = Instance.new("UIStroke", StartBtn)
    startStroke.Color = C.PURPLE
    startStroke.Thickness = 1.5

    updateActionButton = function()
        if not State.MutasiRunning then
            StartBtn.Text = "⚡ START " .. State.MutasiActiveCategory:upper()
        end
    end

    -- Tombol 2: STOP Action
    local StopBtn = Instance.new("TextButton", ActionRow)
    StopBtn.Size = UDim2.new(0.34, -5, 0, 30)
    StopBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    StopBtn.Text = "STOP " .. State.MutasiActiveCategory:upper()
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 9
    Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 15)
    local stopStroke = Instance.new("UIStroke", StopBtn)
    stopStroke.Color = Color3.fromRGB(50, 58, 88)
    stopStroke.Thickness = 1.5

    -- Tombol 3: Mode: A / Mode: B
    local ModeBtn = Instance.new("TextButton", ActionRow)
    ModeBtn.Size = UDim2.new(0.24, -5, 0, 30)
    ModeBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
    ModeBtn.Text = State.MutasiMode
    ModeBtn.TextColor3 = C.CYAN
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 9
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 15)
    local modeStroke = Instance.new("UIStroke", ModeBtn)
    modeStroke.Color = Color3.fromRGB(50, 58, 88)
    modeStroke.Thickness = 1.5

    ModeBtn.MouseButton1Click:Connect(function()
        if State.MutasiMode == "Mode: A" then
            State.MutasiMode = "Mode: B"
        else
            State.MutasiMode = "Mode: A"
        end
        ModeBtn.Text = State.MutasiMode
    end)

    StartBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = true
        StartBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        StartBtn.Text = "RUNNING (" .. State.MutasiMode .. ")"
        ZyloLib:Notify("Auto Mutasi", "Memulai proses " .. State.MutasiActiveCategory .. " (" .. State.MutasiMode .. ")", 2.5)
    end)

    StopBtn.MouseButton1Click:Connect(function()
        State.MutasiRunning = false
        StartBtn.BackgroundColor3 = Color3.fromRGB(15, 18, 36)
        StartBtn.Text = "⚡ START " .. State.MutasiActiveCategory:upper()
        ZyloLib:Notify("Auto Mutasi", "Proses " .. State.MutasiActiveCategory .. " dihentikan.", 2)
    end)

    return {
        Refresh = refreshPetList,
        Wrapper = MutasiWrapper
    }
end
