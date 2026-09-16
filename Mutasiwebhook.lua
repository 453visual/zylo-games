-- =========================================================================
--  ZYLOHUB - MUTASI WEBHOOK SERVICE (v1.0.0)
--  Repository: zylo-games/MutasiWebhook.lua
--  Fungsi: Mengirim Notifikasi Status & Hasil Mutasi Pet ke Discord Webhook
-- =========================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WebhookService = {}

local function sendHttpRequest(url, payload)
    if not url or url == "" or not url:find("discord.com/api/webhooks") then
        return false, "URL Webhook Discord tidak valid"
    end

    local jsonBody = HttpService:JSONEncode(payload)
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

    if httpRequest then
        local success, res = pcall(function()
            return httpRequest({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonBody
            })
        end)
        return success, res
    else
        local success, res = pcall(function()
            return HttpService:PostAsync(url, jsonBody, Enum.HttpContentType.ApplicationJson)
        end)
        return success, res
    end
end

-- 1. Notifikasi Saat Pet Berhasil Mencapai Target Mutasi
function WebhookService:SendSuccess(webhookUrl, petData, targetMutation, stageName)
    if not webhookUrl or webhookUrl == "" then return end

    local petName = petData.Name or "Pet"
    local mutation = petData.Mutation or "Normal"
    local age = tostring(petData.Age or 1)
    local weight = tostring(petData.Weight or "?")
    local playerName = LocalPlayer and LocalPlayer.Name or "Player"

    local embed = {
        title = "🎉 TARGET MUTASI TERCAPAI!",
        description = string.format("**%s** berhasil mendapatkan mutasi yang diinginkan di tahap **%s**!", petName, stageName or "Mesin"),
        color = 9055202, -- Warna Cosmic Purple (#8A2BE2)
        fields = {
            { name = "👤 Akun / Player", value = "```" .. playerName .. "```", inline = true },
            { name = "🐾 Nama Pet", value = "```" .. petName .. "```", inline = true },
            { name = "✨ Mutasi Didapat", value = "```" .. mutation .. "```", inline = true },
            { name = "🎯 Target Mutasi", value = "```" .. (targetMutation or "Any Mutation") .. "```", inline = true },
            { name = "⚖️ Berat (KG)", value = "```" .. weight .. " KG```", inline = true },
            { name = "📈 Umur (Age)", value = "```Age " .. age .. "```", inline = true },
            { name = "⚡ Status Pipeline", value = "```TUNTAS -> Siap Lanjut Tahap Berikutnya```", inline = false }
        },
        footer = {
            text = "ZyloHub • Auto Mutasi Engine v3.9.0",
            icon_url = "https://cdn.discordapp.com/emojis/1083431442436894811.webp"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    sendHttpRequest(webhookUrl, {
        username = "ZyloHub Mutasi Monitor",
        avatar_url = "https://cdn.discordapp.com/emojis/1083431442436894811.webp",
        embeds = { embed }
    })
end

-- 2. Notifikasi Saat Mutasi Belum Sesuai & Mulai Dicuci (Clean Pet Shard)
function WebhookService:SendCleanLog(webhookUrl, petData, currentMutation, targetMutation)
    if not webhookUrl or webhookUrl == "" then return end

    local petName = petData.Name or "Pet"
    local age = tostring(petData.Age or 1)
    local weight = tostring(petData.Weight or "?")
    local playerName = LocalPlayer and LocalPlayer.Name or "Player"

    local embed = {
        title = "🧪 MUTASI TIDAK SESUAI -> AUTO CLEAN AKTIF",
        description = string.format("Pet **%s** mendapatkan mutasi **%s**, belum sesuai target **%s**. Memulai pencucian menggunakan Clean Pet Shard...", petName, currentMutation or "Normal", targetMutation or "Target"),
        color = 16744448, -- Warna Amber / Oranye
        fields = {
            { name = "👤 Akun", value = "```" .. playerName .. "```", inline = true },
            { name = "🐾 Nama Pet", value = "```" .. petName .. "```", inline = true },
            { name = "❌ Mutasi Saat Ini", value = "```" .. currentMutation .. "```", inline = true },
            { name = "🎯 Target Diinginkan", value = "```" .. targetMutation .. "```", inline = true },
            { name = "🧹 Tindakan", value = "```Gunakan Clean Pet Shard -> Masukkan Ulang Mesin```", inline = false }
        },
        footer = {
            text = "ZyloHub • Clean Mutasi Service",
            icon_url = "https://cdn.discordapp.com/emojis/1083431442436894811.webp"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    sendHttpRequest(webhookUrl, {
        username = "ZyloHub Mutasi Monitor",
        embeds = { embed }
    })
end

-- 3. Notifikasi Tes Webhook
function WebhookService:SendTest(webhookUrl)
    if not webhookUrl or webhookUrl == "" then return false, "URL kosong" end
    local embed = {
        title = "🔗 KONEKSI DISCORD WEBHOOK BERHASIL",
        description = "ZyloHub Auto Mutasi telah terhubung dengan webhook Discord Anda. Notifikasi hasil mutasi dan pencucian pet akan dikirimkan ke channel ini.",
        color = 3066993, -- Hijau Sukses
        footer = { text = "ZyloHub • Auto Mutasi Engine" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    return sendHttpRequest(webhookUrl, {
        username = "ZyloHub Test Webhook",
        embeds = { embed }
    })
end

return WebhookService
