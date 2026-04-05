-- ==========================================
-- 🏹 SCRIPT: AUTO CUPID (V27 - ĐƠN GIẢN HÓA REPLAY THEO UI)
-- ==========================================
local WebhookURL = "https://discord.com/api/webhooks/1472994959404564490/D2gxRseTIKywjtkfRV8xvl1ra2fJ5rVRKtmJYIu23LRIXf_4wD6pbuto07WNzD20DVG4"
local LogoZiLi = "https://cdn.discordapp.com/attachments/1482474210243907747/1482474407300698132/0f77b7f8-7648-4aa3-bf67-545da725301a.png"
local NormalThumb = "https://api.rblx.solutions/v1/asset/thumbnail/108561234878560"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager") 
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- [5] BẢO VỆ TỐI THƯỢNG: KICK NẾU CÓ NGƯỜI JOIN SERVER
local function CheckPlayers()
    if #Players:GetPlayers() > 1 then
        Player:Kick("You are banned. if you think this is a false ban, please contact the support team via discord with sufficient evidence.")
    end
end
Players.PlayerAdded:Connect(CheckPlayers)
CheckPlayers()

-- [8] AUTO EQUIP TITLE
task.spawn(function()
    pcall(function()
        local args = { [1] = "Cupid's Nemesis" }
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"):InvokeServer(unpack(args))
    end)
end)

local RareImages = {
    ["Prestige Cupid's Chakram"] = true, 
    ["Cupid Queen's Maid Outfit"] = true,
    ["Leo's Inferno Hagoromo"] = true, 
    ["Cupid's All Seeing Eye"] = true
}

local NormalItems = {
    "Cupid's Harp", "Leo's Blazing Scarf", "Love Shades", "Cupid's Wand",
    "Love Boppers Headband", "Cupid's Battleaxe", "Leo's Blazing Regalia",
    "Virtuous Cupid Queen's Wings", "Maid Outfit", "SP Reset Essence",
    "Virtuous Cupid Queen's Outfit", "Cupid's Chakram"
}

local VIP_Fruits = {"dragon", "soul", "mochi", "venom", "tori", "pteranodon", "ope", "buddha", "pika", "mera", "yami", "smoke", "kage", "paw", "goru", "yuki", "magu", "suna", "goro", "hie", "gura", "zushi"}
local TRASH_Fruits = {"spin", "suke", "kilo", "heal", "bari", "mero", "horo", "yomi", "bomb", "gomu", "kira", "spring"}

-- BIẾN TOÀN CỤC CHỐNG LEAK RAM
local DungeonStartTime = tick()
local DungeonClearTimeStr = "00:00"
local SessionItems = {}        
local ProcessedItems = {}      
local ProcessedUITexts = {}    
local WebhookSentForSession = false
_G.IsProcessingFruit = false 
_G.EndGameStarted = false    
_G.GoToPortal = false        

-- ==========================================
-- [1] HÀM GỬI WEBHOOK
-- ==========================================
local function SendWebhook()
    if WebhookSentForSession then return end
    WebhookSentForSession = true

    local dropsText = ""
    local colorHex = 16758465
    local shouldPing = false

    if #SessionItems == 0 then
        dropsText = "```diff\n- Không có Item / Fruit nào```\n"
    else
        dropsText = "```diff\n"
        for _, item in ipairs(SessionItems) do
            dropsText = dropsText .. "+ " .. item .. "\n"
            if item:match("VIP") or item:match("RARE") then
                colorHex = 16711680
                shouldPing = true
            end
        end
        dropsText = dropsText .. "```\n"
    end

    local payload = {
        ["embeds"] = {{
            ["author"] = {["name"] = "🎁 Cupid Dungeon Summary 🎁"},
            ["title"] = shouldPing and "🔥 RARE / VIP DROPPED !!! 🔥" or "🎁 Dungeon Cleared Successfully!",
            ["color"] = colorHex,
            ["description"] = "━━━━━━━━━━━━━━━━━━━━━━\n:bust_in_silhouette: **User:** ||" .. Player.Name .. "||\n:stopwatch: **Clear Time:** `" .. DungeonClearTimeStr .. "`\n:map: **Map:** `Cupid Dungeon`\n━━━━━━━━━━━━━━━━━━━━━━\n### :sparkles: Session Drops:\n" .. dropsText,
            ["thumbnail"] = {["url"] = NormalThumb},
            ["footer"] = {["text"] = "ZiLi Hub | " .. os.date("%d/%m/%Y - %H:%M:%S"), ["icon_url"] = LogoZiLi}
        }}
    }
    if shouldPing then payload["content"] = "@everyone" end

    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if req then 
        task.spawn(function()
            pcall(function() req({Url = WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)}) end)
        end)
    end
end

-- ==========================================
-- [2] RADAR TRACK ĐỒ 0 MISS (DUAL FRAME 1 & 2)
-- ==========================================
task.spawn(function()
    local pGui = Player:WaitForChild("PlayerGui", 9e9)
    local notif = pGui:WaitForChild("Notifications", 9e9)

    local function CheckItemText(label)
        if not label or not label:IsA("TextLabel") then return end
        
        local function parseText()
            local rawText = string.gsub(label.Text, "<[^>]+>", "")
            local txt = string.lower(rawText)
            if txt == "" then return end

            for rareName, _ in pairs(RareImages) do
                if string.find(txt, string.lower(rareName), 1, true) then
                    local uniqueID = tostring(label) .. rareName
                    if not ProcessedUITexts[uniqueID] then
                        ProcessedUITexts[uniqueID] = true
                        table.insert(SessionItems, rareName .. " [ RARE ITEM ]")
                    end
                end
            end
            for _, normalName in ipairs(NormalItems) do
                if string.find(txt, string.lower(normalName), 1, true) then
                    local uniqueID = tostring(label) .. normalName
                    if not ProcessedUITexts[uniqueID] then
                        ProcessedUITexts[uniqueID] = true
                        table.insert(SessionItems, normalName .. " [ Normal Item ]")
                    end
                end
            end
        end

        parseText() 
        local conn = label:GetPropertyChangedSignal("Text"):Connect(parseText) 
        
        label.AncestryChanged:Connect(function(_, parent)
            if not parent then
                conn:Disconnect()
            end
        end)
    end

    local function SetupTracker(frameName)
        local frame = notif:FindFirstChild(frameName)
        if frame then
            for _, v in ipairs(frame:GetChildren()) do 
                CheckItemText(v) 
            end
            frame.ChildAdded:Connect(CheckItemText)
        end
    end

    SetupTracker("Frame")
    SetupTracker("Frame2")

    notif.ChildAdded:Connect(function(child)
        if child.Name == "Frame" or child.Name == "Frame2" then 
            SetupTracker(child.Name) 
        end
    end)
end)

-- ==========================================
-- [3] RADAR AUTO REPLAY (FIX TIMING & BỎ RÀO CẢN)
-- ==========================================
task.spawn(function()
    local isReplaying = false
    while _G.DungeonScriptID == currentScriptID do
        -- Không cần check cờ GoToPortal nữa, cứ bảng hiện ra là hốt
        if _G.AutoDungeon and not isReplaying then
            pcall(function()
                local prompt = Player.PlayerGui:FindFirstChild("ConfirmationPrompt")
                if prompt then
                    local main = prompt:FindFirstChild("Main")
                    local options = main and main:FindFirstChild("OptionsFrame")
                    local btn = options and options:FindFirstChild("Replay")
                    
                    if btn then
                        -- KIỂM TRA CHẮC CHẮN GIAO DIỆN ĐANG HIỂN THỊ (Không dùng .Enabled mù quáng nữa)
                        local isVisible = true
                        if prompt:IsA("ScreenGui") and prompt.Enabled == false then isVisible = false end
                        if main and main:IsA("GuiObject") and main.Visible == false then isVisible = false end
                        
                        if isVisible then
                            isReplaying = true
                            
                            -- [TIMING FIX]: Bắt chước thao tác tay, đợi 1.5 giây để Server chuẩn bị xong
                            print("⏳ Bảng Replay đã hiện! Đợi 1.5s để Server cho phép...")
                            task.wait(1.5)
                            
                            local val = btn:GetAttribute("buttonValue") or "Replay"
                            local remote = prompt:FindFirstChild("RemoteEvent")
                            
                            -- [CODE CHẠY TAY CỦA FEN]:
                            if not remote then
                                if getnilinstances then
                                    for _, v in next, getnilinstances() do
                                        if v.Name == "RemoteEvent" and v.Parent == nil then
                                            pcall(function() v:FireServer(val) end)
                                        end
                                    end
                                end
                                print("🚀 Đã thực thi lệnh Replay (Nil) gửi đi giá trị: " .. tostring(val))
                            else
                                pcall(function() remote:FireServer(val) end)
                                print("🚀 Đã thực thi lệnh Replay (UI) gửi đi giá trị: " .. tostring(val))
                            end
                            
                            -- Xử lý xong thì giấu cái bảng đi để script không quét trúng lại
                            if prompt:IsA("ScreenGui") then prompt.Enabled = false end
                            if main and main:IsA("GuiObject") then main.Visible = false end
                            
                            -- Khóa vòng lặp 5 giây chờ map mới load
                            task.wait(5)
                            isReplaying = false
                        end
                    end
                end
            end)
        end
        task.wait(0.5) -- Quét nhẹ 0.5s/lần, không tốn 1 giọt CPU/RAM
    end
end)

local function IsPotentialFruit(name)
    local n = name:lower()
    if n:match("fruit") or n == "tool" then return true end 
    for _, v in ipairs(VIP_Fruits) do 
        if n:match(v) or n == v then return true end 
    end
    for _, t in ipairs(TRASH_Fruits) do 
        if n:match(t) or n == t then return true end 
    end
    return false
end

-- ==========================================
-- [4] KHỐI ĐIỀU KHIỂN & COMBAT GỐC
-- ==========================================
if not _G.AntiKnockoutHook then
    _G.AntiKnockoutHook = true
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" then
                if self.Name == "KnockedOut" or self.Name == "Ragdoll" or self.Name == "Zombie" or self.Name == "Knock" then 
                    return nil 
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

if _G.CupidHeartbeat then 
    pcall(function() _G.CupidHeartbeat:Disconnect() end) 
end
if _G.CupidStepped then 
    pcall(function() _G.CupidStepped:Disconnect() end) 
end
_G.DungeonScriptID = (_G.DungeonScriptID or 0) + 1
local currentScriptID = _G.DungeonScriptID

_G.AutoDungeon = true
_G.ForceReblock = false 
print("▶️ Đã khởi chạy Auto Cupid Update 30 (V27 - ĐƠN GIẢN HÓA REPLAY)!\nSession ID: " .. currentScriptID)

local MoveSpeed = 95        
local AttackOffset = 10.5   
local SearchRadius = 800    
local WaitSpawnTime = 15          
local GatherTime = 2        
local DangerRadius = 45     
local EvadeDistance = 60    

local Zone5Points = {
    Vector3.new(-1166.94, 442.27, -3332.41), 
    Vector3.new(-995.78, 442.31, -3331.45), 
    Vector3.new(-962.64, 442.04, -3084.11), 
    Vector3.new(-1135.6, 442.67, -3102.46)
}
local EndPortalPos = Vector3.new(-1097.87, 672.92, -5379.12)
local Z5Index = 1 

local TargetCFrame = nil
local CurrentTargetRoot = nil
local IsReadyToAttack = false
local CurrentZoneIndex = 1
local ZoneState = "FLYING"
local PreviousZoneState = "FLYING"
local Timer = 0
local DodgeTimer = 0 
local CachedZoneFloors = {} 

local IgnoredHazards = setmetatable({}, {__mode = "k"}) 
local CurrentHazard = {Type = "None", Position = nil, Instance = nil, MinDist = DangerRadius} 
local CurrentLava = {Part = nil, Prompt = nil} 
local IsFarmingReady = false
local HasWaitedForLoad = false

local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if not fakePlatform then
    fakePlatform = Instance.new("Part")
    fakePlatform.Name = "CupidFakePlatform"
    fakePlatform.Size = Vector3.new(15, 1, 15)
    fakePlatform.Anchored = true
    fakePlatform.CanCollide = true
    fakePlatform.Transparency = 0.5
    fakePlatform.Parent = workspace
end

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local islands = workspace:FindFirstChild("Islands")
                    if islands then
                        local lobby = islands:FindFirstChild("Lobby")
                        local dungeon = islands:FindFirstChild("Cupid Dungeon")
                        local getPos = function(inst)
                            if not inst then return nil end
                            if inst:IsA("Model") and inst.PrimaryPart then 
                                return inst.PrimaryPart.Position 
                            end
                            local part = inst:FindFirstChildWhichIsA("BasePart", true)
                            if part then return part.Position end
                            return nil
                        end
                        local lPos = getPos(lobby)
                        local dPos = getPos(dungeon)
                        local rPos = root.Position
                        local lDist = lPos and (Vector2.new(lPos.X, lPos.Z) - Vector2.new(rPos.X, rPos.Z)).Magnitude or math.huge
                        local dDist = dPos and (Vector2.new(dPos.X, dPos.Z) - Vector2.new(rPos.X, rPos.Z)).Magnitude or math.huge

                        if dDist < lDist and dDist < 5000 then 
                            if not HasWaitedForLoad then
                                HasWaitedForLoad = true
                                IsFarmingReady = false
                                DungeonStartTime = tick() 
                                SessionItems = {}
                                ProcessedItems = {}
                                ProcessedUITexts = {}
                                WebhookSentForSession = false
                                _G.EndGameStarted = false
                                _G.GoToPortal = false
                                _G.IsProcessingFruit = false
                                task.wait(5)
                                CurrentZoneIndex = 1
                                ZoneState = "FLYING"
                                IsFarmingReady = true
                            end
                        else 
                            IsFarmingReady = false
                            HasWaitedForLoad = false 
                        end
                    end
                end
            end)
        end
        task.wait(1) 
    end
end)

local function GetZoneFloor(zoneIndex, boxCenter)
    if CachedZoneFloors[zoneIndex] then return CachedZoneFloors[zoneIndex] end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { Player.Character, fakePlatform, workspace:FindFirstChild("Effects"), workspace:FindFirstChild("Enemies") }
    local result = workspace:Raycast(boxCenter, Vector3.new(0, -300, 0), params)
    if result then 
        CachedZoneFloors[zoneIndex] = result.Position.Y
        return result.Position.Y 
    end
    return boxCenter.Y - 10 
end

local function GetRoot(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end 
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

local function GetMobsInZone(zonePos)
    local mobs = {}
    local currentSearchRadius = (CurrentZoneIndex == 8) and 1500 or SearchRadius
    
    if CurrentZoneIndex == 8 then
        local foundStatue = false
        pcall(function()
            local statuesFolder = workspace:FindFirstChild("Env") and workspace.Env:FindFirstChild("Statues")
            if statuesFolder then
                for _, statue in pairs(statuesFolder:GetChildren()) do
                    local sRoot = GetRoot(statue)
                    if sRoot then
                        local isAlive = false
                        local barrelHP = statue:FindFirstChild("barrelHP", true)
                        local hum = statue:FindFirstChild("Humanoid", true)
                        if barrelHP and barrelHP:IsA("ValueBase") then 
                            if tonumber(barrelHP.Value) and tonumber(barrelHP.Value) > 0 then 
                                isAlive = true 
                            end
                        elseif hum and hum.Health > 0.1 then 
                            isAlive = true 
                        end
                        if isAlive then 
                            table.insert(mobs, statue)
                            foundStatue = true 
                        end
                    end
                end
            end
        end)
        if foundStatue and #mobs > 0 then return mobs end
    end
    
    local possibleFolders = { workspace:FindFirstChild("Enemies"), workspace:FindFirstChild("Mob"), workspace:FindFirstChild("NPCs") }
    pcall(function() table.insert(possibleFolders, workspace.Effects.Zones["Zone" .. CurrentZoneIndex]) end)
    
    for _, folder in pairs(possibleFolders) do
        if folder then
            for _, v in pairs(folder:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                    local root = GetRoot(v)
                    if root and (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(zonePos.X, zonePos.Z)).Magnitude <= currentSearchRadius then 
                        table.insert(mobs, v) 
                    end
                end
             end
        end
    end
    return mobs
end

local function CheckAndEquipWeapon()
    if _G.IsProcessingFruit then return nil end
    local char = Player.Character
    if not char then return nil end 
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and (currentTool.Name:lower():match("sword") or currentTool.Name:lower():match("blade") or currentTool.Name:lower():match("axe") or currentTool.Name:lower():match("katana")) then 
        return currentTool 
    end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return currentTool end
    local sword = nil
    for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") and (t.Name:lower():match("sword") or t.Name:lower():match("blade") or t.Name:lower():match("axe") or t.Name:lower():match("katana")) then 
            sword = t
            break 
        end
    end
    if sword and currentTool ~= sword then 
        char.Humanoid:EquipTool(sword) 
    end
    return sword
end

task.spawn(function()
    local lastChar = nil
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                if char and char.Parent and lastChar ~= char then
                    lastChar = char
                    task.wait(2.5) 
                    local hasHaki = false
                    for _, v in pairs(char:GetDescendants()) do 
                        if v.Name:match("Buso") or v.Name:match("Haki") or v.Name:match("HasBuso") then 
                            hasHaki = true
                            break 
                        end 
                    end
                    if not hasHaki then 
                        ReplicatedStorage.Events.Haki:FireServer("Buso") 
                    end
                end
            end)
        end
        task.wait(1) 
    end
end)

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                for obj, expireTime in pairs(IgnoredHazards) do 
                    if tick() > expireTime or not obj:IsDescendantOf(workspace) then 
                        IgnoredHazards[obj] = nil 
                    end 
                end
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local playerPos = root.Position
                    local detectedHazard = "None"
                    local hazardPos = nil
                    local hazardInst = nil
                    local minDist = DangerRadius
                    local foundLavaPart = nil
                    local foundLavaPrompt = nil
                    
                    if workspace:FindFirstChild("Effects") then
                        local bossHazardDist = 0
                        local bossHazardInst = nil
                        if CurrentZoneIndex >= 7 then
                            for _, v in pairs(workspace.Effects:GetChildren()) do
                                local n = v.Name:lower()
                                if not IgnoredHazards[v] then
                                    if n:match("enkai") then 
                                        bossHazardDist = 100
                                        bossHazardInst = v
                                        break
                                    elseif n:match("pillar") or n:match("flame") then 
                                        bossHazardDist = 50
                                        bossHazardInst = v
                                        break 
                                    end
                                end
                            end
                        end
                        if bossHazardDist > 0 and CurrentTargetRoot then 
                            detectedHazard = "BossSkill"
                            hazardPos = CurrentTargetRoot.Position
                            minDist = bossHazardDist
                            hazardInst = bossHazardInst 
                        end

                        for _, v in pairs(workspace.Effects:GetChildren()) do 
                            local name = v.Name:lower()
                            local vPos = v:IsA("Model") and (v.PrimaryPart and v.PrimaryPart.Position or v:GetModelCFrame().Position) or (v:IsA("BasePart") and v.Position or nil)
                            if vPos then
                                local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude
                                if not IgnoredHazards[v] and (name:match("aoe") or name:match("circle") or name:match("bomb") or name:match("meteor") or name:match("lightning") or name:match("arrow") or name:match("rain") or name:match("projectile")) and dist < minDist and detectedHazard ~= "BossSkill" then
                                    detectedHazard = "Normal"
                                    hazardPos = vPos
                                    minDist = dist
                                    hazardInst = v
                                end
                                if name:match("lava curse") and dist < 1500 and not IgnoredHazards[v] then
                                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                                    if part and prompt and prompt.Enabled then 
                                        foundLavaPart = part
                                        foundLavaPrompt = prompt 
                                    end
                                end
                            end
                        end
                    end
                    CurrentHazard.Type = detectedHazard
                    CurrentHazard.Position = hazardPos
                    CurrentHazard.Instance = hazardInst
                    CurrentHazard.MinDist = minDist
                    CurrentLava.Part = foundLavaPart
                    CurrentLava.Prompt = foundLavaPrompt
                end
            end)
        end
        task.wait(0.05) 
    end
end)

task.spawn(function()
    local lastZone = 0
    local isHoldingLava = false 
    
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                if lastZone ~= CurrentZoneIndex then 
                    lastZone = CurrentZoneIndex 
                end
                local char = Player.Character
                if not char or not char.Parent then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                if CurrentZoneIndex > 8 then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil

                    if not _G.EndGameStarted then
                        _G.EndGameStarted = true
                        task.spawn(function()
                            if root then root.Velocity = Vector3.zero end
                            task.wait(2.5) 

                            pcall(function()
                                _G.IsProcessingFruit = true
                                local bp = Player:FindFirstChild("Backpack")
                                local hum = char and char:FindFirstChild("Humanoid")
                                if char and bp and hum then
                                    local tools = {}
                                    for _, v in ipairs(char:GetChildren()) do 
                                        if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end 
                                    end
                                    for _, v in ipairs(bp:GetChildren()) do 
                                        if v:IsA("Tool") and IsPotentialFruit(v.Name) then table.insert(tools, v) end 
                                    end
                                    
                                    for _, tool in ipairs(tools) do
                                        if not ProcessedItems[tool] then
                                            ProcessedItems[tool] = true
                                            pcall(function() hum:UnequipTools() end)
                                            task.wait(0.5)
                                            tool.Parent = char
                                            pcall(function() hum:EquipTool(tool) end)
                                            task.wait(2.5) 
                                            pcall(function() ReplicatedStorage:WaitForChild("Events"):WaitForChild("FruitStorage"):InvokeServer(true) end)
                                            task.wait(0.5)

                                            local activeTool = char:FindFirstChildOfClass("Tool") or tool
                                            local exactName = activeTool.Name:lower()
                                            local displayToolName = activeTool.Name
                                            local isVIP = false
                                            for _, vip in ipairs(VIP_Fruits) do 
                                                if exactName:match(vip) or exactName == vip then 
                                                    isVIP = true
                                                    break 
                                                end 
                                            end
                                            
                                            if isVIP then
                                                pcall(function() ReplicatedStorage.Events.FruitStorage:InvokeServer("Store", activeTool) end)
                                                task.wait(1.5)
                                                if activeTool.Parent == char or activeTool.Parent == bp then 
                                                    pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end) 
                                                    table.insert(SessionItems, displayToolName .. " [ VIP Fruit - Dropped ]")
                                                else 
                                                    table.insert(SessionItems, displayToolName .. " [ VIP Fruit - Stored ]") 
                                                end
                                            else
                                                pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end) 
                                                table.insert(SessionItems, displayToolName .. " [ Dropped ]")
                                            end
                                            pcall(function() hum:UnequipTools() end)
                                        end
                                    end
                                end
                            end)
                            _G.IsProcessingFruit = false

                            if not WebhookSentForSession then
                                local elapsed = tick() - DungeonStartTime
                                DungeonClearTimeStr = string.format("%02d:%02d", math.floor(elapsed / 60), math.floor(elapsed % 60))
                                SendWebhook()
                                task.wait(1.5) 
                            end
                            _G.GoToPortal = true
                        end)
                    end

                    if _G.GoToPortal then
                        ZoneState = "TO_PORTAL"
                        TargetCFrame = CFrame.new(EndPortalPos)
                    else
                        TargetCFrame = nil
                        if root then root.Velocity = Vector3.zero end
                    end
                    return 
                end

                local shouldAbsorbLava = false
                if CurrentLava.Part and CurrentLava.Prompt then
                    local lavaPos = CurrentLava.Part.Position
                    local zonePart = nil
                    pcall(function() zonePart = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]:FindFirstChild("Zone") end)
                    if zonePart then
                        local distToZone = (Vector2.new(lavaPos.X, lavaPos.Z) - Vector2.new(zonePart.Position.X, zonePart.Position.Z)).Magnitude
                        if distToZone <= 300 then shouldAbsorbLava = true end
                    else
                        local distToPlayer = (Vector2.new(lavaPos.X, lavaPos.Z) - Vector2.new(root.Position.X, root.Position.Z)).Magnitude
                        if distToPlayer <= 350 then shouldAbsorbLava = true end
                    end
                end

                if shouldAbsorbLava then
                    if ZoneState ~= "ABSORBING_CURSE" then 
                        PreviousZoneState = ZoneState
                        ZoneState = "ABSORBING_CURSE"
                        _G.LavaFailSafeTimer = tick() 
                    end
                    if tick() - _G.LavaFailSafeTimer > 10 then
                        if CurrentLava.Part and CurrentLava.Part.Parent then 
                            IgnoredHazards[CurrentLava.Part.Parent] = tick() + 60 
                        end
                        ZoneState = PreviousZoneState or "FLYING"
                        return
                    end
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    TargetCFrame = CFrame.new(CurrentLava.Part.Position) 
                    local realDist = (root.Position - CurrentLava.Part.Position).Magnitude
                    if realDist <= 12 then 
                        root.Velocity = Vector3.zero 
                        if not isHoldingLava then
                            isHoldingLava = true
                            task.spawn(function()
                                pcall(function()
                                    local p = CurrentLava.Prompt
                                    if p then
                                        p.RequiresLineOfSight = false
                                        p.MaxActivationDistance = 50
                                        local holdTime = p.HoldDuration > 0 and p.HoldDuration or 2.0
                                        p:InputHoldBegin()
                                        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                        task.wait(holdTime + 0.5)
                                        p:InputHoldEnd()
                                        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    end
                                end)
                                task.wait(0.5)
                                isHoldingLava = false
                            end)
                        end
                    end
                    return 
                else 
                    if ZoneState == "ABSORBING_CURSE" then 
                        ZoneState = PreviousZoneState or "FLYING" 
                    end 
                end

                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None" and ZoneState ~= "DODGING" then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    if CurrentHazard.Instance then 
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 6 
                    end
                    if ZoneState ~= "ABSORBING_CURSE" then 
                        PreviousZoneState = ZoneState 
                    end
                    ZoneState = "DODGING"
                    local evadeDir = (root.Position - CurrentHazard.Position)
                    if evadeDir.Magnitude < 0.1 then 
                        evadeDir = Vector3.new(1, 0, 0) 
                    end
                    local actEvadeDist = EvadeDistance
                    local extraWait = 2 
                    if CurrentHazard.Type == "BossSkill" then 
                        actEvadeDist = CurrentHazard.MinDist
                        extraWait = 2.5 
                    end
                    DodgeTimer = tick() + (actEvadeDist / MoveSpeed) + extraWait
                    TargetCFrame = CFrame.new(root.Position + Vector3.new(evadeDir.X, 0, evadeDir.Z).Unit * actEvadeDist)
                end

                if ZoneState == "DODGING" then
                    IsReadyToAttack = false
                    CurrentTargetRoot = nil
                    if tick() > DodgeTimer then 
                        ZoneState = PreviousZoneState or "FLYING"
                        CurrentHazard.Type = "None" 
                    else 
                        return 
                    end
                end

                local zonePart = nil
                pcall(function() zonePart = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]:FindFirstChild("Zone") end)
                if zonePart then
                    local boxCenter = zonePart.Position
                    local floorY = GetZoneFloor(CurrentZoneIndex, boxCenter)
                    local waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)
                    
                    local mobs = GetMobsInZone(boxCenter) 

                    if ZoneState == "FLYING" then
                        TargetCFrame = CFrame.new(Vector3.new(boxCenter.X, math.max(root.Position.Y, floorY + 40), boxCenter.Z))
                        CurrentTargetRoot = nil
                        if (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(boxCenter.X, boxCenter.Z)).Magnitude < 15 then
                            if CurrentZoneIndex == 5 then 
                                ZoneState = "ZONE5_SURVIVAL"
                                Timer = tick() + 30
                                Z5Index = 1 
                            else 
                                ZoneState = "WAITING_SPAWN"
                                Timer = tick() + WaitSpawnTime 
                            end
                        end
                    elseif ZoneState == "ZONE5_SURVIVAL" then
                        IsReadyToAttack = false
                        CurrentTargetRoot = nil
                        local currentZ5Target = Zone5Points[Z5Index]
                        TargetCFrame = CFrame.new(currentZ5Target)
                        if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(currentZ5Target.X, 0, currentZ5Target.Z)).Magnitude < 10 then 
                            Z5Index = Z5Index < #Zone5Points and Z5Index + 1 or 1 
                        end
                        if tick() > Timer then 
                            CurrentZoneIndex = CurrentZoneIndex + 1
                            ZoneState = "FLYING"
                            task.wait(0.2) 
                        end
                    elseif ZoneState == "WAITING_SPAWN" then
                        TargetCFrame = CFrame.new(waitPos)
                        CurrentTargetRoot = nil
                        if #mobs > 0 then 
                            ZoneState = "GATHERING"
                            Timer = tick() + GatherTime 
                        elseif tick() > Timer then 
                            CurrentZoneIndex = CurrentZoneIndex + 1
                            ZoneState = "FLYING"
                            task.wait(0.2) 
                        end
                    elseif ZoneState == "GATHERING" then
                        if #mobs > 0 then 
                            CurrentTargetRoot = GetRoot(mobs[1]) 
                        end 
                        if tick() > Timer then 
                            ZoneState = "ATTACKING" 
                        end
                    elseif ZoneState == "ATTACKING" then
                        if #mobs == 0 then 
                            ZoneState = "VERIFY_CLEAR"
                            Timer = tick() + 2
                        else 
                            CurrentTargetRoot = GetRoot(mobs[1])
                            IsReadyToAttack = true 
                        end
                    elseif ZoneState == "VERIFY_CLEAR" then
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            if CurrentZoneIndex == 7 then 
                                ZoneState = "WAIT_30S"
                                Timer = tick() + 20
                                IsReadyToAttack = false
                                CurrentTargetRoot = nil
                            else 
                                CurrentZoneIndex = CurrentZoneIndex + 1
                                ZoneState = "FLYING"
                                IsReadyToAttack = false
                                CurrentTargetRoot = nil
                                task.wait(0.2) 
                            end
                        end
                    elseif ZoneState == "WAIT_30S" then
                        TargetCFrame = CFrame.new(waitPos)
                        CurrentTargetRoot = nil
                        IsReadyToAttack = false
                        if tick() > Timer then 
                            CurrentZoneIndex = 8
                            ZoneState = "FLYING" 
                        end
                    end
                else 
                    TargetCFrame = nil
                    CurrentTargetRoot = nil
                    IsReadyToAttack = false
                    ZoneState = "FLYING"
                    task.wait(0.5) 
                end
            end)
        end
        task.wait(0.1) 
    end
end)

local BlockHoldTime = 0
local function IsMobAttacking(hum)
    local isAttacking = false
    pcall(function()
        local animator = hum:FindFirstChild("Animator") or hum
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Weight > 0.01 and track.Animation then
                local animName = track.Animation.Name:lower()
                if not (animName:match("idle") or animName:match("walk") or animName:match("run") or animName:match("stun") or animName:match("hit")) then
                    if animName:match("attack") or animName:match("slash") or animName:match("punch") or animName:match("swing") or animName:match("cast") or animName:match("skill") or animName:match("m1") or animName:match("slam") or animName:match("smash") or animName:match("charge") or animName:match("burst") or animName:match("combo") or animName:match("shoot") or animName:match("fire") or animName:match("gun") or animName:match("ranged") or animName:match("magic") or animName:match("throw") or animName:match("shot") then 
                        isAttacking = true
                        break 
                    end
                end
            end
        end
    end)
    return isAttacking
end

task.spawn(function()
    local BlockEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Block") 
    local lastBlockState = false 
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local weapon = char and char:FindFirstChildOfClass("Tool")
                local weaponName = weapon and weapon.Name or "Melee"
                local shouldBlock = false
                
                if root then
                    if CurrentZoneIndex >= 7 and CurrentZoneIndex <= 8 then 
                        if #GetMobsInZone(root.Position) > 0 then 
                            shouldBlock = true 
                        end
                    elseif CurrentHazard.Type ~= "None" then 
                        shouldBlock = true
                    elseif IsReadyToAttack then
                        local blockDist = 80 
                        for _, mob in pairs(GetMobsInZone(root.Position)) do
                            local hum = mob:FindFirstChild("Humanoid")
                            if hum and IsMobAttacking(hum) and (GetRoot(mob).Position - root.Position).Magnitude < blockDist then 
                                shouldBlock = true
                                break 
                            end
                        end
                    end
                end

                if shouldBlock then 
                    BlockHoldTime = tick() + 0.5 
                elseif tick() < BlockHoldTime then 
                    shouldBlock = true 
                end
                
                if shouldBlock ~= lastBlockState or _G.ForceReblock then
                    lastBlockState = shouldBlock
                    _G.ForceReblock = false
                    task.spawn(function() 
                        pcall(function() 
                            if BlockEvent:IsA("RemoteFunction") then 
                                BlockEvent:InvokeServer(shouldBlock, weaponName, false)
                            else 
                                BlockEvent:FireServer(shouldBlock, weaponName, false) 
                            end
                        end) 
                    end)
                    pcall(function() 
                        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        if shouldBlock then 
                            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                        end
                    end)
                end
            end)
        end
        task.wait(0.05) 
    end
end)

local function GetAttackAnim(weaponName, combo)
    if _G.IsProcessingFruit then return "Melee", nil end
    local wType = "Melee"
    local anim = nil
    local swordModules = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("SwordHandle") and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")
    
    if swordModules and swordModules:FindFirstChild(weaponName) then
        wType = "Sword"
        local folder = swordModules[weaponName]:FindFirstChild("Slashes")
        if folder then
            anim = folder:FindFirstChild("Slash"..combo) or folder:FindFirstChild("GroundSlash"..combo) or folder:FindFirstChild("Swing"..combo)
            if not anim then 
                for _, a in pairs(folder:GetChildren()) do 
                    if string.find(a.Name, tostring(combo)) then 
                        anim = a
                        break 
                    end 
                end 
            end
        end 
        return wType, anim
    end
    
    wType = weaponName
    local folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName)
    if not folder then 
        folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Melee")
        wType = "Melee" 
    end
    
    if folder then
        anim = folder:FindFirstChild("Punch"..combo) or folder:FindFirstChild("M1_"..combo) or folder:FindFirstChild("Kick"..combo) or folder:FindFirstChild("Slash"..combo)
        if not anim then 
            for _, a in pairs(folder:GetChildren()) do 
                if string.find(a.Name, tostring(combo)) then 
                    anim = a
                    break 
                end 
            end 
        end
    end 
    return wType, anim
end

task.spawn(function()
    local CombatRegister = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local currentCombo = 1
    local strikeDelay = 0.366
    local comboResetDelay = 1.0     
    while _G.DungeonScriptID == currentScriptID do
        local currentDelay = strikeDelay 
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            local char = Player.Character
            if char and char.Parent then
                pcall(function()
                    local tool = CheckAndEquipWeapon() 
                    local realWeaponName = tool and tool.Name or "Melee"
                    local weaponType, fakeAnim = GetAttackAnim(realWeaponName, currentCombo)

                    if not fakeAnim then 
                        currentCombo = 1
                        task.wait(comboResetDelay)
                        return 
                    end
                    
                    local enemiesToHit = {}
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local primaryCFrame = nil 

                    if root then
                        for _, m in pairs(GetMobsInZone(root.Position)) do
                            local eRoot = GetRoot(m)
                            if eRoot and (eRoot.Position - root.Position).Magnitude <= 300 then 
                                table.insert(enemiesToHit, eRoot)
                                table.insert(enemiesToHit, m) 
                                if not primaryCFrame then 
                                    primaryCFrame = eRoot.CFrame 
                                end
                            end
                        end
                    end
                    
                    if not primaryCFrame and root then 
                        primaryCFrame = root.CFrame 
                    end

                    if #enemiesToHit > 0 and primaryCFrame then
                        local state = "Ground" 
                        task.spawn(function() 
                            pcall(function() 
                                CombatRegister:InvokeServer({[1] = "swingsfx", [2] = weaponType, [3] = currentCombo, [4] = state, [5] = false, [6] = fakeAnim, [7] = 2, [8] = 1.5}) 
                            end) 
                        end)
                        task.spawn(function() 
                            pcall(function() 
                                CombatRegister:InvokeServer({[1] = "damage", [2] = enemiesToHit, [3] = weaponType, [4] = { [1] = currentCombo, [2] = state, [3] = weaponType }, [5] = true, [6] = primaryCFrame, ["aircombo"] = state}) 
                            end) 
                        end)
                        
                        if CurrentZoneIndex >= 7 and CurrentZoneIndex <= 8 then 
                            _G.ForceReblock = true 
                        end
                        
                        currentCombo = currentCombo + 1
                        local _, nextAnim = GetAttackAnim(realWeaponName, currentCombo)
                        if not nextAnim then 
                            currentDelay = comboResetDelay
                            currentCombo = 1 
                        end
                    else 
                        currentCombo = 1 
                    end
                end)
            else 
                currentCombo = 1 
            end
        else 
            currentCombo = 1 
        end
        task.wait(currentDelay) 
    end
end)

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if char and char.Parent then
                    if hum then
                        hum.PlatformStand = false
                        hum.Sit = false
                        hum.AutoRotate = true 
                        local state = hum:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Physics then 
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp) 
                        end
                    end
                    if root and root.Anchored then 
                        root.Anchored = false 
                    end
                    if root then 
                        for _, v in pairs(root:GetChildren()) do 
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then 
                                v:Destroy() 
                            end 
                        end 
                    end
                end
            end)
        end
        task.wait(0.1) 
    end
end)

_G.CupidStepped = RunService.Stepped:Connect(function()
    if not _G.AutoDungeon or not IsFarmingReady then return end
    if _G.IsProcessingFruit then return end 
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not char.Parent then return end

    pcall(function()
        _G.canuse = true
        _G.midM1 = false
        _G.blocking = false
        _G.knocked = false
        _G.ragdoll = false
        _G.stunned = false
        _G.zombie = false
        
        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        
        for attr, _ in pairs(char:GetAttributes()) do
            if type(attr) == "string" then
                local a = attr:lower()
                if a:match("stun") or a:match("busy") or a:match("freeze") or a:match("knock") or a:match("ragdoll") or a:match("zombie") or a:match("down") then 
                    char:SetAttribute(attr, nil) 
                end
            end
        end
        
        for _, v in pairs(char:GetChildren()) do 
            if v:IsA("BasePart") then 
                v.CanCollide = false 
            elseif v:IsA("ValueBase") then 
                local n = v.Name:lower()
                if n:match("stun") or n:match("knock") or n:match("ragdoll") or n:match("zombie") or n:match("busy") then 
                    v:Destroy() 
                end
            else 
                local name = v.Name:lower()
                if name:match("stun") or name:match("knock") or name == "ragdoll" or name == "zombie" then 
                    v:Destroy() 
                end 
            end 
        end
    end)
end)

_G.CupidHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not _G.AutoDungeon then return end
    if not IsFarmingReady then 
        if fakePlatform then fakePlatform.CFrame = CFrame.new(0, -9999, 0) end 
        return 
    end
    if _G.IsProcessingFruit then return end 
    
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not char or not root or not char.Parent then return end
    
    if fakePlatform then 
        fakePlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z) 
    end
    
    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then 
        activeTargetPos = Vector3.new(CurrentTargetRoot.Position.X, CurrentTargetRoot.Position.Y + AttackOffset, CurrentTargetRoot.Position.Z)
    elseif TargetCFrame then 
        activeTargetPos = TargetCFrame.Position 
    end
    
    if activeTargetPos then
        local currentPos = root.Position
        local dist = (currentPos - activeTargetPos).Magnitude
        local newPos = currentPos
        
        if dist > 0.5 then
            local step = (activeTargetPos - currentPos).Unit * MoveSpeed * dt
            if step.Magnitude >= dist then 
                newPos = activeTargetPos 
            else 
                newPos = currentPos + step 
            end
        else 
            newPos = activeTargetPos 
        end

        if IsReadyToAttack then
            local _, currentYaw, _ = root.CFrame:ToOrientation()
            root.CFrame = CFrame.new(newPos) * CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        else
            local flatDir = Vector3.new(activeTargetPos.X - currentPos.X, 0, activeTargetPos.Z - currentPos.Z)
            if dist > 0.1 and flatDir.Magnitude > 0.01 then
                local targetRot = CFrame.lookAt(newPos, newPos + flatDir.Unit)
                local lerpFactor = 1 - math.exp(-12 * dt)
                local smoothRot = root.CFrame:Lerp(targetRot, lerpFactor).Rotation
                root.CFrame = CFrame.new(newPos) * smoothRot
            else 
                root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation 
            end
        end

        if IsReadyToAttack and ZoneState ~= "ABSORBING_CURSE" then
            if hum then 
                root.Velocity = Vector3.new(root.CFrame.LookVector.X * hum.WalkSpeed, 0, root.CFrame.LookVector.Z * hum.WalkSpeed) 
            end
            root.RotVelocity = Vector3.new(0, 0, 0)
            pcall(function()
                if hum then hum:Move(Vector3.new(0.01, 0, 0.01), false) end
                local footstepEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("footstep")
                if footstepEvent then footstepEvent:FireServer() end
            end)
        end
    end
end)
