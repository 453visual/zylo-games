-- =========================================================================
--  ZYLOHUB - MUTASI DISCORD WEBHOOK ENGINE (OFFICIAL v2.3 - PRO TRACKER)
--  Repository: zylo-games/MutasiWebhook.lua
--  Fitur: Time Tracker, Inventory GBXP Stock, Rekap Sederhana, Underline
-- =========================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local MutasiWebhook = {}

local function sendHttpRequest(url, payloadTable)
    if not url or url == "" or not url:find("discord.com/api/webhooks") then
        return false, "URL Webhook tidak valid"
    end

    local jsonBody = ""
    local okJson, errJson = pcall(function()
        jsonBody = HttpService:JSONEncode(payloadTable)
    end)
    if not okJson then return false, "JSON Encode Error: " .. tostring(errJson) end

    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
    if not requestFunc then
        return false, "Executor tidak mendukung custom HTTP request function"
    end

    local response = nil
    local success, reqErr = pcall(function()
        response = requestFunc({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonBody,
            url = url,
            method = "POST",
            headers = { ["Content-Type"] = "application/json" },
            body = jsonBody
        })
    end)

    if not success then
        return false, "HTTP Request Error: " .. tostring(reqErr)
    end

    return true, response
end

-- Helper Pembentuk Teks Waktu (HH:MM:SS)
local function formatTimeDuration(seconds)
    seconds = math.max(tonumber(seconds) or 0, 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

-- Helper Field Waktu (TIME)
local function buildTimeField(modeName, totalModeSeconds, stageTimesTable)
    local lines = {}
    table.insert(lines, string.format("• **%s** : `%s`", modeName or "Mode", formatTimeDuration(totalModeSeconds)))
    if stageTimesTable and type(stageTimesTable) == "table" then
        for stageName, sec in pairs(stageTimesTable) do
            table.insert(lines, string.format("• **%s** : `%s`", stageName, formatTimeDuration(sec)))
        end
    end
    return table.concat(lines, "\n")
end

-- Helper Format Garis Bawah Daftar Pet
local function formatPetsList(petsList)
    if not petsList or #petsList == 0 then return "Tidak ada pet yang diproses" end
    local descriptions = {}
    for i, p in ipairs(petsList) do
        local line = string.format(
            "%d. __**%s**__\n    ╰ Age: `%s` ┆ Berat: `%s KG` ┆ Mutasi: `%s`",
            i, p.Name, tostring(p.Age), tostring(p.Weight), p.Mutation or "Normal"
        )
        table.insert(descriptions, line)
    end
    return table.concat(descriptions, "\n───────────────────────────────\n")
end

-- 1. TES KONEKSI
function MutasiWebhook:SendTest(url)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        avatar_url = "https://i.imgur.com/8Qf9GkF.png",
        embeds = {
            {
                title = "🔔 Tes Koneksi Discord Webhook Berhasil!",
                description = "Koneksi antara **ZyloHub Auto Mutasi** dan Discord Webhook Anda telah terhubung aktif dengan mode **Pro Tracker & Realtime Inventory**.",
                color = 9055202, -- Purple
                fields = {
                    { name = "👤 Akun Roblox", value = string.format("`%s` (@%s)", LocalPlayer.DisplayName, LocalPlayer.Name), inline = true },
                    { name = "⚡ Status", value = "`READY & CONNECTED`", inline = true }
                },
                footer = { text = "ZyloHub • Auto Mutasi System" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 2. EVENT: ROMBONGAN BARU DARI GBXP
function MutasiWebhook:SendBatchStart(url, modeName, petsList, invInfo, timeData, rekapModeCount, rekapMutationCount)
    local timeStr = buildTimeField(modeName, timeData and timeData.TotalMode or 0, timeData and timeData.Stages)
    local invStr = string.format("• Total: `%s` (Free: `%s`)\n• Stok Siap Salur GBXP: `%s Pet`", 
        invInfo and invInfo.TotalText or "?/?", 
        invInfo and invInfo.FreeText or "0",
        tostring(invInfo and invInfo.SupplyCount or 0)
    )

    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "📦 [EVENT]: Rombongan Pet Baru Diambil dari GBXP",
                description = string.format("Memulai pemrosesan rombongan baru di **%s**.\n───────────────────────────────", modeName),
                color = 3447003, -- Blue
                fields = {
                    { name = "👤 Player", value = string.format("`%s`", LocalPlayer.Name), inline = true },
                    { name = "🎯 Mode", value = string.format("`%s`", modeName), inline = true },
                    { name = "⏱️ TIME", value = timeStr, inline = false },
                    { name = "📦 Pets Inventory", value = invStr, inline = false },
                    { name = string.format("🏆 REKAP PET BERHASIL %s", modeName:upper()), value = string.format("`Total: %d Pet`", rekapModeCount or 0), inline = true },
                    { name = "🧬 REKAP PET BERHASIL MUTASI", value = string.format("`Total: %d Pet`", rekapMutationCount or 0), inline = true },
                    { name = string.format("🐾 Daftar Pet Sedang Berjalan (%d)", #petsList), value = formatPetsList(petsList), inline = false }
                },
                footer = { text = "ZyloHub • GBXP Supply Tracker" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 3. EVENT: PINDAH TAHAPAN PERKEMBANGAN (XP, Elephant, 100 Age, dll)
function MutasiWebhook:SendStageChange(url, stageName, targetAge, petsList, invInfo, timeData, rekapModeCount, rekapMutationCount, modeName)
    local timeStr = buildTimeField(modeName or "Mode", timeData and timeData.TotalMode or 0, timeData and timeData.Stages)
    local invStr = string.format("• Total: `%s` (Free: `%s`)\n• Stok Siap Salur GBXP: `%s Pet`", 
        invInfo and invInfo.TotalText or "?/?", 
        invInfo and invInfo.FreeText or "0",
        tostring(invInfo and invInfo.SupplyCount or 0)
    )

    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = string.format("🚀 [PERKEMBANGAN]: Masuk ke Tahap %s", stageName:upper()),
                description = string.format("Booster tim **%s** telah dipasang di kebun. Rombongan pet mulai menaikkan level.\n───────────────────────────────", stageName),
                color = 10181046, -- Purple Vibrant
                fields = {
                    { name = "📌 Tahap Aktif", value = string.format("`%s`", stageName), inline = true },
                    { name = "🎯 Target Unequip", value = string.format("`Age %d`", targetAge), inline = true },
                    { name = "⏱️ TIME", value = timeStr, inline = false },
                    { name = "📦 Pets Inventory", value = invStr, inline = false },
                    { name = string.format("🏆 REKAP PET BERHASIL %s", (modeName or "MODE"):upper()), value = string.format("`Total: %d Pet`", rekapModeCount or 0), inline = true },
                    { name = "🧬 REKAP PET BERHASIL MUTASI", value = string.format("`Total: %d Pet`", rekapMutationCount or 0), inline = true },
                    { name = "🐾 Pet yang Diproses", value = formatPetsList(petsList), inline = false }
                },
                footer = { text = "ZyloHub • Stage Progress" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 4. EVENT: PET MASUK MESIN MUTASI
function MutasiWebhook:SendMachineStart(url, pet, desiredTarget)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "⚙️ [MESIN MUTASI]: Pet Masuk ke Mesin",
                description = string.format("Pet __**%s**__ telah dimasukkan ke dalam Mesin Mutasi dan proses dimulai!\n───────────────────────────────", pet.Name),
                color = 15105570, -- Orange
                fields = {
                    { name = "🐾 Nama Pet", value = string.format("__**%s**__", pet.Name), inline = true },
                    { name = "⚖️ Berat", value = string.format("`%s KG`", tostring(pet.Weight)), inline = true },
                    { name = "🎯 Target Mutasi", value = string.format("`%s`", desiredTarget), inline = true },
                    { name = "🧬 Mutasi Saat Ini", value = string.format("`%s`", pet.Mutation or "Normal"), inline = true }
                },
                footer = { text = "ZyloHub • Mutation Machine" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 5. EVENT: TARGET MUTASI TERCAPAI (SUKSES)
function MutasiWebhook:SendSuccess(url, pet, targetName, location, rekapMutationCount)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "🎉 [TARGET TERCAPAI]: Mutasi Berhasil Diperoleh!",
                description = string.format("Selamat! Pet __**%s**__ berhasil mendapatkan mutasi yang ditargetkan!\n───────────────────────────────", pet.Name),
                color = 3066993, -- Green
                fields = {
                    { name = "🐾 Nama Pet", value = string.format("__**%s**__", pet.Name), inline = true },
                    { name = "🧬 Mutasi Didapat", value = string.format("**%s**", pet.Mutation), inline = true },
                    { name = "🎯 Target", value = string.format("`%s`", targetName), inline = true },
                    { name = "📍 Lokasi", value = string.format("`%s`", location or "Mesin Mutasi"), inline = true },
                    { name = "📊 Umur & Berat", value = string.format("Age `%s` ┆ `%s KG`", tostring(pet.Age), tostring(pet.Weight)), inline = true },
                    { name = "🧬 REKAP PET BERHASIL MUTASI", value = string.format("`Total: %d Pet`", rekapMutationCount or 1), inline = false }
                },
                footer = { text = "ZyloHub • Success Mutation" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 6. EVENT: AUTO CLEAN PET SHARD
function MutasiWebhook:SendCleanLog(url, pet, gotMutation, desiredTarget)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "🧪 [CLEAN SHARD]: Mutasi Belum Cocok, Mencuci Pet...",
                description = string.format("Pet __**%s**__ mendapat **%s**, belum sesuai dengan target **%s**.\nClean Pet Shard otomatis digunakan untuk mereset mutasi pet!\n───────────────────────────────", pet.Name, gotMutation, desiredTarget),
                color = 15158332, -- Red
                fields = {
                    { name = "🐾 Nama Pet", value = string.format("__**%s**__", pet.Name), inline = true },
                    { name = "❌ Mutasi Keluar", value = string.format("`%s`", gotMutation), inline = true },
                    { name = "🎯 Target Diinginkan", value = string.format("`%s`", desiredTarget), inline = true }
                },
                footer = { text = "ZyloHub • Auto Clean Shard" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 7. EVENT: ROMBONGAN TUNTAS 100% SAMPAI AKHIR
function MutasiWebhook:SendBatchCompleted(url, modeName, petsList, invInfo, timeData, rekapModeCount, rekapMutationCount)
    local timeStr = buildTimeField(modeName, timeData and timeData.TotalMode or 0, timeData and timeData.Stages)
    local invStr = string.format("• Total: `%s` (Free: `%s`)\n• Stok Siap Salur GBXP: `%s Pet`", 
        invInfo and invInfo.TotalText or "?/?", 
        invInfo and invInfo.FreeText or "0",
        tostring(invInfo and invInfo.SupplyCount or 0)
    )

    local descriptions = {}
    for i, p in ipairs(petsList) do
        local line = string.format(
            "✓ __**%s**__\n    ╰ Final Age: `%s` ┆ Final Mutasi: `%s`",
            p.Name, tostring(p.Age), p.Mutation or "Normal"
        )
        table.insert(descriptions, line)
    end

    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "🏆 [ROMBONGAN TUNTAS]: Semua Tahapan Selesai!",
                description = string.format("Seluruh pet dalam rombongan ini telah lulus dari semua tahapan **%s** dan ditarik aman ke dalam tas.\n───────────────────────────────", modeName),
                color = 15844367, -- Gold
                fields = {
                    { name = "🎯 Mode Selesai", value = string.format("`%s`", modeName), inline = true },
                    { name = "⏱️ TIME", value = timeStr, inline = false },
                    { name = "📦 Pets Inventory", value = invStr, inline = false },
                    { name = string.format("🏆 REKAP PET BERHASIL %s", modeName:upper()), value = string.format("`Total: %d Pet`", rekapModeCount or 0), inline = true },
                    { name = "🧬 REKAP PET BERHASIL MUTASI", value = string.format("`Total: %d Pet`", rekapMutationCount or 0), inline = true },
                    { name = "🐾 Pet yang Diselesaikan", value = table.concat(descriptions, "\n───────────────────────────────\n"), inline = false }
                },
                footer = { text = "ZyloHub • Batch Completed" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

return MutasiWebhook
