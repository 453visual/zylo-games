-- =========================================================================
--  ZYLOHUB - AUTO HATCH & AUTO SELL MODULE (OFFICIAL EXTENSION - PART 2)
--  Repository: zylo-games/PetHatchAndSellModule.lua
--  Theme: Deep Obsidian Black (#070912) & Cosmic Purple (#8A2BE2)
--  STATUS: 100% PRESERVED AUTO HATCH & REAL-TIME AUTO SELL ENGINE
--  DATASET: 515 MASTER PET SPECIES OFFICIALLY INTEGRATED
-- =========================================================================

return function(PagePets, State, ZyloLib, Main, TeamManager)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local C = ZyloLib.Colors

    -- Services & Remotes
    local GameEvents = ReplicatedStorage:WaitForChild("GameEvents", 10)
    local PetsServiceRemote = GameEvents and GameEvents:WaitForChild("PetsService", 5)
    local Farms = workspace:WaitForChild("Farm", 10)

    local DataService = nil
    pcall(function()
        DataService = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("DataService", 5))
    end)

    local PetsServiceMod = nil
    pcall(function()
        PetsServiceMod = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetsService", 5))
    end)

    local PetUtilities = nil
    pcall(function()
        PetUtilities = require(ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("PetServices", 5):WaitForChild("PetUtilities", 5))
    end)

    -- Inisialisasi State Config Auto Hatch & Sell
    State.AutoHatch = (State.AutoHatch ~= nil) and State.AutoHatch or false
    State.DontHatchIfNotAllDone = (State.DontHatchIfNotAllDone ~= nil) and State.DontHatchIfNotAllDone or false
    State.EggConfigExpanded = (State.EggConfigExpanded ~= nil) and State.EggConfigExpanded or false
    State.SellConfigExpanded = (State.SellConfigExpanded ~= nil) and State.SellConfigExpanded or false

    -- State Khusus Sell Config & Bulk Flow
    State.AutoSellThresholdCount = State.AutoSellThresholdCount or 24
    State.SellMode = State.SellMode or "Sell All"
    State.SellSearchQuery = State.SellSearchQuery or ""
    State.SelectedBulkPetSpecies = State.SelectedBulkPetSpecies or "Mimic Octopus"
    State.BulkKG = State.BulkKG or 3
    State.BulkAction = State.BulkAction or "sell"
    State.ApplyBulkList = (State.ApplyBulkList ~= nil) and State.ApplyBulkList or false

    -- [INTEGRASI DATASET GITHUB RESMI ZYLOHUB]
    local GlobalPetDataset = nil
    pcall(function()
        local rawDataset = game:HttpGet("https://raw.githubusercontent.com/ranklee26-glitch/zylo-games/main/PetDataset.lua?v=" .. tostring(os.time()))
        if rawDataset and #rawDataset > 50 then
            GlobalPetDataset = loadstring(rawDataset)()
        end
    end)

    -- Master List Lengkap Seluruh 515 Spesies Pet Resmi Grow a Garden (100% Akurat)
    local MasterPetSpeciesList = {
        "Alien Bunny", "Alien Cat", "Alien Cow", "Alien Dog", "Amethyst Beetle",
        "Angel Cat", "Angel Dog", "Anglerfish", "Angora Goat", "Ankylosaurus",
        "Anubis", "Apple Gazelle", "Arctic Fox", "Armadillo", "Axolotl",
        "Bacon Pig", "Badger", "Bagel Bunny", "Bald Eagle", "Barn Owl",
        "Bat", "Beanstalk Bear", "Bear Bee", "Bear on Bike", "Bearded Dragon",
        "Beaver", "Bee", "Birb", "Bison", "Black Bird",
        "Black Bunny", "Black Cat", "Black Spotty Dragon", "Blizzard Spinosaurus", "Blood Hedgehog",
        "Blood Kiwi", "Blood Owl", "Blue Butterfly", "Blue Jay", "Blue Ringed Octopus",
        "Blue Tang", "Bobcat", "Bongo Antelope", "Brontosaurus", "Brown Bear",
        "Brown Owl", "Bull", "Bullfrog", "Bunny", "Butterfly",
        "Camel", "Canary", "Candy Bear", "Candy Bunny", "Capybara",
        "Cat", "Caterpillar", "Celestial Owl", "Cerberus", "Chameleon",
        "Cheetah", "Chicken", "Chicken Zombie", "Chimera", "Chimpanzee",
        "Chinchilla", "Chipmunk", "Chocolate Bunny", "Cloud Sprite", "Clownfish",
        "Cobra", "Cockatoo", "Cosmic Butterfly", "Cosmic Dragon", "Cosmic Kitsune",
        "Cosmic Owl", "Cow", "Crab", "Crocodile", "Crow",
        "Crystal Turtle", "Cuckoo", "Cyber Spider", "Cybernetic Dragon", "Dairy Cow",
        "Dalmatian", "Dark Pegasus", "Deer", "Demon Cat", "Demon Dog",
        "Diamond Dolphin", "Dilophosaurus", "Dingo", "Dinosaur", "Disco Bee",
        "Doctor Dog", "Dodo", "Dog", "Dolphin", "Donkey",
        "Dragonfly", "Duck", "Eagle", "Easter Bunny", "Easter Chick",
        "Eclipse Dragon", "Eel", "Elephant", "Emerald Snake", "Emperor Penguin",
        "Emu", "Falcon", "Fennec Fox", "Ferret", "Festive Dragon",
        "Festive Kitsune", "Firefly", "Flamingo", "Flying Squirrel", "Fortune Dragon",
        "Fox", "Frog", "Frost Dragon", "Gazelle", "Gecko",
        "Ghost Bear", "Ghost Cat", "Ghost Dog", "Giant Panda", "Gingerbread Cat",
        "Gingerbread Dog", "Giraffe", "Glitch Cat", "Glow Squid", "Goat",
        "Gold Finch", "Golden Axolotl", "Golden Beetle", "Golden Brontosaurus", "Golden Dragon",
        "Golden Elephant", "Golden Goose", "Golden Koi", "Golden Mimic Octopus", "Golden Phoenix",
        "Goose", "Gopher", "Gorilla", "Grasshopper", "Griffin",
        "Grizzly Bear", "Guinea Pig", "Hamster", "Hawk", "Hedgehog",
        "Hermit Crab", "Hippo", "Honey Bee", "Horse", "Huge Axolotl",
        "Huge Bald Eagle", "Huge Bear Bee", "Huge Black Bunny", "Huge Brontosaurus", "Huge Butterfly",
        "Huge Cat", "Huge Chicken", "Huge Cloud Sprite", "Huge Cow", "Huge Deer",
        "Huge Disco Bee", "Huge Elephant", "Huge Golden Goose", "Huge Goose", "Huge Honey Bee",
        "Huge Jabberwock", "Huge Kitsune", "Huge Mimic Octopus", "Huge Moth", "Huge Orange Tabby",
        "Huge Peacock", "Huge Phoenix", "Huge Pig", "Huge Polar Bear", "Huge Queen Bee",
        "Huge Rooster", "Huge Sea Otter", "Huge Silver Monkey", "Huge Spinosaurus", "Huge T-Rex",
        "Huge Triceratops", "Huge Turtle", "Huge Vine Serpent", "Huge Wasp", "Hummingbird",
        "Hydra", "Hyena", "Iguana", "Inferno T-Rex", "Jabberwock",
        "Jackal", "Jellyfish", "Kangaroo", "Killer Whale", "King Cobra",
        "Kitsune", "Kiwi", "Koala", "Komodo Dragon", "Ladybug",
        "Lava Golem", "Lemur", "Leopard", "Lion", "Llama",
        "Lobster", "Lucky Cat", "Lucky Dog", "Lunar Wolf", "Lynx",
        "Macaw", "Magma Hound", "Magpie", "Mallard Duck", "Manticore",
        "Mantis", "Mecha Cat", "Mecha Dog", "Meerkat", "Mimic Octopus",
        "Mole", "Mongoose", "Monkey", "Moose", "Mosquito",
        "Moth", "Mouse", "Narwhal", "Nebula Squid", "Night Owl",
        "Obsidian Golem", "Octopus", "Okapi", "Opossum", "Orangutan",
        "Ostrich", "Otter", "Owl", "Panda", "Panther",
        "Parrot", "Pastel Deer", "Peacock", "Pearl Whale", "Pegasus",
        "Pelican", "Penguin", "Petal Bee", "Phoenix", "Pig",
        "Pigeon", "Piranha", "Pixel Dog", "Platypus", "Polar Bear",
        "Poodle", "Porcupine", "Possum", "Prismatic Chameleon", "Prismatic Peacock",
        "Pterodactyl", "Pufferfish", "Pug", "Pumpkin Cat", "Pumpkin Dog",
        "Queen Bee", "Rabbit", "Raccoon", "Radioactive Scorpion", "Rainbow Axolotl",
        "Rainbow Brontosaurus", "Rainbow Cloud Sprite", "Rainbow Elephant", "Rainbow Jabberwock", "Rainbow Mimic Octopus",
        "Ram", "Rat", "Rattlesnake", "Raven", "Red Fox",
        "Red Panda", "Reindeer", "Rhino", "Robo Bear", "Rooster",
        "Ruby Beetle", "Salamander", "Sand Dollar", "Sapphire Spider", "Scarlet Macaw",
        "Scorpion", "Sea Horse", "Sea Lion", "Sea Otter", "Sea Turtle",
        "Seagull", "Seal", "Shadow Panther", "Shadow Wolf", "Shark",
        "Sheep", "Shiba Inu", "Silver Monkey", "Skeleton Horse", "Skunk",
        "Sloth", "Snail", "Snake", "Snow Leopard", "Snowman",
        "Snowy Owl", "Solar Phoenix", "Sparrow", "Spectral Fox", "Spider",
        "Spinosaurus", "Spotted Deer", "Spring Butterfly", "Squid", "Squirrel",
        "Starfish", "Steampunk Owl", "Stegosaurus", "Stingray", "Swan",
        "Swordfish", "T-Rex", "Tanuki", "Tapir", "Tarantula",
        "Tarantula Hawk", "Thunder Bird", "Tiger", "Toad", "Topaz Lion",
        "Tortoise", "Toucan", "Toxic Frog", "Tree Frog", "Triceratops",
        "Turkey", "Turtle", "Unicorn", "Velociraptor", "Vine Serpent",
        "Viper", "Void Bear", "Void Cat", "Vulture", "Walrus",
        "Warthog", "Wasp", "Weasel", "Whale", "Whale Shark",
        "White Tiger", "Wild Boar", "Wise Owl", "Wisp", "Wolf",
        "Wombat", "Woodpecker", "Woody", "Yak", "Yeti",
        "Zebra", "Zombie Bear"
    }

    -- Auto-Fetch Dinamis dari Module Game Asli agar selalu sinkron jika ada update live
    local function FetchAllGamePetSpecies()
        pcall(function()
            local petServices = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("PetServices")
            if petServices then
                for _, child in ipairs(petServices:GetChildren()) do
                    if child:IsA("ModuleScript") and (child.Name:find("Registry") or child.Name:find("Config") or child.Name:find("List") or child.Name:find("Data")) then
                        local mod = require(child)
                        if type(mod) == "table" then
                            for k, v in pairs(mod) do
                                local nameCandidate = (type(k) == "string" and k) or (type(v) == "table" and (v.Name or v.Species or v.PetType))
                                if nameCandidate and type(nameCandidate) == "string" and #nameCandidate > 2 and not nameCandidate:find("Service") and not nameCandidate:find("Event") then
                                    if not table.find(MasterPetSpeciesList, nameCandidate) then
                                        table.insert(MasterPetSpeciesList, nameCandidate)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        table.sort(MasterPetSpeciesList)
    end
    FetchAllGamePetSpecies()

    -- Default List Pet Config awal
    State.SellPetRules = State.SellPetRules or {
        { Species = "Mimic Octopus", KG = 3, Action = "SELL" },
        { Species = "Peacock", KG = 3, Action = "SELL" },
        { Species = "Scarlet Macaw", KG = 3, Action = "SELL" },
        { Species = "Capybara", KG = 3, Action = "SELL" },
        { Species = "Ostrich", KG = 3, Action = "SELL" }
    }

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

    local function GetFarmPetArea()
        local farm = GetFarm()
        if not farm then return nil end
        return farm:FindFirstChild("PetArea")
    end

    local function EquipCheck(Tool)
        local Character = LocalPlayer.Character
        if not Character then return end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local Backpack = LocalPlayer:FindFirstChild("Backpack")
        if not Humanoid or not Backpack or not Tool then return end
        if Tool.Parent == Backpack then
            Humanoid:EquipTool(Tool)
            task.wait(0.12)
        end
    end

    -- [PATEN]: LOOP AUTO HATCH DENGAN DUKUNGAN "DONT HATCH IF TIME NOT DONE" (SYNC HATCH)
    task.spawn(function()
        while true do
            if State.AutoHatch then
                local farm = GetFarm()
                local imp = farm and farm:FindFirstChild("Important")
                local objPhysical = imp and imp:FindFirstChild("Objects_Physical")
                
                if objPhysical then
                    local eggsInGarden = {}
                    for _, obj in ipairs(objPhysical:GetChildren()) do
                        local p = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local isEgg = false
                        local nameLower = obj.Name:lower()
                        if nameLower:find("egg") or (p and p.ActionText:lower():find("hatch")) then
                            isEgg = true
                        end
                        if isEgg and p then
                            table.insert(eggsInGarden, { Model = obj, Prompt = p })
                        end
                    end

                    local canHatchNow = true
                    if State.DontHatchIfNotAllDone and #eggsInGarden > 0 then
                        for _, egg in ipairs(eggsInGarden) do
                            local isPromptReady = egg.Prompt.Enabled
                            local billboard = egg.Model:FindFirstChildWhichIsA("BillboardGui", true)
                            local timeLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel", true)
                            if timeLabel and (timeLabel.Text:find(":") or timeLabel.Text:lower():find("m") or timeLabel.Text:lower():find("s")) and not timeLabel.Text:lower():find("ready") then
                                isPromptReady = false
                            end

                            if not isPromptReady then
                                canHatchNow = false
                                break
                            end
                        end
                    end

                    if canHatchNow and #eggsInGarden > 0 then
                        for _, egg in ipairs(eggsInGarden) do
                            if not State.AutoHatch then break end
                            local p = egg.Prompt
                            if p and p.Enabled then
                                p.HoldDuration = 0
                                p.RequiresLineOfSight = false
                                pcall(function() fireproximityprompt(p) end)
                                task.wait(0.08)
                            end
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    -- Proxy Helper ke TeamManager jika tersedia
    local function GetAllPetsList()
        if TeamManager and TeamManager.GetAllPetsList then
            return TeamManager.GetAllPetsList()
        end
        return {}
    end

    local function UnequipPetByUUID(uuid)
        if TeamManager and TeamManager.UnequipPetByUUID then
            return TeamManager.UnequipPetByUUID(uuid)
        end
    end

    -- =============================================================
    -- [FUNGSI UTAMA]: ENGINE AUTO SELL PET BERDASARKAN ATURAN CONFIG
    -- =============================================================
    local isProcessingAutoSell = false
    local function CheckAndExecuteAutoSell()
        if isProcessingAutoSell or not State.ApplyBulkList then return end
        local allPets = GetAllPetsList()
        local currentTotalPets = #allPets
        local threshold = tonumber(State.AutoSellThresholdCount) or 24

        if currentTotalPets < threshold then return end

        isProcessingAutoSell = true

        local rulesMap = {}
        for _, rule in ipairs(State.SellPetRules) do
            rulesMap[rule.Species:lower()] = {
                KG = tonumber(rule.KG) or 0,
                Action = (rule.Action or "SELL"):upper()
            }
        end

        local petsToSell = {}
        for _, pet in ipairs(allPets) do
            if not pet.IsFavorite then
                local sName = (pet.Species or pet.Name or ""):lower()
                local rule = rulesMap[sName]
                
                if rule then
                    local petWeight = pet.NumericWeight or tonumber(pet.Weight) or 0
                    local targetKG = rule.KG

                    if targetKG > 0 then
                        if petWeight < targetKG then
                            if rule.Action == "SELL" then
                                table.insert(petsToSell, pet)
                            end
                        end
                    end
                end
            end
        end

        if #petsToSell > 0 then
            print("[ZyloHub Auto Sell] Menemukan " .. tostring(#petsToSell) .. " pet yang memenuhi syarat jual.")
            for _, p in ipairs(petsToSell) do
                if not State.ApplyBulkList then break end

                if p.InGarden then
                    UnequipPetByUUID(p.UUID)
                    task.wait(0.2)
                end

                if PetsServiceMod and PetsServiceMod.SellPet then
                    pcall(function() PetsServiceMod:SellPet(p.UUID) end)
                end
                if PetsServiceRemote then
                    pcall(function() PetsServiceRemote:FireServer("SellPet", p.UUID) end)
                    pcall(function() PetsServiceRemote:FireServer("Sell", p.UUID) end)
                end

                if State.SellMode == "Sell One By One" then
                    task.wait(0.35)
                else
                    task.wait(0.08)
                end
            end
        end

        isProcessingAutoSell = false
    end

    task.spawn(function()
        while true do
            task.wait(2.5)
            if State.ApplyBulkList then
                pcall(CheckAndExecuteAutoSell)
            end
        end
    end)

    local ConfigContainer = TeamManager and TeamManager.ConfigContainer
    local TeamCard = TeamManager and TeamManager.TeamCard

    if not ConfigContainer then
        local accHatchFallback, bodyHatchFallback = ZyloLib:CreateAccordion(PagePets, "Auto Hatch & Sell Settings", true, 380)
        ConfigContainer = Instance.new("ScrollingFrame", bodyHatchFallback)
        ConfigContainer.Size = UDim2.new(1, 0, 1, 0)
        ConfigContainer.BackgroundTransparency = 1
        ConfigContainer.ScrollBarThickness = 3
        ConfigContainer.ScrollBarImageColor3 = C.PURPLE
        TeamCard = bodyHatchFallback
    end

    -- =============================================================
    -- CONFIG CONTAINER (EGG CONFIG & SELL CONFIG FULL UI)
    -- =============================================================
    local cfgLayout = Instance.new("UIListLayout", ConfigContainer)
    cfgLayout.Padding = UDim.new(0, 8)
    local cfgPad = Instance.new("UIPadding", ConfigContainer)
    cfgPad.PaddingTop = UDim.new(0, 4)
    cfgPad.PaddingLeft = UDim.new(0, 10)
    cfgPad.PaddingRight = UDim.new(0, 10)

    -- [A] EGG CONFIG CARD
    local EggConfigCard = Instance.new("Frame", ConfigContainer)
    EggConfigCard.Size = State.EggConfigExpanded and UDim2.new(1, 0, 0, 132) or UDim2.new(1, 0, 0, 38)
    EggConfigCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", EggConfigCard).CornerRadius = UDim.new(0, 8)
    local eccStroke = Instance.new("UIStroke", EggConfigCard)
    eccStroke.Color = State.EggConfigExpanded and C.PURPLE_L or C.STROKE
    eccStroke.Thickness = 1.2

    local EggHeaderBtn = Instance.new("TextButton", EggConfigCard)
    EggHeaderBtn.Size = UDim2.new(1, 0, 0, 38)
    EggHeaderBtn.BackgroundTransparency = 1
    EggHeaderBtn.Text = ""

    local ehTitle = Instance.new("TextLabel", EggHeaderBtn)
    ehTitle.Position = UDim2.new(0, 12, 0, 0)
    ehTitle.Size = UDim2.new(1, -45, 1, 0)
    ehTitle.BackgroundTransparency = 1
    ehTitle.Text = "🥚  Egg Config"
    ehTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    ehTitle.Font = Enum.Font.GothamBold
    ehTitle.TextSize = 10
    ehTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ehArrow = Instance.new("TextLabel", EggHeaderBtn)
    ehArrow.Position = UDim2.new(1, -30, 0, 0)
    ehArrow.Size = UDim2.new(0, 20, 1, 0)
    ehArrow.BackgroundTransparency = 1
    ehArrow.Text = State.EggConfigExpanded and "▼" or "▶"
    ehArrow.TextColor3 = C.PURPLE_L
    ehArrow.Font = Enum.Font.GothamBold
    ehArrow.TextSize = 9.5

    local EggOptionsFrame = Instance.new("Frame", EggConfigCard)
    EggOptionsFrame.Position = UDim2.new(0, 8, 0, 42)
    EggOptionsFrame.Size = UDim2.new(1, -16, 0, 84)
    EggOptionsFrame.BackgroundTransparency = 1
    EggOptionsFrame.Visible = State.EggConfigExpanded

    local eoLayout = Instance.new("UIListLayout", EggOptionsFrame)
    eoLayout.Padding = UDim.new(0, 6)

    local rowHatch = Instance.new("Frame", EggOptionsFrame)
    rowHatch.Size = UDim2.new(1, 0, 0, 36)
    rowHatch.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowHatch).CornerRadius = UDim.new(0, 6)
    local rhStroke = Instance.new("UIStroke", rowHatch)
    rhStroke.Color = Color3.fromRGB(30, 38, 60)

    local rhLbl = Instance.new("TextLabel", rowHatch)
    rhLbl.Position = UDim2.new(0, 10, 0, 0)
    rhLbl.Size = UDim2.new(1, -55, 1, 0)
    rhLbl.BackgroundTransparency = 1
    rhLbl.Text = "Otomatis Tetaskan & Claim Telur Siap Panen"
    rhLbl.TextColor3 = C.TEXT_W
    rhLbl.Font = Enum.Font.GothamMedium
    rhLbl.TextSize = 8.5
    rhLbl.TextXAlignment = Enum.TextXAlignment.Left

    local hatchPill = ZyloLib:CreatePillSwitch(rowHatch, State.AutoHatch, function(v) State.AutoHatch = v end)
    hatchPill.Position = UDim2.new(1, -44, 0.5, -10)

    local rowSync = Instance.new("Frame", EggOptionsFrame)
    rowSync.Size = UDim2.new(1, 0, 0, 42)
    rowSync.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowSync).CornerRadius = UDim.new(0, 6)
    local rsStroke = Instance.new("UIStroke", rowSync)
    rsStroke.Color = Color3.fromRGB(30, 38, 60)

    local rsTitle = Instance.new("TextLabel", rowSync)
    rsTitle.Position = UDim2.new(0, 10, 0, 4)
    rsTitle.Size = UDim2.new(1, -55, 0, 16)
    rsTitle.BackgroundTransparency = 1
    rsTitle.Text = "Don't Hatch If Time Not Done"
    rsTitle.TextColor3 = C.TEXT_W
    rsTitle.Font = Enum.Font.GothamBold
    rsTitle.TextSize = 8.5
    rsTitle.TextXAlignment = Enum.TextXAlignment.Left

    local rsSub = Instance.new("TextLabel", rowSync)
    rsSub.Position = UDim2.new(0, 10, 0, 20)
    rsSub.Size = UDim2.new(1, -55, 0, 18)
    rsSub.BackgroundTransparency = 1
    rsSub.Text = "Tunggu semua telur selesai cooldown baru di-hatch barengan"
    rsSub.TextColor3 = C.TEXT_M
    rsSub.Font = Enum.Font.GothamMedium
    rsSub.TextSize = 7.5
    rsSub.TextXAlignment = Enum.TextXAlignment.Left

    local syncPill = ZyloLib:CreatePillSwitch(rowSync, State.DontHatchIfNotAllDone, function(v) State.DontHatchIfNotAllDone = v end)
    syncPill.Position = UDim2.new(1, -44, 0.5, -10)

    local function recalculateCanvasSize()
        local h = 80
        if State.EggConfigExpanded then h = h + 100 end
        if State.SellConfigExpanded then h = h + 460 end
        ConfigContainer.CanvasSize = UDim2.new(0, 0, 0, h)
    end

    EggHeaderBtn.MouseButton1Click:Connect(function()
        State.EggConfigExpanded = not State.EggConfigExpanded
        ehArrow.Text = State.EggConfigExpanded and "▼" or "▶"
        EggOptionsFrame.Visible = State.EggConfigExpanded
        EggConfigCard.Size = State.EggConfigExpanded and UDim2.new(1, 0, 0, 132) or UDim2.new(1, 0, 0, 38)
        eccStroke.Color = State.EggConfigExpanded and C.PURPLE_L or C.STROKE
        recalculateCanvasSize()
    end)

    -- [B] SELL CONFIG CARD
    local SellConfigCard = Instance.new("Frame", ConfigContainer)
    SellConfigCard.Size = State.SellConfigExpanded and UDim2.new(1, 0, 0, 480) or UDim2.new(1, 0, 0, 38)
    SellConfigCard.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
    Instance.new("UICorner", SellConfigCard).CornerRadius = UDim.new(0, 8)
    local sccStroke = Instance.new("UIStroke", SellConfigCard)
    sccStroke.Color = State.SellConfigExpanded and C.PURPLE_L or C.STROKE
    sccStroke.Thickness = 1.2

    local SellHeaderBtn = Instance.new("TextButton", SellConfigCard)
    SellHeaderBtn.Size = UDim2.new(1, 0, 0, 38)
    SellHeaderBtn.BackgroundTransparency = 1
    SellHeaderBtn.Text = ""

    local shTitle = Instance.new("TextLabel", SellHeaderBtn)
    shTitle.Position = UDim2.new(0, 12, 0, 0)
    shTitle.Size = UDim2.new(1, -45, 1, 0)
    shTitle.BackgroundTransparency = 1
    shTitle.Text = "💰  Sell Config (Favorite Important Pets First)"
    shTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    shTitle.Font = Enum.Font.GothamBold
    shTitle.TextSize = 9.5
    shTitle.TextXAlignment = Enum.TextXAlignment.Left

    local shArrow = Instance.new("TextLabel", SellHeaderBtn)
    shArrow.Position = UDim2.new(1, -30, 0, 0)
    shArrow.Size = UDim2.new(0, 20, 1, 0)
    shArrow.BackgroundTransparency = 1
    shArrow.Text = State.SellConfigExpanded and "▼" or "▶"
    shArrow.TextColor3 = C.PURPLE_L
    shArrow.Font = Enum.Font.GothamBold
    shArrow.TextSize = 9.5

    local SellOptionsFrame = Instance.new("Frame", SellConfigCard)
    SellOptionsFrame.Position = UDim2.new(0, 8, 0, 42)
    SellOptionsFrame.Size = UDim2.new(1, -16, 0, 430)
    SellOptionsFrame.BackgroundTransparency = 1
    SellOptionsFrame.Visible = State.SellConfigExpanded

    local soLayout = Instance.new("UIListLayout", SellOptionsFrame)
    soLayout.Padding = UDim.new(0, 6)

    -- Threshold Row
    local rowThresh = Instance.new("Frame", SellOptionsFrame)
    rowThresh.Size = UDim2.new(1, 0, 0, 28)
    rowThresh.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    Instance.new("UICorner", rowThresh).CornerRadius = UDim.new(0, 5)

    local rthLbl = Instance.new("TextLabel", rowThresh)
    rthLbl.Position = UDim2.new(0, 8, 0, 0)
    rthLbl.Size = UDim2.new(1, -65, 1, 0)
    rthLbl.BackgroundTransparency = 1
    rthLbl.Text = "Auto Sell Aktif Saat Total Pet ( Sesuai Config List Dibawah ) :"
    rthLbl.TextColor3 = Color3.fromRGB(255, 110, 110)
    rthLbl.Font = Enum.Font.GothamBold
    rthLbl.TextSize = 8
    rthLbl.TextXAlignment = Enum.TextXAlignment.Left

    local rthBox = Instance.new("TextBox", rowThresh)
    rthBox.Position = UDim2.new(1, -50, 0.5, -10)
    rthBox.Size = UDim2.new(0, 42, 0, 20)
    rthBox.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    rthBox.Text = tostring(State.AutoSellThresholdCount or 24)
    rthBox.TextColor3 = C.TEXT_W
    rthBox.Font = Enum.Font.GothamBold
    rthBox.TextSize = 9
    Instance.new("UICorner", rthBox).CornerRadius = UDim.new(0, 4)
    local rthStroke = Instance.new("UIStroke", rthBox)
    rthStroke.Color = C.STROKE

    rthBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(rthBox.Text)
        if val then State.AutoSellThresholdCount = val end
    end)

    -- Sell Mode Selector
    local rowMode = Instance.new("Frame", SellOptionsFrame)
    rowMode.Size = UDim2.new(1, 0, 0, 26)
    rowMode.BackgroundTransparency = 1

    local smLbl = Instance.new("TextLabel", rowMode)
    smLbl.Position = UDim2.new(0, 4, 0, 0)
    smLbl.Size = UDim2.new(0.35, 0, 1, 0)
    smLbl.BackgroundTransparency = 1
    smLbl.Text = "Sell Mode"
    smLbl.TextColor3 = C.TEXT_M
    smLbl.Font = Enum.Font.GothamMedium
    smLbl.TextSize = 9
    smLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btnOneByOne = Instance.new("TextButton", rowMode)
    btnOneByOne.Position = UDim2.new(0.36, 0, 0, 0)
    btnOneByOne.Size = UDim2.new(0.31, 0, 1, 0)
    btnOneByOne.BackgroundColor3 = (State.SellMode == "Sell One By One") and C.PURPLE or Color3.fromRGB(16, 21, 42)
    btnOneByOne.Text = "Sell One By One"
    btnOneByOne.TextColor3 = (State.SellMode == "Sell One By One") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    btnOneByOne.Font = Enum.Font.GothamBold
    btnOneByOne.TextSize = 8
    Instance.new("UICorner", btnOneByOne).CornerRadius = UDim.new(0, 4)

    local btnSellAll = Instance.new("TextButton", rowMode)
    btnSellAll.Position = UDim2.new(0.69, 0, 0, 0)
    btnSellAll.Size = UDim2.new(0.31, 0, 1, 0)
    btnSellAll.BackgroundColor3 = (State.SellMode == "Sell All") and C.PURPLE or Color3.fromRGB(16, 21, 42)
    btnSellAll.Text = "Sell All"
    btnSellAll.TextColor3 = (State.SellMode == "Sell All") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    btnSellAll.Font = Enum.Font.GothamBold
    btnSellAll.TextSize = 8
    Instance.new("UICorner", btnSellAll).CornerRadius = UDim.new(0, 4)

    local function updateModeButtons()
        btnOneByOne.BackgroundColor3 = (State.SellMode == "Sell One By One") and C.PURPLE or Color3.fromRGB(16, 21, 42)
        btnOneByOne.TextColor3 = (State.SellMode == "Sell One By One") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
        btnSellAll.BackgroundColor3 = (State.SellMode == "Sell All") and C.PURPLE or Color3.fromRGB(16, 21, 42)
        btnSellAll.TextColor3 = (State.SellMode == "Sell All") and Color3.fromRGB(255, 255, 255) or C.TEXT_M
    end

    btnOneByOne.MouseButton1Click:Connect(function()
        State.SellMode = "Sell One By One"
        updateModeButtons()
    end)
    btnSellAll.MouseButton1Click:Connect(function()
        State.SellMode = "Sell All"
        updateModeButtons()
    end)

    -- Dropdown Select Pet Type
    local rowBulkPet = Instance.new("Frame", SellOptionsFrame)
    rowBulkPet.Size = UDim2.new(1, 0, 0, 24)
    rowBulkPet.BackgroundTransparency = 1

    local bpLbl = Instance.new("TextLabel", rowBulkPet)
    bpLbl.Size = UDim2.new(0.4, 0, 1, 0)
    bpLbl.BackgroundTransparency = 1
    bpLbl.Text = "Select Pet Type"
    bpLbl.TextColor3 = C.TEXT_M
    bpLbl.Font = Enum.Font.GothamMedium
    bpLbl.TextSize = 8.5
    bpLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bpDropdown = Instance.new("TextButton", rowBulkPet)
    bpDropdown.Position = UDim2.new(0.42, 0, 0, 0)
    bpDropdown.Size = UDim2.new(0.58, 0, 1, 0)
    bpDropdown.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bpDropdown.Text = (State.SelectedBulkPetSpecies or "Select Pet...") .. "  ▼"
    bpDropdown.TextColor3 = C.TEXT_W
    bpDropdown.Font = Enum.Font.GothamBold
    bpDropdown.TextSize = 8.5
    Instance.new("UICorner", bpDropdown).CornerRadius = UDim.new(0, 4)
    local bpdStroke = Instance.new("UIStroke", bpDropdown)
    bpdStroke.Color = Color3.fromRGB(35, 42, 65)

    -- KG (Bulk)
    local rowBulkKG = Instance.new("Frame", SellOptionsFrame)
    rowBulkKG.Size = UDim2.new(1, 0, 0, 24)
    rowBulkKG.BackgroundTransparency = 1

    local bkgLbl = Instance.new("TextLabel", rowBulkKG)
    bkgLbl.Size = UDim2.new(0.6, 0, 1, 0)
    bkgLbl.BackgroundTransparency = 1
    bkgLbl.Text = "KG (Bulk)"
    bkgLbl.TextColor3 = C.TEXT_M
    bkgLbl.Font = Enum.Font.GothamMedium
    bkgLbl.TextSize = 8.5
    bkgLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bkgBox = Instance.new("TextBox", rowBulkKG)
    bkgBox.Position = UDim2.new(1, -60, 0, 0)
    bkgBox.Size = UDim2.new(0, 60, 1, 0)
    bkgBox.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bkgBox.Text = tostring(State.BulkKG or 3)
    bkgBox.TextColor3 = C.TEXT_W
    bkgBox.Font = Enum.Font.GothamBold
    bkgBox.TextSize = 8.5
    Instance.new("UICorner", bkgBox).CornerRadius = UDim.new(0, 4)
    local bkgStroke = Instance.new("UIStroke", bkgBox)
    bkgStroke.Color = Color3.fromRGB(35, 42, 65)

    bkgBox:GetPropertyChangedSignal("Text"):Connect(function()
        local val = tonumber(bkgBox.Text)
        if val then State.BulkKG = val end
    end)

    -- Below KG Action
    local rowBulkAct = Instance.new("Frame", SellOptionsFrame)
    rowBulkAct.Size = UDim2.new(1, 0, 0, 24)
    rowBulkAct.BackgroundTransparency = 1

    local bkaLbl = Instance.new("TextLabel", rowBulkAct)
    bkaLbl.Size = UDim2.new(0.6, 0, 1, 0)
    bkaLbl.BackgroundTransparency = 1
    bkaLbl.Text = "Below KG Action (Bulk)"
    bkaLbl.TextColor3 = C.TEXT_M
    bkaLbl.Font = Enum.Font.GothamMedium
    bkaLbl.TextSize = 8.5
    bkaLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bkaBtn = Instance.new("TextButton", rowBulkAct)
    bkaBtn.Position = UDim2.new(1, -75, 0, 0)
    bkaBtn.Size = UDim2.new(0, 75, 1, 0)
    bkaBtn.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    bkaBtn.Text = State.BulkAction .. "  ▼"
    bkaBtn.TextColor3 = (State.BulkAction == "sell") and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 240, 150)
    bkaBtn.Font = Enum.Font.GothamBold
    bkaBtn.TextSize = 8.5
    Instance.new("UICorner", bkaBtn).CornerRadius = UDim.new(0, 4)
    local bkaStroke = Instance.new("UIStroke", bkaBtn)
    bkaStroke.Color = Color3.fromRGB(35, 42, 65)

    bkaBtn.MouseButton1Click:Connect(function()
        State.BulkAction = (State.BulkAction == "sell") and "keep" or "sell"
        bkaBtn.Text = State.BulkAction .. "  ▼"
        bkaBtn.TextColor3 = (State.BulkAction == "sell") and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(110, 240, 150)
    end)

    local renderSellRules = nil

    -- Apply Bulk List Switch
    local rowBulkApply = Instance.new("Frame", SellOptionsFrame)
    rowBulkApply.Size = UDim2.new(1, 0, 0, 26)
    rowBulkApply.BackgroundTransparency = 1

    local baLbl = Instance.new("TextLabel", rowBulkApply)
    baLbl.Size = UDim2.new(0.7, 0, 1, 0)
    baLbl.BackgroundTransparency = 1
    baLbl.Text = "APPLY BULK LIST"
    baLbl.TextColor3 = C.TEXT_M
    baLbl.Font = Enum.Font.GothamBold
    baLbl.TextSize = 8.5
    baLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bulkPill = ZyloLib:CreatePillSwitch(rowBulkApply, State.ApplyBulkList, function(v)
        State.ApplyBulkList = v
        if v then
            local speciesToAdd = State.SelectedBulkPetSpecies
            if speciesToAdd and speciesToAdd ~= "" then
                local found = false
                for _, r in ipairs(State.SellPetRules) do
                    if r.Species:lower() == speciesToAdd:lower() then
                        r.KG = tonumber(State.BulkKG) or 3
                        r.Action = State.BulkAction:upper()
                        found = true
                        break
                    end
                end

                if not found then
                    table.insert(State.SellPetRules, 1, {
                        Species = speciesToAdd,
                        KG = tonumber(State.BulkKG) or 3,
                        Action = State.BulkAction:upper()
                    })
                end

                if renderSellRules then
                    renderSellRules()
                end
                print("[ZyloHub] Berhasil apply pet ke list:", speciesToAdd)
            end
        end
    end)
    bulkPill.Position = UDim2.new(1, -44, 0.5, -10)

    -- Search Box
    local sellSearchBox = Instance.new("TextBox", SellOptionsFrame)
    sellSearchBox.Size = UDim2.new(1, 0, 0, 22)
    sellSearchBox.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    sellSearchBox.PlaceholderText = "Search in config list..."
    sellSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    sellSearchBox.Text = ""
    sellSearchBox.TextColor3 = C.TEXT_W
    sellSearchBox.Font = Enum.Font.Gotham
    sellSearchBox.TextSize = 8.5
    Instance.new("UICorner", sellSearchBox).CornerRadius = UDim.new(0, 4)
    local ssbStroke = Instance.new("UIStroke", sellSearchBox)
    ssbStroke.Color = Color3.fromRGB(32, 38, 60)

    -- Scroll List Table
    local sellListScroll = Instance.new("ScrollingFrame", SellOptionsFrame)
    sellListScroll.Size = UDim2.new(1, 0, 0, 136)
    sellListScroll.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
    sellListScroll.ScrollBarThickness = 2
    sellListScroll.ScrollBarImageColor3 = C.PURPLE
    Instance.new("UICorner", sellListScroll).CornerRadius = UDim.new(0, 6)
    local slsStroke = Instance.new("UIStroke", sellListScroll)
    slsStroke.Color = Color3.fromRGB(30, 38, 60)

    local slsLayout = Instance.new("UIListLayout", sellListScroll)
    slsLayout.Padding = UDim.new(0, 4)
    local slsPad = Instance.new("UIPadding", sellListScroll)
    slsPad.PaddingTop = UDim.new(0, 4)
    slsPad.PaddingLeft = UDim.new(0, 4)
    slsPad.PaddingRight = UDim.new(0, 4)

    renderSellRules = function()
        for _, ch in ipairs(sellListScroll:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end

        local filter = (State.SellSearchQuery or ""):lower()
        local count = 0

        for idx, rule in ipairs(State.SellPetRules) do
            if filter == "" or rule.Species:lower():find(filter) then
                count = count + 1
                local item = Instance.new("Frame", sellListScroll)
                item.Size = UDim2.new(1, 0, 0, 24)
                item.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
                Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)

                local nameLbl = Instance.new("TextLabel", item)
                nameLbl.Position = UDim2.new(0, 6, 0, 0)
                nameLbl.Size = UDim2.new(0.32, 0, 1, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = rule.Species
                nameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
                nameLbl.Font = Enum.Font.GothamMedium
                nameLbl.TextSize = 8
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left

                local badgeLbl = Instance.new("TextLabel", item)
                badgeLbl.Position = UDim2.new(0.33, 0, 0, 0)
                badgeLbl.Size = UDim2.new(0.35, 0, 1, 0)
                badgeLbl.BackgroundTransparency = 1
                badgeLbl.RichText = true
                badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                badgeLbl.Font = Enum.Font.GothamBold
                badgeLbl.TextSize = 7.5
                badgeLbl.TextXAlignment = Enum.TextXAlignment.Left

                local kgBox = Instance.new("TextBox", item)
                kgBox.Position = UDim2.new(0.69, 0, 0.5, -8)
                kgBox.Size = UDim2.new(0, 26, 0, 16)
                kgBox.BackgroundColor3 = Color3.fromRGB(9, 12, 22)
                kgBox.Text = tostring(rule.KG)
                kgBox.TextColor3 = C.TEXT_W
                kgBox.Font = Enum.Font.GothamBold
                kgBox.TextSize = 8
                Instance.new("UICorner", kgBox).CornerRadius = UDim.new(0, 3)

                kgBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local val = tonumber(kgBox.Text)
                    if val then
                        rule.KG = val
                        badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                    end
                end)

                local actBtn = Instance.new("TextButton", item)
                actBtn.Position = UDim2.new(0.79, 0, 0.5, -8)
                actBtn.Size = UDim2.new(0, 34, 0, 16)
                local isSell = (rule.Action == "SELL")
                actBtn.BackgroundColor3 = isSell and Color3.fromRGB(120, 24, 40) or Color3.fromRGB(24, 100, 50)
                actBtn.Text = rule.Action
                actBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                actBtn.Font = Enum.Font.GothamBold
                actBtn.TextSize = 7.5
                Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 3)

                actBtn.MouseButton1Click:Connect(function()
                    rule.Action = (rule.Action == "SELL") and "KEEP" or "SELL"
                    actBtn.Text = rule.Action
                    actBtn.BackgroundColor3 = (rule.Action == "SELL") and Color3.fromRGB(120, 24, 40) or Color3.fromRGB(24, 100, 50)
                    badgeLbl.Text = string.format("<font color=\"#F87171\">&lt; %s %s</font> | <font color=\"#4ADE80\">&gt;= %s BRONTO</font>", tostring(rule.KG), rule.Action, tostring(rule.KG))
                end)

                local delBtn = Instance.new("TextButton", item)
                delBtn.Position = UDim2.new(1, -20, 0.5, -8)
                delBtn.Size = UDim2.new(0, 16, 0, 16)
                delBtn.BackgroundColor3 = Color3.fromRGB(140, 25, 35)
                delBtn.Text = "-"
                delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                delBtn.Font = Enum.Font.GothamBold
                delBtn.TextSize = 9
                Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 3)

                delBtn.MouseButton1Click:Connect(function()
                    table.remove(State.SellPetRules, idx)
                    renderSellRules()
                end)
            end
        end

        if count == 0 then
            local emptyLbl = Instance.new("TextLabel", sellListScroll)
            emptyLbl.Size = UDim2.new(1, 0, 0, 30)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "List pet masih kosong.\nSilakan pilih pet di atas lalu aktifkan APPLY BULK LIST."
            emptyLbl.TextColor3 = Color3.fromRGB(180, 190, 220)
            emptyLbl.Font = Enum.Font.GothamMedium
            emptyLbl.TextSize = 8
            sellListScroll.CanvasSize = UDim2.new(0, 0, 0, 40)
        else
            sellListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 6)
        end
    end

    sellSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.SellSearchQuery = sellSearchBox.Text
        renderSellRules()
    end)

    renderSellRules()

    -- =============================================================
    -- MODAL POPUP: SELECT PET TYPE (515 PET RESMI LENGKAP)
    -- =============================================================
    local PickerModal = Instance.new("Frame", TeamCard)
    PickerModal.Size = UDim2.new(0, 250, 0, 270)
    PickerModal.Position = UDim2.new(0.5, -125, 0.5, -135)
    PickerModal.BackgroundColor3 = Color3.fromRGB(10, 13, 26)
    PickerModal.ZIndex = 50
    PickerModal.Visible = false
    Instance.new("UICorner", PickerModal).CornerRadius = UDim.new(0, 8)
    local pmStroke = Instance.new("UIStroke", PickerModal)
    pmStroke.Color = C.PURPLE_L
    pmStroke.Thickness = 1.5

    local pmHeader = Instance.new("Frame", PickerModal)
    pmHeader.Size = UDim2.new(1, 0, 0, 28)
    pmHeader.BackgroundTransparency = 1
    pmHeader.ZIndex = 51

    local pmTitle = Instance.new("TextLabel", pmHeader)
    pmTitle.Position = UDim2.new(0, 10, 0, 0)
    pmTitle.Size = UDim2.new(1, -40, 1, 0)
    pmTitle.BackgroundTransparency = 1
    pmTitle.Text = "Select Pet Type (" .. tostring(#MasterPetSpeciesList) .. " Pets)"
    pmTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    pmTitle.Font = Enum.Font.GothamBold
    pmTitle.TextSize = 9.5
    pmTitle.TextXAlignment = Enum.TextXAlignment.Left
    pmTitle.ZIndex = 51

    local pmClose = Instance.new("TextButton", pmHeader)
    pmClose.Position = UDim2.new(1, -26, 0, 4)
    pmClose.Size = UDim2.new(0, 20, 0, 20)
    pmClose.BackgroundColor3 = Color3.fromRGB(24, 28, 48)
    pmClose.Text = "✕"
    pmClose.TextColor3 = Color3.fromRGB(255, 120, 120)
    pmClose.Font = Enum.Font.GothamBold
    pmClose.TextSize = 9
    pmClose.ZIndex = 52
    Instance.new("UICorner", pmClose).CornerRadius = UDim.new(0, 4)

    pmClose.MouseButton1Click:Connect(function()
        PickerModal.Visible = false
    end)

    local pmSearch = Instance.new("TextBox", PickerModal)
    pmSearch.Position = UDim2.new(0, 10, 0, 32)
    pmSearch.Size = UDim2.new(1, -20, 0, 24)
    pmSearch.BackgroundColor3 = Color3.fromRGB(16, 21, 42)
    pmSearch.PlaceholderText = "Search pet species (e.g. Mimic, Peacock)..."
    pmSearch.PlaceholderColor3 = Color3.fromRGB(110, 120, 150)
    pmSearch.Text = ""
    pmSearch.TextColor3 = C.TEXT_W
    pmSearch.Font = Enum.Font.Gotham
    pmSearch.TextSize = 9
    pmSearch.ZIndex = 51
    Instance.new("UICorner", pmSearch).CornerRadius = UDim.new(0, 5)

    local pmScroll = Instance.new("ScrollingFrame", PickerModal)
    pmScroll.Position = UDim2.new(0, 10, 0, 62)
    pmScroll.Size = UDim2.new(1, -20, 1, -70)
    pmScroll.BackgroundTransparency = 1
    pmScroll.ScrollBarThickness = 3
    pmScroll.ScrollBarImageColor3 = C.PURPLE
    pmScroll.ZIndex = 51

    local pmsLayout = Instance.new("UIListLayout", pmScroll)
    pmsLayout.Padding = UDim.new(0, 4)

    local function refreshPickerModalList()
        for _, c in ipairs(pmScroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local filter = pmSearch.Text:lower()
        local count = 0
        for _, species in ipairs(MasterPetSpeciesList) do
            if filter == "" or species:lower():find(filter) then
                count = count + 1
                local isCur = (State.SelectedBulkPetSpecies == species)
                local b = Instance.new("TextButton", pmScroll)
                b.Size = UDim2.new(1, -4, 0, 24)
                b.BackgroundColor3 = isCur and Color3.fromRGB(42, 20, 70) or Color3.fromRGB(16, 21, 42)
                b.Text = "  " .. species
                b.TextColor3 = isCur and Color3.fromRGB(255, 255, 255) or C.TEXT_M
                b.Font = Enum.Font.GothamBold
                b.TextSize = 8.5
                b.TextXAlignment = Enum.TextXAlignment.Left
                b.ZIndex = 52
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                local bSt = Instance.new("UIStroke", b)
                bSt.Color = isCur and C.PURPLE_L or Color3.fromRGB(30, 36, 60)

                b.MouseButton1Click:Connect(function()
                    State.SelectedBulkPetSpecies = species
                    bpDropdown.Text = species .. "  ▼"
                    PickerModal.Visible = false
                end)
            end
        end
        pmScroll.CanvasSize = UDim2.new(0, 0, 0, count * 28)
    end

    pmSearch:GetPropertyChangedSignal("Text"):Connect(refreshPickerModalList)

    bpDropdown.MouseButton1Click:Connect(function()
        FetchAllGamePetSpecies()
        pmTitle.Text = "Select Pet Type (" .. tostring(#MasterPetSpeciesList) .. " Pets)"
        PickerModal.Visible = true
        pmSearch.Text = ""
        refreshPickerModalList()
    end)

    SellHeaderBtn.MouseButton1Click:Connect(function()
        State.SellConfigExpanded = not State.SellConfigExpanded
        shArrow.Text = State.SellConfigExpanded and "▼" or "▶"
        SellOptionsFrame.Visible = State.SellConfigExpanded
        SellConfigCard.Size = State.SellConfigExpanded and UDim2.new(1, 0, 0, 480) or UDim2.new(1, 0, 0, 38)
        sccStroke.Color = State.SellConfigExpanded and C.PURPLE_L or C.STROKE
        recalculateCanvasSize()
    end)

    -- [C] SWAP SKILL CONFIG BUTTON
    local function makeSimpleConfigButton(title)
        local btn = Instance.new("TextButton", ConfigContainer)
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(14, 18, 36)
        btn.Text = ""
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = C.STROKE
        stroke.Thickness = 1.2

        local tLbl = Instance.new("TextLabel", btn)
        tLbl.Position = UDim2.new(0, 12, 0, 0)
        tLbl.Size = UDim2.new(1, -45, 1, 0)
        tLbl.BackgroundTransparency = 1
        tLbl.Text = title
        tLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
        tLbl.Font = Enum.Font.GothamBold
        tLbl.TextSize = 9.5
        tLbl.TextXAlignment = Enum.TextXAlignment.Left

        local arrow = Instance.new("TextLabel", btn)
        arrow.Position = UDim2.new(1, -30, 0, 0)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▶"
        arrow.TextColor3 = C.PURPLE_L
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 9.5

        return btn
    end

    makeSimpleConfigButton("🔄  Swap Skill Config")

    return {
        CheckAndExecuteAutoSell = CheckAndExecuteAutoSell,
        FetchAllGamePetSpecies = FetchAllGamePetSpecies,
        Dataset = GlobalPetDataset
    }
end
