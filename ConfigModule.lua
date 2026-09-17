-- =========================================================================
--  ZYLOHUB - CONFIG MANAGER MODULE (v1.0 - PER-DEVICE PERSISTENCE)
--  Repository: zylo-games/ConfigModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Features: Save, Load, Set Auto Load, Delete, Dropdown Profil, Auto Startup
-- =========================================================================

return function(ParentContainer, State, ZyloLib, Main)
    local HttpService = game:GetService("HttpService")
    local C = ZyloLib.Colors

    -- 1. FOLDER SYSTEM CHECK (PER-DEVICE STORAGE)
    local CONFIG_FOLDER = "ZyloHub"
    local CONFIGS_PATH = "ZyloHub/Configs"
    local AUTOLOAD_FILE = "ZyloHub/Configs/autoload.txt"

    local function SafeMakeFolder(path)
        if makefolder and isfolder then
            if not isfolder(path) then
                pcall(function() makefolder(path) end)
            end
        end
    end

    SafeMakeFolder(CONFIG_FOLDER)
    SafeMakeFolder(CONFIGS_PATH)

    -- 2. HELPER BACA & TULIS FILE EXECUTOR
    local function GetSavedConfigFiles()
        local files = {}
        if listfiles and isfolder and isfolder(CONFIGS_PATH) then
            local ok, list = pcall(function() return listfiles(CONFIGS_PATH) end)
            if ok and list then
                for _, fullPath in ipairs(list) do
                    local fileName = fullPath:match("([^/\\]+)%.json$")
                    if fileName then
                        table.insert(files, fileName)
                    end
                end
            end
        end
        if #files == 0 then
            table.insert(files, "Default")
        end
        return files
    end

    local currentConfigName = "Default"
    local isAutoLoadEnabled = false

    if isfile and isfile(AUTOLOAD_FILE) then
        local ok, target = pcall(function() return readfile(AUTOLOAD_FILE) end)
        if ok and target and target ~= "" then
            currentConfigName = target:gsub("%s+", "")
            isAutoLoadEnabled = true
        end
    end

    -- 3. FUNGSI SAVE CONFIG (MENYIMPAN SELURUH ISI STATE)
    local function SaveConfigToFile(configName)
        if not writefile then return false, "Executor tidak mendukung fungsi writefile" end
        configName = (configName and configName ~= "") and configName or "Default"
        SafeMakeFolder(CONFIGS_PATH)

        -- Kloning data yang dapat diserialisasi dari State
        local dataToSave = {}
        for k, v in pairs(State) do
            local t = type(v)
            if t == "string" or t == "number" or t == "boolean" or t == "table" then
                dataToSave[k] = v
            end
        end

        local jsonString = ""
        local okEncode, errEncode = pcall(function()
            jsonString = HttpService:JSONEncode(dataToSave)
        end)
        if not okEncode then return false, "JSON Encode Error: " .. tostring(errEncode) end

        local filePath = CONFIGS_PATH .. "/" .. configName .. ".json"
        local okWrite, errWrite = pcall(function()
            writefile(filePath, jsonString)
        end)
        if not okWrite then return false, "Gagal menulis file: " .. tostring(errWrite) end

        return true, filePath
    end

    -- 4. FUNGSI LOAD CONFIG (MEMULIHKAN SELURUH ISI STATE)
    local function LoadConfigFromFile(configName)
        if not readfile or not isfile then return false, "Executor tidak mendukung readfile/isfile" end
        configName = (configName and configName ~= "") and configName or "Default"
        local filePath = CONFIGS_PATH .. "/" .. configName .. ".json"

        if not isfile(filePath) then
            return false, "File konfigurasi '" .. configName .. "' tidak ditemukan."
        end

        local content = ""
        local okRead, errRead = pcall(function()
            content = readfile(filePath)
        end)
        if not okRead or content == "" then return false, "Gagal membaca isi file: " .. tostring(errRead) end

        local decoded = nil
        local okDecode, errDecode = pcall(function()
            decoded = HttpService:JSONDecode(content)
        end)
        if not okDecode or type(decoded) ~= "table" then
            return false, "Format file JSON korup: " .. tostring(errDecode)
        end

        -- Terapkan kembali ke dalam tabel State global
        for k, v in pairs(decoded) do
            State[k] = v
        end

        return true, decoded
    end

    -- 5. FUNGSI DELETE CONFIG
    local function DeleteConfigFile(configName)
        if not delfile or not isfile then return false, "Executor tidak mendukung delfile/isfile" end
        configName = (configName and configName ~= "") and configName or "Default"
        local filePath = CONFIGS_PATH .. "/" .. configName .. ".json"

        if not isfile(filePath) then
            return false, "File tidak ditemukan."
        end

        local ok, err = pcall(function() delfile(filePath) end)
        if not ok then return false, tostring(err) end

        -- Jika file yang dihapus sedang jadi autoload, bersihkan autoload.txt
        if isfile(AUTOLOAD_FILE) then
            local curAuto = readfile(AUTOLOAD_FILE)
            if curAuto and curAuto:find(configName) then
                pcall(function() delfile(AUTOLOAD_FILE) end)
            end
        end

        return true
    end

    -- =====================================================================
    -- MEMBANGUN TAMPILAN UI (SESUAI GAMBAR REFERENSI ANDA)
    -- =====================================================================
    local ConfigWrapper = Instance.new("Frame", ParentContainer)
    ConfigWrapper.Size = UDim2.new(1, 0, 0, 480)
    ConfigWrapper.BackgroundTransparency = 1

    local CwLayout = Instance.new("UIListLayout", ConfigWrapper)
    CwLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CwLayout.Padding = UDim.new(0, 8)

    -- Header Title
    local HeaderLabel = Instance.new("TextLabel", ConfigWrapper)
    HeaderLabel.Size = UDim2.new(1, 0, 0, 24)
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Text = "Config"
    HeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    HeaderLabel.Font = Enum.Font.GothamBold
    HeaderLabel.TextSize = 16
    HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
    HeaderLabel.LayoutOrder = 1

    -- Card Container Utama
    local CardFrame = Instance.new("Frame", ConfigWrapper)
    CardFrame.Size = UDim2.new(1, 0, 0, 390)
    CardFrame.BackgroundColor3 = Color3.fromRGB(11, 14, 28)
    CardFrame.LayoutOrder = 2
    Instance.new("UICorner", CardFrame).CornerRadius = UDim.new(0, 10)
    local cardStroke = Instance.new("UIStroke", CardFrame)
    cardStroke.Color = Color3.fromRGB(36, 44, 72)

    local CardLayout = Instance.new("UIListLayout", CardFrame)
    CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CardLayout.Padding = UDim.new(0, 6)
    local CardPad = Instance.new("UIPadding", CardFrame)
    CardPad.PaddingTop = UDim.new(0, 8)
    CardPad.PaddingBottom = UDim.new(0, 8)
    CardPad.PaddingLeft = UDim.new(0, 12)
    CardPad.PaddingRight = UDim.new(0, 12)

    -- Header Panel Accordion
    local PanelHeader = Instance.new("Frame", CardFrame)
    PanelHeader.Size = UDim2.new(1, 0, 0, 28)
    PanelHeader.BackgroundTransparency = 1
    PanelHeader.LayoutOrder = 1

    local PhTitle = Instance.new("TextLabel", PanelHeader)
    PhTitle.Position = UDim2.new(0, 0, 0, 0)
    PhTitle.Size = UDim2.new(1, -30, 1, 0)
    PhTitle.BackgroundTransparency = 1
    PhTitle.Text = "Config Panel"
    PhTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    PhTitle.Font = Enum.Font.GothamBold
    PhTitle.TextSize = 12
    PhTitle.TextXAlignment = Enum.TextXAlignment.Left

    local PhArrow = Instance.new("TextLabel", PanelHeader)
    PhArrow.Position = UDim2.new(1, -20, 0, 0)
    PhArrow.Size = UDim2.new(0, 20, 1, 0)
    PhArrow.BackgroundTransparency = 1
    PhArrow.Text = "v"
    PhArrow.TextColor3 = C.PURPLE_L
    PhArrow.Font = Enum.Font.GothamBold
    PhArrow.TextSize = 11

    -- Garis Aksen Ungu Menyala (Glowing Purple Accent Line)
    local AccentLine = Instance.new("Frame", CardFrame)
    AccentLine.Size = UDim2.new(1, 0, 0, 2)
    AccentLine.BackgroundColor3 = C.PURPLE
    AccentLine.BorderSizePixel = 0
    AccentLine.LayoutOrder = 2

    -- Deskripsi Settings
    local DescBox = Instance.new("Frame", CardFrame)
    DescBox.Size = UDim2.new(1, 0, 0, 48)
    DescBox.BackgroundTransparency = 1
    DescBox.LayoutOrder = 3

    local DescTitle = Instance.new("TextLabel", DescBox)
    DescTitle.Position = UDim2.new(0, 0, 0, 2)
    DescTitle.Size = UDim2.new(1, 0, 0, 14)
    DescTitle.BackgroundTransparency = 1
    DescTitle.Text = "Settings"
    DescTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    DescTitle.Font = Enum.Font.GothamBold
    DescTitle.TextSize = 10
    DescTitle.TextXAlignment = Enum.TextXAlignment.Left

    local DescText = Instance.new("TextLabel", DescBox)
    DescText.Position = UDim2.new(0, 0, 0, 18)
    DescText.Size = UDim2.new(1, 0, 0, 28)
    DescText.BackgroundTransparency = 1
    DescText.Text = "Save, load, delete and auto-load every toggle, slider, dropdown and box in the script. Turn on Auto Load and that config comes back on its own next time you run it."
    DescText.TextColor3 = Color3.fromRGB(120, 132, 165)
    DescText.Font = Enum.Font.GothamMedium
    DescText.TextSize = 8.5
    DescText.TextWrapped = true
    DescText.TextXAlignment = Enum.TextXAlignment.Left
    DescText.TextYAlignment = Enum.TextYAlignment.Top

    -- Row 1: Config Name
    local RowName = Instance.new("Frame", CardFrame)
    RowName.Size = UDim2.new(1, 0, 0, 42)
    RowName.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    RowName.LayoutOrder = 4
    Instance.new("UICorner", RowName).CornerRadius = UDim.new(0, 6)
    local rnStroke = Instance.new("UIStroke", RowName)
    rnStroke.Color = Color3.fromRGB(36, 44, 70)

    local RnTitle = Instance.new("TextLabel", RowName)
    RnTitle.Position = UDim2.new(0, 10, 0, 4)
    RnTitle.Size = UDim2.new(0.5, 0, 0, 14)
    RnTitle.BackgroundTransparency = 1
    RnTitle.Text = "Config Name"
    RnTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    RnTitle.Font = Enum.Font.GothamBold
    RnTitle.TextSize = 9.5
    RnTitle.TextXAlignment = Enum.TextXAlignment.Left

    local RnSub = Instance.new("TextLabel", RowName)
    RnSub.Position = UDim2.new(0, 10, 0, 20)
    RnSub.Size = UDim2.new(0.5, 0, 0, 14)
    RnSub.BackgroundTransparency = 1
    RnSub.Text = "Type a name for the config"
    RnSub.TextColor3 = Color3.fromRGB(120, 132, 165)
    RnSub.Font = Enum.Font.GothamMedium
    RnSub.TextSize = 8
    RnSub.TextXAlignment = Enum.TextXAlignment.Left

    local NameInput = Instance.new("TextBox", RowName)
    NameInput.Position = UDim2.new(1, -145, 0.5, -13)
    NameInput.Size = UDim2.new(0, 135, 0, 26)
    NameInput.BackgroundColor3 = Color3.fromRGB(20, 24, 48)
    NameInput.Text = currentConfigName
    NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameInput.Font = Enum.Font.GothamBold
    NameInput.TextSize = 9
    NameInput.ClearTextOnFocus = false
    Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)
    local niStroke = Instance.new("UIStroke", NameInput)
    niStroke.Color = Color3.fromRGB(48, 58, 90)

    NameInput:GetPropertyChangedSignal("Text"):Connect(function()
        currentConfigName = NameInput.Text
    end)

    -- Row 2: Saved Configs (Dropdown)
    local RowSaved = Instance.new("Frame", CardFrame)
    RowSaved.Size = UDim2.new(1, 0, 0, 42)
    RowSaved.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    RowSaved.LayoutOrder = 5
    Instance.new("UICorner", RowSaved).CornerRadius = UDim.new(0, 6)
    local rsStroke = Instance.new("UIStroke", RowSaved)
    rsStroke.Color = Color3.fromRGB(36, 44, 70)

    local RsTitle = Instance.new("TextLabel", RowSaved)
    RsTitle.Position = UDim2.new(0, 10, 0, 4)
    RsTitle.Size = UDim2.new(0.5, 0, 0, 14)
    RsTitle.BackgroundTransparency = 1
    RsTitle.Text = "Saved Configs"
    RsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    RsTitle.Font = Enum.Font.GothamBold
    RsTitle.TextSize = 9.5
    RsTitle.TextXAlignment = Enum.TextXAlignment.Left

    local RsSub = Instance.new("TextLabel", RowSaved)
    RsSub.Position = UDim2.new(0, 10, 0, 20)
    RsSub.Size = UDim2.new(0.5, 0, 0, 14)
    RsSub.BackgroundTransparency = 1
    RsSub.Text = "Select a saved config"
    RsSub.TextColor3 = Color3.fromRGB(120, 132, 165)
    RsSub.Font = Enum.Font.GothamMedium
    RsSub.TextSize = 8
    RsSub.TextXAlignment = Enum.TextXAlignment.Left

    local SavedDropdownBtn = Instance.new("TextButton", RowSaved)
    SavedDropdownBtn.Position = UDim2.new(1, -145, 0.5, -13)
    SavedDropdownBtn.Size = UDim2.new(0, 135, 0, 26)
    SavedDropdownBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 48)
    SavedDropdownBtn.Text = currentConfigName .. "  v"
    SavedDropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SavedDropdownBtn.Font = Enum.Font.GothamBold
    SavedDropdownBtn.TextSize = 9
    Instance.new("UICorner", SavedDropdownBtn).CornerRadius = UDim.new(0, 6)
    local sdbStroke = Instance.new("UIStroke", SavedDropdownBtn)
    sdbStroke.Color = Color3.fromRGB(48, 58, 90)

    -- Dropdown List Menu
    local DropListFrame = Instance.new("Frame", Main)
    DropListFrame.Size = UDim2.new(0, 145, 0, 120)
    DropListFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 40)
    DropListFrame.Visible = false
    DropListFrame.ZIndex = 60
    Instance.new("UICorner", DropListFrame).CornerRadius = UDim.new(0, 6)
    local dlfStroke = Instance.new("UIStroke", DropListFrame)
    dlfStroke.Color = C.PURPLE
    dlfStroke.Thickness = 1.5

    local DropScroll = Instance.new("ScrollingFrame", DropListFrame)
    DropScroll.Size = UDim2.new(1, 0, 1, 0)
    DropScroll.BackgroundTransparency = 1
    DropScroll.ScrollBarThickness = 2
    DropScroll.ZIndex = 61
    local DropLayout = Instance.new("UIListLayout", DropScroll)
    DropLayout.Padding = UDim.new(0, 2)
    Instance.new("UIPadding", DropScroll).PaddingTop = UDim.new(0, 4)

    local function RefreshSavedList()
        for _, c in ipairs(DropScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        local fileList = GetSavedConfigFiles()
        for _, fName in ipairs(fileList) do
            local b = Instance.new("TextButton", DropScroll)
            b.Size = UDim2.new(1, -6, 0, 24)
            b.Position = UDim2.new(0, 3, 0, 0)
            b.BackgroundColor3 = (currentConfigName == fName) and Color3.fromRGB(56, 24, 90) or Color3.fromRGB(22, 26, 50)
            b.Text = "  " .. fName
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.Font.GothamMedium
            b.TextSize = 8.5
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.ZIndex = 62
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

            b.MouseButton1Click:Connect(function()
                currentConfigName = fName
                NameInput.Text = fName
                SavedDropdownBtn.Text = fName .. "  v"
                DropListFrame.Visible = false
            end)
        end
        DropScroll.CanvasSize = UDim2.new(0, 0, 0, #fileList * 26 + 8)
    end

    SavedDropdownBtn.MouseButton1Click:Connect(function()
        RefreshSavedList()
        local abs = SavedDropdownBtn.AbsolutePosition
        local mainAbs = Main.AbsolutePosition
        DropListFrame.Position = UDim2.new(0, abs.X - mainAbs.X, 0, abs.Y - mainAbs.Y + 30)
        DropListFrame.Visible = not DropListFrame.Visible
    end)

    -- Row 3: Auto Load (Pill Switch)
    local RowAuto = Instance.new("Frame", CardFrame)
    RowAuto.Size = UDim2.new(1, 0, 0, 42)
    RowAuto.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    RowAuto.LayoutOrder = 6
    Instance.new("UICorner", RowAuto).CornerRadius = UDim.new(0, 6)
    local raStroke = Instance.new("UIStroke", RowAuto)
    raStroke.Color = Color3.fromRGB(36, 44, 70)

    local RaTitle = Instance.new("TextLabel", RowAuto)
    RaTitle.Position = UDim2.new(0, 10, 0, 4)
    RaTitle.Size = UDim2.new(0.7, 0, 0, 14)
    RaTitle.BackgroundTransparency = 1
    RaTitle.Text = "Auto Load"
    RaTitle.TextColor3 = C.PURPLE_L
    RaTitle.Font = Enum.Font.GothamBold
    RaTitle.TextSize = 9.5
    RaTitle.TextXAlignment = Enum.TextXAlignment.Left

    local RaSub = Instance.new("TextLabel", RowAuto)
    RaSub.Position = UDim2.new(0, 10, 0, 20)
    RaSub.Size = UDim2.new(0.7, 0, 0, 14)
    RaSub.BackgroundTransparency = 1
    RaSub.Text = "Load this config automatically on startup"
    RaSub.TextColor3 = Color3.fromRGB(120, 132, 165)
    RaSub.Font = Enum.Font.GothamMedium
    RaSub.TextSize = 8
    RaSub.TextXAlignment = Enum.TextXAlignment.Left

    local AutoLoadSwitch = ZyloLib:CreatePillSwitch(RowAuto, isAutoLoadEnabled, function(val)
        isAutoLoadEnabled = val
        if val then
            if writefile then
                pcall(function() writefile(AUTOLOAD_FILE, currentConfigName) end)
            end
        else
            if delfile and isfile and isfile(AUTOLOAD_FILE) then
                pcall(function() delfile(AUTOLOAD_FILE) end)
            end
        end
    end)
    AutoLoadSwitch.Position = UDim2.new(1, -48, 0.5, -10)

    -- Status Notification Text
    local StatusInfo = Instance.new("TextLabel", CardFrame)
    StatusInfo.Size = UDim2.new(1, 0, 0, 16)
    StatusInfo.BackgroundTransparency = 1
    StatusInfo.Text = "Status: Siap."
    StatusInfo.TextColor3 = C.CYAN
    StatusInfo.Font = Enum.Font.GothamMedium
    StatusInfo.TextSize = 8.5
    StatusInfo.TextXAlignment = Enum.TextXAlignment.Left
    StatusInfo.LayoutOrder = 7

    local function Notify(msg, isErr)
        StatusInfo.Text = "Status: " .. msg
        StatusInfo.TextColor3 = isErr and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(0, 255, 170)
        task.delay(4, function()
            if StatusInfo and StatusInfo.Parent then
                StatusInfo.Text = "Status: Siap."
                StatusInfo.TextColor3 = C.CYAN
            end
        end)
    end

    -- =====================================================================
    -- 4 TOMBOL AKSI LENGKAP
    -- =====================================================================
    local function CreateActionButton(text, order, callback)
        local btn = Instance.new("TextButton", CardFrame)
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Color3.fromRGB(18, 22, 42)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(245, 247, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9.5
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", btn)
        bStroke.Color = Color3.fromRGB(42, 50, 80)

        btn.MouseButton1Click:Connect(function()
            callback(btn)
        end)
        return btn
    end

    -- 1. SAVE CONFIG
    CreateActionButton("Save Config", 8, function()
        local targetName = (NameInput.Text ~= "") and NameInput.Text or "Default"
        local ok, res = SaveConfigToFile(targetName)
        if ok then
            currentConfigName = targetName
            SavedDropdownBtn.Text = targetName .. "  v"
            Notify("✓ Config '" .. targetName .. "' berhasil disimpan ke perangkat!", false)
        else
            Notify("Gagal Simpan: " .. tostring(res), true)
        end
    end)

    -- 2. LOAD CONFIG
    CreateActionButton("Load Config", 9, function()
        local targetName = currentConfigName or "Default"
        local ok, res = LoadConfigFromFile(targetName)
        if ok then
            Notify("✓ Config '" .. targetName .. "' berhasil dimuat!", false)
        else
            Notify("Gagal Muat: " .. tostring(res), true)
        end
    end)

    -- 3. SET AS AUTO LOAD
    CreateActionButton("Set as Auto Load", 10, function()
        local targetName = currentConfigName or "Default"
        SaveConfigToFile(targetName)
        if writefile then
            pcall(function() writefile(AUTOLOAD_FILE, targetName) end)
            isAutoLoadEnabled = true
            Notify("✓ Config '" .. targetName .. "' ditetapkan sebagai Auto Load!", false)
        else
            Notify("Executor tidak mendukung writefile.", true)
        end
    end)

    -- 4. DELETE CONFIG
    CreateActionButton("Delete Config", 11, function()
        local targetName = currentConfigName or "Default"
        local ok, err = DeleteConfigFile(targetName)
        if ok then
            Notify("✓ Config '" .. targetName .. "' berhasil dihapus.", false)
            currentConfigName = "Default"
            NameInput.Text = "Default"
            SavedDropdownBtn.Text = "Default  v"
        else
            Notify("Gagal Hapus: " .. tostring(err), true)
        end
    end)

    -- =====================================================================
    -- AUTO STARTUP LOADER (MEMUAT OTOMATIS SAAT GAME SELESAI LOADING)
    -- =====================================================================
    task.spawn(function()
        if isfile and isfile(AUTOLOAD_FILE) then
            local ok, autoTarget = pcall(function() return readfile(AUTOLOAD_FILE) end)
            if ok and autoTarget and autoTarget ~= "" then
                autoTarget = autoTarget:gsub("%s+", "")
                task.wait(3) -- Safety check agar map dan game stabil
                local okLoad = LoadConfigFromFile(autoTarget)
                if okLoad then
                    Notify("✓ Startup: Auto Load '" .. autoTarget .. "' berhasil diaktifkan.", false)
                end
            end
        end
    end)

    return {
        Save = SaveConfigToFile,
        Load = LoadConfigFromFile,
        Wrapper = ConfigWrapper
    }
end
