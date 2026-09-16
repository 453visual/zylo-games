-- =========================================================================
--  ZYLOHUB - CLEAN MUTASI SERVICE (v1.0.0)
--  Repository: zylo-games/CleanMutasi.lua
--  Fungsi: Otomasi Penggunaan "Clean Pet Shard" untuk mereset mutasi pet
--  Alur: Cari Shard -> Pegang di tangan -> Klik pet target -> Auto Confirm
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local CleanMutasiService = {}

-- 1. Deteksi dan Klik Otomatis Tombol Confirm di Layar
local function AutoClickConfirmDialog()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return false end

    for _, gui in ipairs(pGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextButton") or desc:IsA("ImageButton") then
                    local btnText = (desc:IsA("TextButton") and desc.Text) or desc.Name
                    local lower = tostring(btnText):lower()
                    if lower:find("confirm") or lower:find("yes") or lower:find("ya") or lower:find("clean") then
                        pcall(function()
                            if desc.Visible then
                                if desc.MouseButton1Click then
                                    for _, con in pairs(getconnections(desc.MouseButton1Click)) do
                                        con:Fire()
                                    end
                                end
                                if desc.Activated then
                                    for _, con in pairs(getconnections(desc.Activated)) do
                                        con:Fire()
                                    end
                                end
                            end
                        end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- 2. Cari Item "Clean Pet Shard" di Tas atau Tangan Karakter
local function FindCleanPetShardTool()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local function checkContainer(cont)
        if not cont then return nil end
        for _, item in ipairs(cont:GetChildren()) do
            if item:IsA("Tool") then
                local nLow = item.Name:lower()
                if (nLow:find("clean") and nLow:find("shard")) or nLow:find("clean pet shard") or item:GetAttribute("IsCleanShard") then
                    return item
                end
            end
        end
        return nil
    end

    return checkContainer(character) or checkContainer(backpack)
end

-- 3. Eksekusi Pencucian Pet Menggunakan Shard
function CleanMutasiService:CleanPet(petTargetUUID, petTargetName)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not humanoid then return false, "Karakter tidak siap" end

    -- A. Cari item Clean Pet Shard
    local shardTool = FindCleanPetShardTool()
    if not shardTool then
        return false, "Clean Pet Shard tidak ditemukan di tas atau tangan!"
    end

    -- B. Pegang shard di tangan jika masih di dalam Backpack
    if shardTool.Parent == backpack then
        humanoid:EquipTool(shardTool)
        task.wait(0.4)
    end

    -- C. Temukan Model / Object Pet Target di Kebun atau Inventory
    local cleanUUID = tostring(petTargetUUID or ""):gsub("[{}]", "")
    local farm = workspace:FindFirstChild("Farm")
    local targetFound = false

    -- Cek model pet di kebun jika sedang di kebun
    if farm then
        for _, obj in ipairs(farm:GetDescendants()) do
            local u = obj:GetAttribute("UUID") or obj:GetAttribute("PET_UUID")
            if u and (tostring(u) == tostring(petTargetUUID) or tostring(u):gsub("[{}]", "") == cleanUUID) then
                -- Dekati pet jika perlu
                pcall(function()
                    if obj:IsA("Model") and obj.PrimaryPart then
                        character:PivotTo(obj.PrimaryPart.CFrame + Vector3.new(0, 2, 2))
                        task.wait(0.2)
                    end
                end)

                -- Interaksi dengan prompt atau klik
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    pcall(function() fireproximityprompt(prompt) end)
                    targetFound = true
                end
                break
            end
        end
    end

    -- D. Jika pet berupa Tool di tas/tangan
    if not targetFound then
        for _, t in ipairs(character:GetChildren()) do
            if t:IsA("Tool") and t ~= shardTool then
                local u = t:GetAttribute("PET_UUID") or t:GetAttribute("UUID") or (t:FindFirstChild("PET_UUID") and t.PET_UUID.Value)
                if u and (tostring(u) == tostring(petTargetUUID) or tostring(u):gsub("[{}]", "") == cleanUUID) then
                    targetFound = true
                    break
                end
            end
        end
    end

    -- E. Jalankan tool shard (Activated) untuk memicu pembersihan pada pet
    pcall(function()
        if shardTool and shardTool.Parent == character then
            shardTool:Activate()
        end
    end)
    task.wait(0.4)

    -- F. Tekan otomatis tombol Confirm pada dialog pembersihan
    local confirmed = false
    for attempt = 1, 6 do
        if AutoClickConfirmDialog() then
            confirmed = true
            break
        end
        task.wait(0.2)
    end

    task.wait(0.6)
    return true, "Proses clean shard dijalankan"
end

return CleanMutasiService
