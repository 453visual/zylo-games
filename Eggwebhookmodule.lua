-- =========================================================================
--  ZYLOHUB - EGG WEBHOOK MODULE (OFFICIAL EXTENSION)
--  Repository: zylo-games/EggWebhookModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  Fungsi: Notifikasi Hatch Egg ke Discord Webhook (Mode Simple & Detail)
-- =========================================================================

local EggWebhookModule = {}

function EggWebhookModule.Init(State, ZyloLib, MainScreen, GearBtn)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local C = ZyloLib.Colors

    -- Inisialisasi State Webhook
    State.EggWebhook = State.EggWebhook or {}
    State.EggWebhook.Url = State.EggWebhook.Url or ""
    State.EggWebhook.Enabled = (State.EggWebhook.Enabled ~= nil) and State.EggWebhook.Enabled or false
    State.EggWebhook.Mode = State.EggWebhook.Mode or "Simple" -- "Simple" atau "Detail"
    State.EggWebhook.SendTestStatus = ""

    -- Tracking State untuk Detail Mode
    State.EggWebhook.Tracking = State.EggWebhook.Tracking or {
        Cycle = 1,
        TotalHatch = 0,
        StartTime = os.time(),
        CycleStartTime = os.time(),
        StartEggCounts = {},
        PrevCycleEggCounts = {},
        CurrentEggCounts = {},
        BrontoHatchCount = 0,
        BrontoHatchBreakdown = {},
        NormalHatchBreakdown = {},
        EggBackHatch = {},
        PetsSold = 0,
        EggBackSell = {}
    }

    -- Auto-load saved webhook URL & Mode dari file jika didukung executor
    local CONFIG_FILE = "ZyloHub_EggWebhook.json"
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data then
                if data.Url and State.EggWebhook.Url == "" then
                    State.EggWebhook.Url = data.Url
                end
                if data.Enabled ~= nil then
                    State.EggWebhook.Enabled = data.Enabled
                end
                if data.Mode and (data.Mode == "Simple" or data.Mode == "Detail") then
                    State.EggWebhook.Mode = data.Mode
                end
            end
        end
    end)

    local function saveWebhookConfig()
        pcall(function()
            if writefile then
                local data = {
                    Url = State.EggWebhook.Url,
                    Enabled = State.EggWebhook.Enabled,
                    Mode = State.EggWebhook.Mode
                }
                writefile(CONFIG_FILE, HttpService:JSONEncode(data))
            end
        end)
    end

    -- =============================================================
    -- [1] HTTP REQUEST HELPER FOR DISCORD WEBHOOK
    -- =============================================================
    local function sendDiscordWebhook(url, payloadTable, callback)
        task.spawn(function()
            if not url or url == "" then
                if callback then callback(false, "URL Webhook kosong!") end
                return
            end

            local cleanUrl = url:gsub("^%s+", ""):gsub("%s+$", "")
            if not (cleanUrl:find("discord%.com/api/webhooks") or cleanUrl:find("discordapp%.com/api/webhooks")) then
                if callback then callback(false, "URL tidak valid! Harus link discord.com/api/webhooks") end
                return
            end

            local jsonPayload = nil
            local okEncode, errEncode = pcall(function()
                jsonPayload = HttpService:JSONEncode(payloadTable)
            end)
            if not okEncode or not jsonPayload then
                if callback then callback(false, "Gagal encode JSON: " .. tostring(errEncode)) end
                return
            end

            local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if httpRequest then
                local res = nil
                local okReq, errReq = pcall(function()
                    res = httpRequest({
                        Url = cleanUrl,
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json"
                        },
                        Body = jsonPayload
                    })
                end)

                if okReq and res then
                    local code = res.StatusCode or res.status_code or 0
                    if code == 200 or code == 204 then
                        if callback then callback(true, "Sukses terkirim! (Status " .. tostring(code) .. ")") end
                    else
                        local msg = res.Body or res.body or "HTTP Error " .. tostring(code)
                        if callback then callback(false, "Gagal (" .. tostring(code) .. "): " .. tostring(msg):sub(1, 60)) end
                    end
                else
                    if callback then callback(false, "Gagal request: " .. tostring(errReq or "Unknown error")) end
                end
            else
                if callback then callback(false, "Executor tidak mendukung fungsi HTTP Request!") end
            end
        end)
    end

    -- Helper format detik menjadi HH:MM:SS
    local function formatSeconds(secs)
        secs = math.max(0, math.floor(tonumber(secs) or 0))
        local h = math.floor(secs / 3600)
        local m = math.floor((secs % 3600) / 60)
        local s = secs % 60
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    -- Helper ambil ping game real-time
    local function getGamePing()
        local ping = 50
        pcall(function()
            local stats = game:GetService("Stats")
            local pingItem = stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
            if pingItem then
                ping = math.floor(pingItem:GetValue())
            end
        end)
        return ping
    end

    -- =============================================================
    -- [2] BUILDER PAYLOAD DISCORD (SIMPLE & DETAIL)
    -- =============================================================

    -- BUILDER 1: MODE SIMPLE (Sesuai request user)
    -- Menampilkan: Nama/jenis telur, Nama pet, Berat/bobot, status favorite/keep, Akun roblox & waktu
    local function BuildSimplePayload(eggName, petSpecies, petWeight, isFavorite, timestamp)
        local timeStr = timestamp or os.date("%Y-%m-%d %H:%M:%S")
        local color = isFavorite and 16766720 or 9055202 -- Emas jika favorite, Ungu jika normal

        return {
            username = "ZyloHub • Egg Hatch (Simple)",
            avatar_url = "https://i.imgur.com/4M34hi2.png",
            embeds = {
                {
                    title = "🐣 Telur Menetas! (Egg Hatched)",
                    description = "Pemain **" .. LocalPlayer.Name .. "** baru saja menetaskan telur di kebun!",
                    color = color,
                    fields = {
                        { name = "🥚 Jenis Telur", value = "`" .. tostring(eggName or "Unknown Egg") .. "`", inline = true },
                        { name = "🐾 Nama Pet", value = "**" .. tostring(petSpecies or "Pet") .. "**", inline = true },
                        { name = "⚖️ Berat/Bobot", value = "`" .. tostring(petWeight or "0.0") .. " KG`", inline = true },
                        { name = "⭐ Status Pet", value = isFavorite and "`⭐ Favorite / Keep`" or "`Normal`", inline = true },
                        { name = "👤 Akun Roblox", value = "`" .. LocalPlayer.Name .. "`", inline = true },
                        { name = "🕒 Waktu Hatch", value = "`" .. timeStr .. "`", inline = true }
                    },
                    footer = {
                        text = "ZyloHub v3.5 • Mode Simple"
                    }
                }
            }
        }
    end

    -- BUILDER 2: MODE DETAIL (Sesuai Screenshot Discord Pengguna)
    -- Menampilkan Cycle, Tracking, Ping, Pets Inventory, Eggs Start, Eggs Cycle, Bronto, Normal, Egg Back, Sell Summary, Luck
    local function BuildDetailPayload(customData)
        local d = customData or {}
        local cycleNum = d.Cycle or 417
        local cycleDur = d.CycleDuration or "00:00:53"
        local player = d.Player or LocalPlayer.Name
        local totalHatch = d.TotalHatch or 5421
        local totalDur = d.Duration or "06:05:17"
        local ping = d.Ping or getGamePing()
        local invTotal = d.InvTotal or 34
        local invMax = d.InvMax or 285
        local invFree = invMax - invTotal

        local eggsTotalStr = d.EggsTotalStr or "Total: 768 → 806 (+38)\n• Night Egg: 768 → 806 (+38)"
        local eggsCycleStr = d.EggsCycleStr or "Total: 807 → 806 (-1)\n• Night Egg: 807 → 806 (-1)"

        local brontoHatchStr = d.BrontoHatchStr or "• Total hatch with Bronto: 8\n• Raccoon: 8x (1.270–2.504 kg)"
        local normalHatchStr = d.NormalHatchStr or "• Echo Frog: 1x (1.118–1.118 kg)\n• Hedgehog: 4x (0.904–1.780 kg)\n• Frog: 2x (1.456–1.492 kg)\n• Mole: 5x (0.908–2.058 kg)"

        local eggBackStr = d.EggBackStr or "• Night Egg: 5x"
        local eggBackPercent = d.EggBackPercent or "50.00%"

        local sellSummaryStr = d.SellSummaryStr or "• Pets sold : 12\n• Egg back sell : Night Egg ( 6x )"
        local sellPercent = d.SellPercent or "52.25%"

        local luckStr = d.LuckStr or "🟢 GOOD Luck (+38)"
        local embedColor = d.EmbedColor or 3066993 -- 0x2ECC71 (Emerald Green Discord)

        local contentText = string.format(
            "**Cycle #%d • Finished**\n**Cycle Duration:** %s\n\n" ..
            "**👤 Player**\n• %s\n\n" ..
            "**📊 Tracking**\n• Total hatch : %s\n• Duration : %s\n\n" ..
            "**📡 PING**\n• Game Ping: `%d ms`\n\n" ..
            "**📦 Pets Inventory**\n• Total: %d/%d (Free: %d)\n\n" ..
            "**🥚 Eggs (Total since start)**\n%s\n\n" ..
            "**🥚 Eggs (This cycle only)**\n%s\n\n" ..
            "**🦴 Hatch Bronto**\n%s\n\n" ..
            "**🥕 Hatch Normal**\n%s\n\n" ..
            "**🔄 Egg Back from Hatch ( %s )**\n%s\n\n" ..
            "**💰 Sell Summary ( %s )**\n%s\n\n" ..
            "**🎯 Luck:** %s",
            cycleNum, cycleDur,
            player,
            tostring(totalHatch), totalDur,
            ping,
            invTotal, invMax, invFree,
            eggsTotalStr,
            eggsCycleStr,
            brontoHatchStr,
            normalHatchStr,
            eggBackPercent, eggBackStr,
            sellPercent, sellSummaryStr,
            luckStr
        )

        return {
            username = "ZyloHub • Hatch Reporter",
            avatar_url = "https://i.imgur.com/4M34hi2.png",
            embeds = {
                {
                    title = string.format("#Cycle #%d", cycleNum),
                    description = contentText,
                    color = embedColor,
                    footer = {
                        text = "ZyloHub v3.5 • Grow a Garden Automation Suite • " .. os.date("%d/%m/%Y %H:%M")
                    }
                }
            }
        }
    end

    -- =============================================================
    -- [3] UI MODAL FRAME PENGATURAN WEBHOOK EGG
    -- =============================================================
    local Modal = Instance.new("Frame", MainScreen or LocalPlayer.PlayerGui:FindFirstChildOfClass("ScreenGui"))
    Modal.Name = "EggWebhookModal"
    Modal.Size = UDim2.new(0, 335, 0, 345)
    Modal.Position = UDim2.new(0.5, -167, 0.5, -172)
    Modal.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Modal.Visible = false
    Modal.ZIndex = 120
    Instance.new("UICorner", Modal).CornerRadius = UDim.new(0, 10)

    local mStroke = Instance.new("UIStroke", Modal)
    mStroke.Color = C.PURPLE
    mStroke.Thickness = 1.5

    -- Header Modal
    local Header = Instance.new("Frame", Modal)
    Header.Size = UDim2.new(1, 0, 0, 38)
    Header.BackgroundColor3 = Color3.fromRGB(16, 20, 38)
    Header.BorderSizePixel = 0
    Header.ZIndex = 121
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

    local hIcon = Instance.new("TextLabel", Header)
    hIcon.Position = UDim2.new(0, 10, 0, 0)
    hIcon.Size = UDim2.new(0, 24, 1, 0)
    hIcon.BackgroundTransparency = 1
    hIcon.Text = "⚙️"
    hIcon.TextSize = 14
    hIcon.ZIndex = 122

    local hTitle = Instance.new("TextLabel", Header)
    hTitle.Position = UDim2.new(0, 36, 0, 0)
    hTitle.Size = UDim2.new(1, -75, 1, 0)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "Webhook Egg Settings"
    hTitle.TextColor3 = Color3.fromRGB(245, 248, 255)
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextSize = 11
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 122

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -11)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 50)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(200, 210, 240)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 10
    CloseBtn.ZIndex = 122
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

    CloseBtn.MouseButton1Click:Connect(function()
        Modal.Visible = false
    end)

    -- Container Body
    local Body = Instance.new("Frame", Modal)
    Body.Position = UDim2.new(0, 12, 0, 44)
    Body.Size = UDim2.new(1, -24, 1, -50)
    Body.BackgroundTransparency = 1
    Body.ZIndex = 121

    local bLayout = Instance.new("UIListLayout", Body)
    bLayout.SortOrder = Enum.SortOrder.LayoutOrder
    bLayout.Padding = UDim.new(0, 8)

    -- -------------------------------------------------------------
    -- [BAGIAN 1: INPUT LINK WEBHOOK EGG]
    -- -------------------------------------------------------------
    local SecLink = Instance.new("Frame", Body)
    SecLink.Size = UDim2.new(1, 0, 0, 58)
    SecLink.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
    SecLink.LayoutOrder = 1
    SecLink.ZIndex = 122
    Instance.new("UICorner", SecLink).CornerRadius = UDim.new(0, 6)
    local slStroke = Instance.new("UIStroke", SecLink)
    slStroke.Color = Color3.fromRGB(35, 42, 70)

    local lblLinkTitle = Instance.new("TextLabel", SecLink)
    lblLinkTitle.Position = UDim2.new(0, 10, 0, 5)
    lblLinkTitle.Size = UDim2.new(1, -20, 0, 14)
    lblLinkTitle.BackgroundTransparency = 1
    lblLinkTitle.Text = "Webhook Egg ( Link Webhook Discord ) :"
    lblLinkTitle.TextColor3 = C.TEXT_W
    lblLinkTitle.Font = Enum.Font.GothamBold
    lblLinkTitle.TextSize = 8.5
    lblLinkTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblLinkTitle.ZIndex = 123

    local BoxContainer = Instance.new("Frame", SecLink)
    BoxContainer.Position = UDim2.new(0, 8, 0, 23)
    BoxContainer.Size = UDim2.new(1, -16, 0, 28)
    BoxContainer.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
    BoxContainer.ZIndex = 123
    Instance.new("UICorner", BoxContainer).CornerRadius = UDim.new(0, 6)
    local bcStroke = Instance.new("UIStroke", BoxContainer)
    bcStroke.Color = Color3.fromRGB(45, 55, 85)

    local BoxLink = Instance.new("TextBox", BoxContainer)
    BoxLink.Position = UDim2.new(0, 8, 0, 0)
    BoxLink.Size = UDim2.new(1, -16, 1, 0)
    BoxLink.BackgroundTransparency = 1
    BoxLink.Text = State.EggWebhook.Url or ""
    BoxLink.PlaceholderText = "https://discord.com/api/webhooks/..."
    BoxLink.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    BoxLink.TextColor3 = C.CYAN
    BoxLink.Font = Enum.Font.Gotham
    BoxLink.TextSize = 8.5
    BoxLink.TextXAlignment = Enum.TextXAlignment.Left
    BoxLink.ClearTextOnFocus = false
    BoxLink.ZIndex = 124

    local function onUrlChanged()
        State.EggWebhook.Url = BoxLink.Text:gsub("^%s+", ""):gsub("%s+$", "")
        saveWebhookConfig()
    end

    BoxLink.FocusLost:Connect(onUrlChanged)
    BoxLink:GetPropertyChangedSignal("Text"):Connect(onUrlChanged)

    -- -------------------------------------------------------------
    -- [BAGIAN 2: PILIHAN MODE FORMAT NOTIFIKASI (SIMPLE VS DETAIL)]
    -- -------------------------------------------------------------
    local SecMode = Instance.new("Frame", Body)
    SecMode.Size = UDim2.new(1, 0, 0, 64)
    SecMode.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
    SecMode.LayoutOrder = 2
    SecMode.ZIndex = 122
    Instance.new("UICorner", SecMode).CornerRadius = UDim.new(0, 6)
    local smStroke = Instance.new("UIStroke", SecMode)
    smStroke.Color = Color3.fromRGB(35, 42, 70)

    local lblModeTitle = Instance.new("TextLabel", SecMode)
    lblModeTitle.Position = UDim2.new(0, 10, 0, 5)
    lblModeTitle.Size = UDim2.new(1, -20, 0, 14)
    lblModeTitle.BackgroundTransparency = 1
    lblModeTitle.Text = "Format Notifikasi Discord :"
    lblModeTitle.TextColor3 = C.TEXT_W
    lblModeTitle.Font = Enum.Font.GothamBold
    lblModeTitle.TextSize = 8.5
    lblModeTitle.TextXAlignment = Enum.TextXAlignment.Left
    lblModeTitle.ZIndex = 123

    local ModeBtnsContainer = Instance.new("Frame", SecMode)
    ModeBtnsContainer.Position = UDim2.new(0, 8, 0, 22)
    ModeBtnsContainer.Size = UDim2.new(1, -16, 0, 24)
    ModeBtnsContainer.BackgroundTransparency = 1
    ModeBtnsContainer.ZIndex = 123

    local btnSimple = Instance.new("TextButton", ModeBtnsContainer)
    btnSimple.Size = UDim2.new(0.48, 0, 1, 0)
    btnSimple.Position = UDim2.new(0, 0, 0, 0)
    btnSimple.Font = Enum.Font.GothamBold
    btnSimple.TextSize = 8.5
    btnSimple.ZIndex = 124
    Instance.new("UICorner", btnSimple).CornerRadius = UDim.new(0, 5)
    local bsStroke = Instance.new("UIStroke", btnSimple)

    local btnDetail = Instance.new("TextButton", ModeBtnsContainer)
    btnDetail.Size = UDim2.new(0.48, 0, 1, 0)
    btnDetail.Position = UDim2.new(0.52, 0, 0, 0)
    btnDetail.Font = Enum.Font.GothamBold
    btnDetail.TextSize = 8.5
    btnDetail.ZIndex = 124
    Instance.new("UICorner", btnDetail).CornerRadius = UDim.new(0, 5)
    local bdStroke = Instance.new("UIStroke", btnDetail)

    local lblModeDesc = Instance.new("TextLabel", SecMode)
    lblModeDesc.Position = UDim2.new(0, 10, 0, 48)
    lblModeDesc.Size = UDim2.new(1, -20, 0, 12)
    lblModeDesc.BackgroundTransparency = 1
    lblModeDesc.TextColor3 = Color3.fromRGB(150, 160, 190)
    lblModeDesc.Font = Enum.Font.Gotham
    lblModeDesc.TextSize = 7.5
    lblModeDesc.TextXAlignment = Enum.TextXAlignment.Left
    lblModeDesc.ZIndex = 123

    local function updateModeVisual()
        local isSimple = (State.EggWebhook.Mode == "Simple")

        btnSimple.BackgroundColor3 = isSimple and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(20, 24, 44)
        btnSimple.Text = isSimple and "✓ 📄 Simple Mode" or "📄 Simple Mode"
        btnSimple.TextColor3 = isSimple and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 170, 200)
        bsStroke.Color = isSimple and Color3.fromRGB(200, 130, 255) or Color3.fromRGB(45, 55, 85)

        btnDetail.BackgroundColor3 = not isSimple and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(20, 24, 44)
        btnDetail.Text = not isSimple and "✓ 📊 Detail (Cycle)" or "📊 Detail (Cycle)"
        btnDetail.TextColor3 = not isSimple and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 170, 200)
        bdStroke.Color = not isSimple and Color3.fromRGB(200, 130, 255) or Color3.fromRGB(45, 55, 85)

        if isSimple then
            lblModeDesc.Text = "ℹ️ Simple: Nama telur, pet didapat, bobot, status fav/keep, player & waktu"
        else
            lblModeDesc.Text = "ℹ️ Detail: Rekap Cycle lengkap (Tracking, Ping, Bronto/Normal, Egg & Sell)"
        end
    end

    btnSimple.MouseButton1Click:Connect(function()
        State.EggWebhook.Mode = "Simple"
        updateModeVisual()
        saveWebhookConfig()
    end)

    btnDetail.MouseButton1Click:Connect(function()
        State.EggWebhook.Mode = "Detail"
        updateModeVisual()
        saveWebhookConfig()
    end)

    updateModeVisual()

    -- -------------------------------------------------------------
    -- [BAGIAN 3: TOMBOL "SEND TEST" & STATUS INDIKATOR]
    -- -------------------------------------------------------------
    local SecTest = Instance.new("Frame", Body)
    SecTest.Size = UDim2.new(1, 0, 0, 56)
    SecTest.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
    SecTest.LayoutOrder = 3
    SecTest.ZIndex = 122
    Instance.new("UICorner", SecTest).CornerRadius = UDim.new(0, 6)
    local stStroke = Instance.new("UIStroke", SecTest)
    stStroke.Color = Color3.fromRGB(35, 42, 70)

    local BtnSendTest = Instance.new("TextButton", SecTest)
    BtnSendTest.Position = UDim2.new(0, 8, 0, 6)
    BtnSendTest.Size = UDim2.new(1, -16, 0, 25)
    BtnSendTest.BackgroundColor3 = Color3.fromRGB(32, 20, 58)
    BtnSendTest.Text = "🧪  Send Test Webhook"
    BtnSendTest.TextColor3 = Color3.fromRGB(255, 255, 255)
    BtnSendTest.Font = Enum.Font.GothamBold
    BtnSendTest.TextSize = 9
    BtnSendTest.ZIndex = 123
    Instance.new("UICorner", BtnSendTest).CornerRadius = UDim.new(0, 6)
    local bstStroke = Instance.new("UIStroke", BtnSendTest)
    bstStroke.Color = C.PURPLE_L

    local StatusLbl = Instance.new("TextLabel", SecTest)
    StatusLbl.Position = UDim2.new(0, 8, 0, 34)
    StatusLbl.Size = UDim2.new(1, -16, 0, 16)
    StatusLbl.BackgroundTransparency = 1
    StatusLbl.Text = "Status: Siap mencoba koneksi"
    StatusLbl.TextColor3 = Color3.fromRGB(150, 165, 200)
    StatusLbl.Font = Enum.Font.GothamMedium
    StatusLbl.TextSize = 8
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Center
    StatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
    StatusLbl.ZIndex = 123

    BtnSendTest.MouseButton1Click:Connect(function()
        local url = State.EggWebhook.Url or ""
        if url == "" then
            StatusLbl.Text = "❌ Masukkan link webhook Discord terlebih dahulu!"
            StatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end

        local mode = State.EggWebhook.Mode or "Simple"
        StatusLbl.Text = string.format("⏳ Mengirim test webhook (%s)...", mode)
        StatusLbl.TextColor3 = C.CYAN
        BtnSendTest.BackgroundColor3 = Color3.fromRGB(20, 24, 44)

        local testPayload = nil
        if mode == "Detail" then
            testPayload = BuildDetailPayload({
                Cycle = 417,
                CycleDuration = "00:00:53",
                Player = LocalPlayer.Name,
                TotalHatch = 5421,
                Duration = "06:05:17",
                Ping = getGamePing(),
                InvTotal = 34,
                InvMax = 285,
                EggsTotalStr = "Total: 768 → 806 (+38)\n• Night Egg: 768 → 806 (+38)",
                EggsCycleStr = "Total: 807 → 806 (-1)\n• Night Egg: 807 → 806 (-1)",
                BrontoHatchStr = "• Total hatch with Bronto: 8\n• Raccoon: 8x (1.270–2.504 kg)",
                NormalHatchStr = "• Echo Frog: 1x (1.118–1.118 kg)\n• Hedgehog: 4x (0.904–1.780 kg)\n• Frog: 2x (1.456–1.492 kg)\n• Mole: 5x (0.908–2.058 kg)",
                EggBackPercent = "50.00%",
                EggBackStr = "• Night Egg: 5x",
                SellPercent = "52.25%",
                SellSummaryStr = "• Pets sold : 12\n• Egg back sell : Night Egg ( 6x )",
                LuckStr = "🟢 GOOD Luck (+38)",
                EmbedColor = 3066993 -- 0x2ECC71
            })
        else
            testPayload = BuildSimplePayload("Night Egg", "Mimic Octopus", 280.0, true, os.date("%Y-%m-%d %H:%M:%S"))
        end

        sendDiscordWebhook(url, testPayload, function(success, message)
            BtnSendTest.BackgroundColor3 = Color3.fromRGB(32, 20, 58)
            if success then
                StatusLbl.Text = "✅ " .. tostring(message) .. " (" .. mode .. ")"
                StatusLbl.TextColor3 = Color3.fromRGB(100, 255, 170)
            else
                StatusLbl.Text = "❌ " .. tostring(message)
                StatusLbl.TextColor3 = Color3.fromRGB(255, 110, 110)
            end
        end)
    end)

    -- -------------------------------------------------------------
    -- [BAGIAN 4: FITUR "ON / OFF" NOTIFIKASI WEBHOOK EGG]
    -- -------------------------------------------------------------
    local SecToggle = Instance.new("Frame", Body)
    SecToggle.Size = UDim2.new(1, 0, 0, 46)
    SecToggle.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
    SecToggle.LayoutOrder = 4
    SecToggle.ZIndex = 122
    Instance.new("UICorner", SecToggle).CornerRadius = UDim.new(0, 6)
    local togStroke = Instance.new("UIStroke", SecToggle)
    togStroke.Color = Color3.fromRGB(35, 42, 70)

    local lblTog = Instance.new("TextLabel", SecToggle)
    lblTog.Position = UDim2.new(0, 10, 0, 6)
    lblTog.Size = UDim2.new(1, -85, 0, 16)
    lblTog.BackgroundTransparency = 1
    lblTog.Text = "Aktifkan Webhook Notifikasi Egg"
    lblTog.TextColor3 = C.TEXT_W
    lblTog.Font = Enum.Font.GothamBold
    lblTog.TextSize = 9
    lblTog.TextXAlignment = Enum.TextXAlignment.Left
    lblTog.ZIndex = 123

    local subTog = Instance.new("TextLabel", SecToggle)
    subTog.Position = UDim2.new(0, 10, 0, 24)
    subTog.Size = UDim2.new(1, -85, 0, 14)
    subTog.BackgroundTransparency = 1
    subTog.Text = "Kirim laporan otomatis ke Discord"
    subTog.TextColor3 = Color3.fromRGB(140, 150, 180)
    subTog.Font = Enum.Font.Gotham
    subTog.TextSize = 7.5
    subTog.TextXAlignment = Enum.TextXAlignment.Left
    subTog.ZIndex = 123

    local BtnToggle = Instance.new("TextButton", SecToggle)
    BtnToggle.Position = UDim2.new(1, -66, 0.5, -12)
    BtnToggle.Size = UDim2.new(0, 56, 0, 24)
    BtnToggle.BackgroundColor3 = State.EggWebhook.Enabled and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(24, 28, 48)
    BtnToggle.Text = State.EggWebhook.Enabled and "ON" or "OFF"
    BtnToggle.TextColor3 = State.EggWebhook.Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 150, 180)
    BtnToggle.Font = Enum.Font.GothamBold
    BtnToggle.TextSize = 9
    BtnToggle.ZIndex = 123
    Instance.new("UICorner", BtnToggle).CornerRadius = UDim.new(0, 6)
    local btStroke = Instance.new("UIStroke", BtnToggle)
    btStroke.Color = State.EggWebhook.Enabled and Color3.fromRGB(200, 130, 255) or Color3.fromRGB(50, 60, 90)

    local function updateToggleVisual()
        local isAct = State.EggWebhook.Enabled
        BtnToggle.BackgroundColor3 = isAct and Color3.fromRGB(138, 43, 226) or Color3.fromRGB(24, 28, 48)
        BtnToggle.Text = isAct and "ON" or "OFF"
        BtnToggle.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 150, 180)
        btStroke.Color = isAct and Color3.fromRGB(200, 130, 255) or Color3.fromRGB(50, 60, 90)

        if GearBtn then
            local gStroke = GearBtn:FindFirstChildOfClass("UIStroke")
            if isAct then
                GearBtn.TextColor3 = C.CYAN
                if gStroke then gStroke.Color = C.CYAN end
            else
                GearBtn.TextColor3 = C.TEXT_M
                if gStroke then gStroke.Color = C.STROKE end
            end
        end
    end

    BtnToggle.MouseButton1Click:Connect(function()
        State.EggWebhook.Enabled = not State.EggWebhook.Enabled
        updateToggleVisual()
        saveWebhookConfig()
    end)

    updateToggleVisual()

    -- =============================================================
    -- [5] KONEKSI TOMBOL PENGATURAN (⚙️) DI SEBELAH CONFIG
    -- =============================================================
    if GearBtn then
        GearBtn.MouseButton1Click:Connect(function()
            Modal.Visible = not Modal.Visible
            if Modal.Visible then
                BoxLink.Text = State.EggWebhook.Url or ""
                updateModeVisual()
                StatusLbl.Text = "Status: Siap mencoba koneksi"
                StatusLbl.TextColor3 = Color3.fromRGB(150, 165, 200)
            end
        end)
    end

    -- =============================================================
    -- [6] PUBLIC API PENGIRIMAN NOTIFIKASI
    -- =============================================================

    -- Kirim notifikasi individual (Simple)
    function EggWebhookModule.SendHatchNotification(eggName, petSpecies, petWeight, isFavorite)
        if not State.EggWebhook.Enabled or not State.EggWebhook.Url or State.EggWebhook.Url == "" then
            return
        end

        local payload = nil
        if State.EggWebhook.Mode == "Detail" then
            -- Jika mode detail aktif, notifikasi diakumulasikan ke cycle atau dikirim rekap
            return
        else
            payload = BuildSimplePayload(eggName, petSpecies, petWeight, isFavorite)
        end

        sendDiscordWebhook(State.EggWebhook.Url, payload)
    end

    -- Kirim notifikasi siklus komprehensif (Detail)
    function EggWebhookModule.SendCycleReport(cycleData)
        if not State.EggWebhook.Enabled or not State.EggWebhook.Url or State.EggWebhook.Url == "" then
            return
        end
        local payload = BuildDetailPayload(cycleData)
        sendDiscordWebhook(State.EggWebhook.Url, payload)
    end

    return {
        Modal = Modal,
        Open = function() Modal.Visible = true end,
        Close = function() Modal.Visible = false end,
        Toggle = function() Modal.Visible = not Modal.Visible end,
        SendHatchNotification = EggWebhookModule.SendHatchNotification,
        SendCycleReport = EggWebhookModule.SendCycleReport,
        BuildSimplePayload = BuildSimplePayload,
        BuildDetailPayload = BuildDetailPayload
    }
end

return EggWebhookModule
