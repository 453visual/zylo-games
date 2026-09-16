-- =========================================================================
--  ZYLOHUB - MUTASI DISCORD WEBHOOK ENGINE (v2.1 - CLEAN & STATS TRACKER)
--  Repository: zylo-games/MutasiWebhook.lua
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
        return false, "Executor tidak mendukung custom HTTP request"
    end

    local response = nil
    local success, reqErr = pcall(function()
        -- Mendukung huruf kecil dan kapital untuk semua executor
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

-- 1. TES KONEKSI
function MutasiWebhook:SendTest(url)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        avatar_url = "https://i.imgur.com/8Qf9GkF.png",
        embeds = {
            {
                title = "🔔 Tes Koneksi Discord Webhook Berhasil!",
                description = "Koneksi antara **ZyloHub Auto Mutasi** dan Discord Webhook telah terhubung dengan mode **Event Realtime & Statistik Tracker**.",
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
function MutasiWebhook:SendBatchStart(url, modeName, petsList, totalCompleted)
    local petDescriptions = {}
    for i, p in ipairs(petsList) do
        local line = string.format(
            "%d. __**%s**__\n    ╰ Age: `%s` ┆ Berat: `%s KG` ┆ Mutasi: `%s`",
            i, p.Name, tostring(p.Age), tostring(p.Weight), p.Mutation or "Normal"
        )
        table.insert(petDescriptions, line)
    end

    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "📦 [EVENT]: Rombongan Pet Baru Diambil dari GBXP",
                description = string.format("Memulai pemrosesan rombongan baru di **%s**.\n───────────────────────────────", modeName),
                color = 3447003, -- Blue
                fields = {
                    { name = "👤 Player", value = string.format("`%s`", LocalPlayer.Name), inline = true },
                    { name = "🎯 Mode Aktif", value = string.format("`%s`", modeName), inline = true },
                    { name = "🏆 Total Pet Lulus", value = string.format("**%d Pet**", totalCompleted or 0), inline = true },
                    { name = string.format("🐾 Daftar Pet Sedang Berjalan (%d)", #petsList), value = table.concat(petDescriptions, "\n───────────────────────────────\n") }
                },
                footer = { text = "ZyloHub • GBXP Supply Tracker" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 3. EVENT: PINDAH TAHAPAN PERKEMBANGAN
function MutasiWebhook:SendStageChange(url, stageName, targetAge, petsList)
    local petDescriptions = {}
    for i, p in ipairs(petsList) do
        local line = string.format(
            "• __**%s**__ ➔ Saat ini: Age `%s` ┆ Target: `Age %d`",
            p.Name, tostring(p.Age), targetAge
        )
        table.insert(petDescriptions, line)
    end

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
                    { name = "🐾 Pet yang Diproses", value = table.concat(petDescriptions, "\n") }
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
                description = string.format("Pet __**%s**__ telah dimasukkan ke dalam Mesin Mutasi!\n───────────────────────────────", pet.Name),
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
function MutasiWebhook:SendSuccess(url, pet, targetName, location)
    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "🎉 [TARGET TERCAPAI]: Mutasi Berhasil Diperoleh!",
                description = string.format("Selamat! Pet __**%s**__ berhasil mendapatkan mutasi impian!\n───────────────────────────────", pet.Name),
                color = 3066993, -- Green
                fields = {
                    { name = "🐾 Nama Pet", value = string.format("__**%s**__", pet.Name), inline = true },
                    { name = "🧬 Mutasi Didapat", value = string.format("**%s**", pet.Mutation), inline = true },
                    { name = "🎯 Target", value = string.format("`%s`", targetName), inline = true },
                    { name = "📍 Lokasi", value = string.format("`%s`", location or "Mesin Mutasi"), inline = true },
                    { name = "📊 Umur & Berat", value = string.format("Age `%s` ┆ `%s KG`", tostring(pet.Age), tostring(pet.Weight)), inline = true }
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
                description = string.format("Pet __**%s**__ mendapat mutasi **%s** (Belum sesuai **%s**).\nClean Pet Shard otomatis digunakan untuk mereset!\n───────────────────────────────", pet.Name, gotMutation, desiredTarget),
                color = 15158332, -- Red
                fields = {
                    { name = "🐾 Nama Pet", value = string.format("__**%s**__", pet.Name), inline = true },
                    { name = "❌ Mutasi Keluar", value = string.format("`%s`", gotMutation), inline = true },
                    { name = "🎯 Target", value = string.format("`%s`", desiredTarget), inline = true }
                },
                footer = { text = "ZyloHub • Auto Clean Shard" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

-- 7. EVENT: ROMBONGAN TUNTAS 100% (DENGAN TOTAL STATISTIK SELESAI)
function MutasiWebhook:SendBatchCompleted(url, modeName, petsList, totalCompleted)
    local petDescriptions = {}
    for i, p in ipairs(petsList) do
        local line = string.format(
            "✓ __**%s**__\n    ╰ Final Age: `%s` ┆ Final Mutasi: `%s`",
            p.Name, tostring(p.Age), p.Mutation or "Normal"
        )
        table.insert(petDescriptions, line)
    end

    local payload = {
        username = "ZyloHub Mutasi Bot",
        embeds = {
            {
                title = "🏆 [ROMBONGAN TUNTAS]: Semua Tahapan Selesai!",
                description = string.format("Seluruh pet dalam rombongan ini telah **lulus 100%%** dari tahapan **%s** dan ditarik aman ke dalam tas.\n───────────────────────────────", modeName),
                color = 15844367, -- Gold
                fields = {
                    { name = "🎯 Mode Selesai", value = string.format("`%s`", modeName), inline = true },
                    { name = "📊 Total Pet Lulus", value = string.format("🔥 **%d Pet Telah Lulus**", totalCompleted or #petsList), inline = true },
                    { name = "🐾 Rombongan Baru Saja Lulus", value = table.concat(petDescriptions, "\n───────────────────────────────\n") }
                },
                footer = { text = "ZyloHub • Batch Completed Tracker" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    return sendHttpRequest(url, payload)
end

return MutasiWebhook
