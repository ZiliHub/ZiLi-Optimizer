-- ==========================================
-- 🏹 SCRIPT: AUTO CUPID (V8 - IMPROVE)
-- Game: GET BETTER OUT | Cupid Dungeon
-- V8 Changes vs V7:
--   [1]  🔄 Block spin fix: park fakePlatform trước khi restore CanCollide
--          → không còn bounce collision → không sinh RotVelocity
--   [2]  🔄 Block spin fix: spam RotVelocity=0 + AssemblyAngularVelocity=0
--          5× trong 0.15s ngay sau khi nhả block key
--   [3]  🔄 Block spin fix: reset RotVelocity mỗi frame TRONG block window
--          (Heartbeat SkillBlocking branch) để không accumulate
--   [4]  ⚡ ArrowRain: dodge xa 80 studs, KHÔNG block sau (đúng theo yêu cầu)
--   [5]  ⚡ Lightning: đứng tại chỗ hold block 1.5s, KHÔNG dodge
--          → thêm branch action=="BLOCK" trong DODGE TRIGGER
--   [6]  🧹 Xóa dead code branch "ArrowLightning" (type này không bao giờ được set)
--   [7]  🧹 DODGING state machine: đơn giản hóa, xóa elseif không bao giờ trigger
-- ==========================================

local WebhookURL  = "https://discord.com/api/webhooks/1472994959404564490/D2gxRseTIKywjtkfRV8xvl1ra2fJ5rVRKtmJYIu23LRIXf_4wD6pbuto07WNzD20DVG4"
local LogoZiLi    = "https://cdn.discordapp.com/attachments/1482474210243907747/1482474407300698132/0f77b7f8-7648-4aa3-bf67-545da725301a.png"
local NormalThumb = "https://api.rblx.solutions/v1/asset/thumbnail/108561234878560"

local HttpService       = game:GetService("HttpService")
local Players           = game:GetService("Players")
local Player            = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM               = game:GetService("VirtualInputManager")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")

-- ==========================================
-- [0] SESSION ID — PHẢI ĐỨNG ĐẦU
-- ==========================================
if _G.CupidHeartbeat then pcall(function() _G.CupidHeartbeat:Disconnect() end) end
if _G.CupidStepped    then pcall(function() _G.CupidStepped:Disconnect()    end) end

_G.DungeonScriptID = (_G.DungeonScriptID or 0) + 1
local currentScriptID = _G.DungeonScriptID

_G.AutoDungeon       = true
_G.IsProcessingFruit = false
_G.EndGameStarted    = false
_G.GoToPortal        = false
_G.SkillBlocking     = false  -- V4: controlled by TriggerSkillBlock()

print("▶️ Auto Cupid V4 (IMPROVE) — Session:", currentScriptID)

-- ==========================================
-- [1] BẢO VỆ TỐI THƯỢNG
-- ==========================================
local function CheckPlayers()
    if #Players:GetPlayers() > 1 then
        Player:Kick("You are banned. if you think this is a false ban, please contact the support team via discord with sufficient evidence.")
    end
end
Players.PlayerAdded:Connect(CheckPlayers)
CheckPlayers()

-- ==========================================
-- [2] AUTO EQUIP TITLE
-- ==========================================
task.spawn(function()
    pcall(function()
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Titles"):InvokeServer("Cupid's Nemesis")
    end)
end)

-- ==========================================
-- [3] DATA
-- ==========================================
local RareImages = {
    ["Prestige Cupid's Chakram"]  = true,
    ["Cupid Queen's Maid Outfit"] = true,
    ["Leo's Inferno Hagoromo"]    = true,
    ["Cupid's All Seeing Eye"]    = true,
}
local NormalItems = {
    "Cupid's Harp","Leo's Blazing Scarf","Love Shades","Cupid's Wand",
    "Love Boppers Headband","Cupid's Battleaxe","Leo's Blazing Regalia",
    "Virtuous Cupid Queen's Wings","Maid Outfit","SP Reset Essence",
    "Virtuous Cupid Queen's Outfit","Cupid's Chakram",
}
local VIP_Fruits   = {"dragon","soul","mochi","venom","tori","pteranodon","ope","buddha","pika","mera","yami","smoke","kage","paw","goru","yuki","magu","suna","goro","hie","gura","zushi"}
local TRASH_Fruits = {"spin","suke","kilo","heal","bari","mero","horo","yomi","bomb","gomu","kira","spring"}

-- ==========================================
-- [4] BIẾN SESSION
-- ==========================================
local DungeonStartTime      = tick()
local DungeonClearTimeStr   = "00:00"
local SessionItems          = {}
local ProcessedItems        = {}
local ProcessedLabels       = setmetatable({}, {__mode = "k"})
local WebhookSentForSession = false

-- ==========================================
-- [5] ANTI KNOCKOUT HOOK
-- ==========================================
if not _G.AntiKnockoutHook then
    _G.AntiKnockoutHook = true
    pcall(function()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "FireServer" then
                if self.Name == "KnockedOut" or self.Name == "Ragdoll"
                or self.Name == "Zombie"      or self.Name == "Knock" then
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
end

-- ==========================================
-- [6] WEBHOOK
-- ==========================================
local function SendWebhook()
    if WebhookSentForSession then return end
    WebhookSentForSession = true

    local rareDrops, vipDrops, normalDrops = {}, {}, {}
    local shouldPing = false

    for _, item in ipairs(SessionItems) do
        if item:match("%[ RARE ITEM %]") then
            table.insert(rareDrops, item); shouldPing = true
        elseif item:match("VIP Fruit") then
            table.insert(vipDrops, item); shouldPing = true
        else
            table.insert(normalDrops, item)
        end
    end

    local fields = {}
    if #rareDrops > 0 then
        local lines = ""
        for _, v in ipairs(rareDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "✨  RARE DROP", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #vipDrops > 0 then
        local lines = ""
        for _, v in ipairs(vipDrops) do lines = lines .. "+ " .. v .. "\n" end
        table.insert(fields, {name = "🍑  VIP Fruit", value = "```diff\n" .. lines .. "```", inline = false})
    end
    if #normalDrops > 0 then
        local lines = ""
        for _, v in ipairs(normalDrops) do lines = lines .. "  " .. v .. "\n" end
        table.insert(fields, {name = "🎁  Normal Drops", value = "```\n" .. lines .. "```", inline = false})
    end
    if #SessionItems == 0 then
        table.insert(fields, {name = "🎁  Session Drops", value = "```diff\n- Không có Item / Fruit nào```", inline = false})
    end
    table.insert(fields, {
        name  = "📊  Thống kê",
        value = "```\nRare   : " .. #rareDrops
              .. "\nVIP    : " .. #vipDrops
              .. "\nNormal : " .. #normalDrops
              .. "\nTổng   : " .. #SessionItems .. "```",
        inline = true,
    })

    local embedTitle
    if #rareDrops > 0 and #vipDrops > 0 then embedTitle = "🔥  RARE + VIP DROPPED !!!"
    elseif #rareDrops > 0                 then embedTitle = "✨  RARE ITEM DROPPED !!!"
    elseif #vipDrops > 0                  then embedTitle = "🍑  VIP FRUIT DROPPED !!!"
    else                                       embedTitle = "🎁  Dungeon Cleared" end

    local payload = {
        embeds = {{
            author      = {name = "⚔️  Cupid Dungeon  •  Auto Farm", icon_url = LogoZiLi},
            title       = embedTitle,
            color       = shouldPing and 0xFF2222 or 0xFFB347,
            description = "━━━━━━━━━━━━━━━━━━━━━━\n"
                .. "👤  **Player:** ||" .. Player.Name .. "||\n"
                .. "⏱️  **Clear Time:** `" .. DungeonClearTimeStr .. "`\n"
                .. "🗺️  **Map:** `Cupid Dungeon`\n"
                .. "━━━━━━━━━━━━━━━━━━━━━━",
            fields      = fields,
            thumbnail   = {url = NormalThumb},
            footer      = {text = "ZiLi Hub  •  " .. os.date("%d/%m/%Y  %H:%M:%S"), icon_url = LogoZiLi},
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    if shouldPing then payload["content"] = "@everyone 🚨 DROP HIẾM!" end

    local req = (syn and syn.request) or (http and http.request)
             or http_request or (fluxus and fluxus.request) or request
    if req then
        task.spawn(function()
            pcall(function()
                req({ Url = WebhookURL, Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode(payload) })
            end)
        end)
    end
end

-- ==========================================
-- [7] RADAR TRACK ĐỒ
-- ==========================================
task.spawn(function()
    local pGui  = Player:WaitForChild("PlayerGui", 9e9)
    local notif = pGui:WaitForChild("Notifications", 9e9)

    local function CheckItemText(label)
        if not label or not label:IsA("TextLabel") then return end
        if not ProcessedLabels[label] then ProcessedLabels[label] = {} end

        local function parseText()
            local txt = string.lower(string.gsub(label.Text, "<[^>]+>", ""))
            if txt == "" then return end
            for rareName in pairs(RareImages) do
                if string.find(txt, string.lower(rareName), 1, true) then
                    if not ProcessedLabels[label][rareName] then
                        ProcessedLabels[label][rareName] = true
                        table.insert(SessionItems, rareName .. " [ RARE ITEM ]")
                        print("🔴 RARE:", rareName)
                    end
                end
            end
            for _, normalName in ipairs(NormalItems) do
                if string.find(txt, string.lower(normalName), 1, true) then
                    if not ProcessedLabels[label][normalName] then
                        ProcessedLabels[label][normalName] = true
                        table.insert(SessionItems, normalName .. " [ Normal Item ]")
                        print("🟢 ITEM:", normalName)
                    end
                end
            end
        end

        parseText()
        local conn = label:GetPropertyChangedSignal("Text"):Connect(parseText)
        label.AncestryChanged:Connect(function(_, parent) if not parent then conn:Disconnect() end end)
    end

    local function SetupTracker(frameName)
        local frame = notif:FindFirstChild(frameName)
        if not frame then return end
        for _, v in ipairs(frame:GetChildren()) do CheckItemText(v) end
        frame.ChildAdded:Connect(CheckItemText)
    end

    SetupTracker("Frame"); SetupTracker("Frame2")
    notif.ChildAdded:Connect(function(child)
        if child.Name == "Frame" or child.Name == "Frame2" then SetupTracker(child.Name) end
    end)
end)

-- ==========================================
-- [8] AUTO REPLAY (V4 FIX)
-- Decompile cho thấy:
--   - Nút là ImageButton có attribute "buttonValue"
--   - prompt:GetAttribute("isServer") == true → FireServer
--   - Ngược lại → clientEvent:Fire(val)
--   - RemoteEvent nằm trong chính prompt (script.Parent của code gốc)
-- ==========================================
task.spawn(function()
    local isReplaying = false

    -- Tìm nút replay theo đúng decompile
    local function FindReplayButton()
        local prompt = Player.PlayerGui:FindFirstChild("ConfirmationPrompt")
        if not prompt then return nil, nil, nil end
        if prompt:IsA("ScreenGui") and not prompt.Enabled then return nil, nil, nil end

        local main = prompt:FindFirstChild("Main")
        if not main or (main:IsA("GuiObject") and not main.Visible) then return nil, nil, nil end

        local options = main:FindFirstChild("OptionsFrame")
        if not options then return nil, nil, nil end

        -- V4: Scan ImageButton như trong decompile
        local targetBtn = nil
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("ImageButton") then
                local bv = child:GetAttribute("buttonValue")
                if bv then
                    local bvLow = tostring(bv):lower()
                    -- Ưu tiên nút replay/again/play
                    if bvLow:match("replay") or bvLow:match("again") or bvLow:match("play") then
                        targetBtn = child; break
                    end
                    if not targetBtn then targetBtn = child end  -- fallback: nút đầu tiên có buttonValue
                end
            end
        end
        -- Fallback: tìm theo tên (V3 compat)
        if not targetBtn then
            targetBtn = options:FindFirstChild("Replay")
                     or options:FindFirstChild("PlayAgain")
                     or options:FindFirstChild("Again")
        end

        return targetBtn, prompt, main
    end

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and not isReplaying then
            pcall(function()
                local btn, prompt, main = FindReplayButton()
                if btn then
                    isReplaying = true
                    print("⏳ Bảng Replay hiện! Đợi 1.5s...")
                    task.wait(1.5)

                    local val      = btn:GetAttribute("buttonValue") or btn.Name
                    local isServer = prompt:GetAttribute("isServer")  -- bool từ decompile
                    local remote   = prompt:FindFirstChild("RemoteEvent")

                    local fired = false
                    if remote then
                        if isServer == true then
                            -- Decompile path: isServer → FireServer
                            pcall(function() remote:FireServer(val) end)
                            print("🚀 Replay (FireServer, isServer=true) val:", tostring(val))
                            fired = true
                        else
                            -- Decompile path: clientEvent:Fire(val)
                            local clientEvent = prompt:FindFirstChild("clientEvent")
                            if clientEvent then
                                pcall(function() clientEvent:Fire(val) end)
                                print("🚀 Replay (clientEvent:Fire) val:", tostring(val))
                                fired = true
                            else
                                -- clientEvent không tìm thấy, thử FireServer
                                pcall(function() remote:FireServer(val) end)
                                print("🚀 Replay (FireServer fallback) val:", tostring(val))
                                fired = true
                            end
                        end
                    end

                    if not fired then
                        -- Không có RemoteEvent, thử nil instances rồi VIM
                        local nilFired = false
                        if getnilinstances then
                            for _, v in next, getnilinstances() do
                                if v:IsA("RemoteEvent") and v.Parent == nil then
                                    pcall(function() v:FireServer(val) end)
                                    nilFired = true
                                end
                            end
                        end
                        if nilFired then
                            print("🚀 Replay (Nil Remote) val:", tostring(val))
                        else
                            pcall(function()
                                local pos  = btn.AbsolutePosition
                                local size = btn.AbsoluteSize
                                local cx   = pos.X + size.X / 2
                                local cy   = pos.Y + size.Y / 2
                                VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 1)
                                task.wait(0.05)
                                VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                            end)
                            print("🖱️ Replay (VIM Click)")
                        end
                    end

                    -- Ẩn prompt để không re-trigger
                    if prompt:IsA("ScreenGui") then prompt.Enabled = false end
                    if main:IsA("GuiObject")   then main.Visible   = false end

                    task.wait(5)
                    isReplaying = false
                end
            end)
        end
        task.wait(0.5)
    end
    print("🔴 Replay loop thoát — Session:", currentScriptID)
end)

-- ==========================================
-- [9] HÀM TIỆN ÍCH
-- ==========================================
local function IsPotentialFruit(name)
    local n = name:lower()
    if n:match("fruit") or n == "tool" then return true end
    for _, v in ipairs(VIP_Fruits)   do if n:match(v) or n == v then return true end end
    for _, t in ipairs(TRASH_Fruits) do if n:match(t) or n == t then return true end end
    return false
end

-- ==========================================
-- [10] COMBAT CONFIG & STATE
-- ==========================================
local MoveSpeed     = 110
local AttackOffset  = 10    -- FIX: 10 thay vì 10.5, dùng chung cho flying & underground
local SearchRadius  = 800
local WaitSpawnTime = 6     -- giảm: chờ spawn tối đa 6s
local GatherTime    = 0.2   -- gather nhanh hơn
local DangerRadius  = 45
local EvadeDistance = 60

-- Khoảng cách né skill boss
local EVADE_ENTEI        = 130
local EVADE_FLAME_PILLAR = 75
local EVADE_BOSS_GENERIC = 100

-- Underground noclip (zone 7+8)
-- FIX: dùng mob.Y ± AttackOffset thay vì floorY - depth
-- → khoảng cách tới mob = AttackOffset (10), giống flying
local UNDERGROUND_DEPTH     = AttackOffset   -- = 10, đồng nhất với flying
local UNDERGROUND_DODGE_ADD = 10             -- thêm khi dodge (tổng 20 dưới mob)
local UNDERGROUND_LERP_SPEED = 80            -- studs/s smooth descent

-- Ground AoE (arrow rain, lightning): chui xuống dưới mob thay vì chạy xa
local GROUND_AOE_DEPTH = 20   -- studs dưới mob.Y khi né ground AoE

-- Giới hạn tween
local MAX_DT             = 0.1    -- 100ms cap — an toàn hơn ở FPS thấp
local MAX_STEP_PER_FRAME = 8      -- giảm từ 10 → server ít kick hơn khi FPS < 5
-- V6 FIX: Y axis riêng — anticheat threshold ~47 studs/s
-- Tại 60fps: MAX_STEP_Y = 47/60 ≈ 0.78 studs/frame → safe
-- Tại 30fps: MAX_STEP_Y = 47/30 ≈ 1.57 studs/frame → safe
-- Cap ở 0.7 studs/frame để có buffer (threshold - buffer)
local MAX_STEP_Y_PER_FRAME = 0.7  -- studs/frame, phòng "Y Axis too fast" anticheat

-- Thời gian đứng yên sau khi né dodge xong
local DODGE_RETURN_WAIT = 4  -- giây

local Zone5Points = {
    Vector3.new(-1166.94, 442.27, -3332.41),
    Vector3.new(-995.78,  442.31, -3331.45),
    Vector3.new(-962.64,  442.04, -3084.11),
    Vector3.new(-1135.6,  442.67, -3102.46),
}
local EndPortalPos    = Vector3.new(-1097.87, 672.92, -5379.12)
local Z5Index         = 1

local TargetCFrame      = nil
local CurrentTargetRoot = nil
local IsReadyToAttack   = false
local CurrentZoneIndex  = 1
local ZoneState         = "FLYING"
local PreviousZoneState = "FLYING"
local Timer             = 0
local DodgeTimer        = 0
local SkillBlockUntil   = 0
local CachedZoneFloors  = {}

-- Underground tracking
local _undergroundCurrentY = nil
local _isUndergroundMode   = false

-- Fix 1: track loại dodge để biết có cần BLOCK sau khi dodge không
local _currentDodgeIsAoe = false   -- true = general AoE → block sau khi dodge

-- Fix 3: smooth movement zone 7+8 — velocity accumulator
local _smoothPos    = nil  -- Vector3 vị trí smooth hiện tại (nil = chưa init)
local _smoothVelXZ  = Vector3.new(0,0,0)  -- XZ velocity

local IgnoredHazards = setmetatable({}, {__mode = "k"})
local CurrentHazard  = {Type = "None", Position = nil, Instance = nil, MinDist = DangerRadius, Action = "DODGE"}
local CurrentLava    = {Part = nil, Prompt = nil}
local IsFarmingReady    = false
local HasWaitedForLoad  = false

-- ── FIX V6: FakePlatform — tàng hình, size lớn hơn, CanCollide đúng
-- Platform theo chân nhân vật mọi lúc.
-- Khi -90° tilt (IsReadyToAttack): body nằm ngang → lowest world Y ≈ HRP.Y
--   → đặt platform tại root.Y - 0.6 (sát dưới body nằm ngang)
-- Khi đứng bình thường: feet ≈ root.Y - 3.2
--   → đặt platform tại root.Y - 3.7 (top = root.Y - 3.2)
-- Cả 2 trường hợp đều trong 15 studs từ character → qua "Distance from Floor" check
local fakePlatform = workspace:FindFirstChild("CupidFakePlatform")
if fakePlatform then fakePlatform:Destroy() end  -- reset platform cũ nếu có
fakePlatform              = Instance.new("Part")
fakePlatform.Name         = "CupidFakePlatform"
fakePlatform.Size         = Vector3.new(22, 1, 22)
fakePlatform.Anchored     = true
fakePlatform.CanCollide   = true
fakePlatform.Transparency = 1        -- V6: tàng hình hoàn toàn
fakePlatform.CastShadow   = false
fakePlatform.Material     = Enum.Material.SmoothPlastic
fakePlatform.Parent       = workspace

-- ==========================================
-- [5-A] STAMINA SPOOF — V7 ALWAYS-ON
-- V7: Fire liên tục mọi lúc (lobby + dungeon + bất kỳ đâu)
--   • Không có guard IsFarmingReady → không bao giờ ngừng
--   • Không gọi StopStaminaSpoof khi vào dungeon nữa
--   • Case-insensitive fetch giữ nguyên
--   • Dual-fire + task.defer giữ nguyên
-- ==========================================
local Events   = ReplicatedStorage:WaitForChild("Events", 5)

local function FindEventCI(parent, targetName)
    if not parent then return nil end
    local lower = targetName:lower()
    local exact = parent:FindFirstChild(targetName)
    if exact then return exact end
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:lower() == lower then return child end
    end
    return nil
end

local TakeStam = Events and FindEventCI(Events, "takestam")

-- V7: Chạy 1 lần duy nhất, không bao giờ stop, không cần Start/Stop
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        -- Re-fetch nếu bị nil (zone reload)
        if not TakeStam or not TakeStam.Parent then
            pcall(function()
                local ev = ReplicatedStorage:FindFirstChild("Events")
                if ev then TakeStam = FindEventCI(ev, "takestam") end
            end)
        end
        if TakeStam and TakeStam.Parent then
            pcall(function() TakeStam:FireServer(0.545, "dash") end)
            task.defer(function()
                pcall(function()
                    if TakeStam and TakeStam.Parent then
                        TakeStam:FireServer(0.545, "dash")
                    end
                end)
            end)
        end
        task.wait(0.05)
    end
end)

-- Stub: giữ lại để không bị lỗi nếu code cũ gọi
local function StartStaminaSpoof() end
local function StopStaminaSpoof() end

-- ==========================================
-- [5-B] SKILL BLOCK TRIGGER — V7 NOCLIP-SAFE
-- V7 Fix: block + noclip = kick
--   • Set _G.NoclipPaused = true TRƯỚC khi block → noclip loop dừng force CanCollide=false
--   • Restore CanCollide = true cho toàn char trước khi gửi block event
--   • Block ngắn 0.5s thay vì 2.5s (đủ để parry, không bị noclip lâu)
--   • Release block → _G.NoclipPaused = false → noclip tự resume
-- ==========================================
local function TriggerSkillBlock(weaponName, duration)
    if _G.SkillBlocking then return end
    _G.SkillBlocking  = true
    _G.NoclipPaused   = true   -- báo noclip loop dừng ngay
    SkillBlockUntil   = tick() + (duration or 0.5)

    task.spawn(function()
        pcall(function()
            -- ── Step 1: Park fakePlatform TRƯỚC khi restore CanCollide ──────
            -- Root cause spin: fakePlatform.CanCollide=true + character parts CanCollide=true
            -- → character chạm platform ngay bên dưới → impulse → RotVelocity spike → spin
            -- Fix: đẩy platform ra xa trong suốt block window, bring back sau khi release
            if fakePlatform and fakePlatform.Parent then
                fakePlatform.CFrame = CFrame.new(0, -9999, 0)
            end

            -- ── Step 2: Restore CanCollide (cần cho server block check) ─────
            local char = Player.Character
            local charRoot = char and char:FindFirstChild("HumanoidRootPart")
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
                end
            end
            -- Zero bất kỳ RotVelocity có sẵn TRƯỚC khi block
            if charRoot then
                charRoot.RotVelocity = Vector3.zero
                pcall(function() charRoot.AssemblyAngularVelocity = Vector3.zero end)
            end
            task.wait(0.02)

            -- ── Step 3: Gửi block event + VIM key ───────────────────────────
            local BlockEvent = ReplicatedStorage:WaitForChild("Events", 3)
                :WaitForChild("Block", 3)
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(true, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(true, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)

            -- ── Step 4: Hold block ───────────────────────────────────────────
            task.wait(duration or 0.5)

            -- ── Step 5: Release block ────────────────────────────────────────
            if BlockEvent:IsA("RemoteFunction") then
                BlockEvent:InvokeServer(false, weaponName or "Melee", false)
            else
                BlockEvent:FireServer(false, weaponName or "Melee", false)
            end
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)

            -- ── Step 6: Dập tắt spin ngay sau khi nhả block ─────────────────
            -- VIM F release → game exit block anim → có thể spike RotVelocity
            -- Spam reset 5× trong 0.15s để chắc chắn không còn angular velocity
            local r = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            for i = 1, 5 do
                if r and r.Parent then
                    r.RotVelocity = Vector3.zero
                    pcall(function() r.AssemblyAngularVelocity = Vector3.zero end)
                end
                task.wait(0.03)
            end
        end)

        -- ── Step 7: Resume noclip SAU KHI spin đã clear ─────────────────────
        _G.SkillBlocking = false
        _G.NoclipPaused  = false
        print("🛡️ Block release xong → spin cleared → noclip resume")
    end)
    print("🛡️ TriggerSkillBlock:", weaponName, "→", duration or 0.5, "s")
end

-- ==========================================
-- [11] HÀM TIỆN ÍCH COMBAT
-- ==========================================
local function GetZoneFloor(zoneIndex, boxCenter)
    if CachedZoneFloors[zoneIndex] then return CachedZoneFloors[zoneIndex] end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        Player.Character, fakePlatform,
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Enemies"),
    }
    local result = workspace:Raycast(boxCenter, Vector3.new(0, -300, 0), params)
    if result then CachedZoneFloors[zoneIndex] = result.Position.Y; return result.Position.Y end
    return boxCenter.Y - 10
end

local function GetRoot(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    return m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

-- V4: Kiểm tra mob còn sống — hỗ trợ Humanoid lẫn barrelHP (statue)
local function IsMobAlive(mob)
    local hum = mob:FindFirstChildOfClass("Humanoid") or mob:FindFirstChild("Humanoid", true)
    if hum then return hum.Health > 0.1 end
    local barrelHP = mob:FindFirstChild("barrelHP", true)
    if barrelHP and barrelHP:IsA("ValueBase") then
        local v = tonumber(barrelHP.Value)
        return v ~= nil and v > 0
    end
    return false
end

-- V4: GetMobsInZone với cache 80ms + workspace-wide fallback + statue scan
local MobSearchCache = {mobs = {}, time = 0, zone = -1}
local MOB_CACHE_TTL  = 0.08

local function GetMobsInZone(zonePos)
    -- Dùng cache nếu còn hạn và đúng zone
    if MobSearchCache.zone == CurrentZoneIndex
    and tick() - MobSearchCache.time < MOB_CACHE_TTL then
        local valid = {}
        for _, m in ipairs(MobSearchCache.mobs) do
            if m and m.Parent and IsMobAlive(m) then table.insert(valid, m) end
        end
        MobSearchCache.mobs = valid
        return valid
    end

    local mobs = {}
    local currentSearchRadius = (CurrentZoneIndex == 8) and 1500 or SearchRadius

    -- Zone 8: ưu tiên scan statue trước
    if CurrentZoneIndex == 8 then
        local foundStatue = false
        pcall(function()
            local statueFolders = {}
            local envFolder = workspace:FindFirstChild("Env")
            if envFolder then
                local sf = envFolder:FindFirstChild("Statues")
                if sf then table.insert(statueFolders, sf) end
                for _, c in pairs(envFolder:GetChildren()) do
                    if c.Name:lower():match("statue") then table.insert(statueFolders, c) end
                end
            end
            -- Scan thẳng workspace cho statue
            for _, c in pairs(workspace:GetChildren()) do
                if c.Name:lower():match("statue") then table.insert(statueFolders, c) end
            end
            for _, folder in pairs(statueFolders) do
                if folder then
                    local list = folder:IsA("Model") and {folder} or folder:GetChildren()
                    for _, statue in pairs(list) do
                        if statue:IsA("Model") then
                            local sRoot = GetRoot(statue)
                            if sRoot and IsMobAlive(statue) then
                                table.insert(mobs, statue)
                                foundStatue = true
                            end
                        end
                    end
                end
            end
        end)
        if foundStatue and #mobs > 0 then
            MobSearchCache = {mobs = mobs, time = tick(), zone = CurrentZoneIndex}
            return mobs
        end
    end

    -- Standard scan: nhiều folder + zone folder + 1 cấp grandchild
    local possibleFolders = {}
    for _, name in ipairs({"Enemies","Mob","Mobs","NPCs","Boss","Enemy"}) do
        local f = workspace:FindFirstChild(name)
        if f then table.insert(possibleFolders, f) end
    end
    pcall(function()
        local zf = workspace.Effects.Zones["Zone" .. CurrentZoneIndex]
        if zf then table.insert(possibleFolders, zf) end
    end)

    local seen = {}
    for _, folder in pairs(possibleFolders) do
        if folder then
            local checkList = {}
            for _, c in pairs(folder:GetChildren()) do
                table.insert(checkList, c)
                -- Một cấp sâu hơn để bắt nested folders
                if c:IsA("Folder") or c:IsA("Model") then
                    for _, cc in pairs(c:GetChildren()) do
                        table.insert(checkList, cc)
                    end
                end
            end
            for _, v in pairs(checkList) do
                if v:IsA("Model") and not seen[v] then
                    local hum = v:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0.1 then
                        local root = GetRoot(v)
                        if root then
                            local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                                         - Vector2.new(zonePos.X, zonePos.Z)).Magnitude
                            if xzDist <= currentSearchRadius then
                                table.insert(mobs, v)
                                seen[v] = true
                            end
                        end
                    end
                end
            end
        end
    end

    MobSearchCache = {mobs = mobs, time = tick(), zone = CurrentZoneIndex}

    -- Ưu tiên "dungeon gun user" lên đầu (zone 1-4)
    if CurrentZoneIndex <= 4 and #mobs > 1 then
        table.sort(mobs, function(a, b)
            local an = a.Name:lower()
            local bn = b.Name:lower()
            local aGun = an:find("gun", 1, true) ~= nil
            local bGun = bn:find("gun", 1, true) ~= nil
            if aGun ~= bGun then return aGun end
            return false
        end)
    end

    return mobs
end

-- FIX: priority scan (sword/blade > axe > katana) + pcall bảo vệ EquipTool
local WEAPON_PRIORITY = {
    {pattern = "sword",  score = 1},
    {pattern = "blade",  score = 1},
    {pattern = "axe",    score = 2},
    {pattern = "katana", score = 3},
}
local function IsWeapon(name)
    local n = name:lower()
    for _, w in ipairs(WEAPON_PRIORITY) do
        if n:match(w.pattern) then return true, w.score end
    end
    return false, math.huge
end

local function CheckAndEquipWeapon()
    if _G.IsProcessingFruit then return nil end
    local char = Player.Character
    if not char then return nil end
    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool then
        local ok, _ = IsWeapon(currentTool.Name)
        if ok then return currentTool end
    end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return currentTool end

    -- FIX: scan toàn bộ backpack, chọn vũ khí ưu tiên cao nhất (score thấp nhất)
    local best, bestScore = nil, math.huge
    for _, t in pairs(bp:GetChildren()) do
        if t:IsA("Tool") then
            local ok, score = IsWeapon(t.Name)
            if ok and score < bestScore then
                best = t; bestScore = score
            end
        end
    end
    if best then
        local hum = char:FindFirstChild("Humanoid")
        -- FIX: bọc pcall để tránh fail silent khi humanoid đang stun/ragdoll
        if hum then pcall(function() hum:EquipTool(best) end) end
    end
    return best
end

local function GetAttackAnim(weaponName, combo)
    if _G.IsProcessingFruit then return "Melee", nil end
    local wType = "Melee"
    local anim  = nil
    local swordModules = ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("SwordHandle")
        and ReplicatedStorage.Modules.SwordHandle:FindFirstChild("Swords")

    if swordModules and swordModules:FindFirstChild(weaponName) then
        wType = "Sword"
        local folder = swordModules[weaponName]:FindFirstChild("Slashes")
        if folder then
            anim = folder:FindFirstChild("Slash"..combo)
                or folder:FindFirstChild("GroundSlash"..combo)
                or folder:FindFirstChild("Swing"..combo)
            if not anim then
                for _, a in pairs(folder:GetChildren()) do
                    if string.find(a.Name, tostring(combo)) then anim = a; break end
                end
            end
        end
        return wType, anim
    end

    -- FIX: nếu tên weapon match sword/blade/katana/axe → dùng "Sword" type khi fallback
    -- Tránh bị tính damage theo melee scaling khi cầm katana không có folder riêng
    local isBladeWeapon = (function()
        local n = weaponName:lower()
        return n:match("sword") or n:match("blade") or n:match("katana") or n:match("axe")
    end)()

    wType  = isBladeWeapon and "Sword" or weaponName
    local folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild(weaponName)
    if not folder then
        -- Thử tìm folder "Sword" trước nếu là blade weapon
        if isBladeWeapon then
            folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Sword")
        end
        if not folder then
            folder = ReplicatedStorage:WaitForChild("CombatAnimations"):FindFirstChild("Melee")
            if not isBladeWeapon then wType = "Melee" end
        end
    end
    if folder then
        anim = folder:FindFirstChild("Punch"..combo)
            or folder:FindFirstChild("M1_"..combo)
            or folder:FindFirstChild("Kick"..combo)
            or folder:FindFirstChild("Slash"..combo)
        if not anim then
            for _, a in pairs(folder:GetChildren()) do
                if string.find(a.Name, tostring(combo)) then anim = a; break end
            end
        end
    end
    return wType, anim
end

local function IsMobAttacking(hum)
    local isAttacking = false
    pcall(function()
        local animator = hum:FindFirstChild("Animator") or hum
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if track.Weight > 0.01 and track.Animation then
                local n = track.Animation.Name:lower()
                if not (n:match("idle") or n:match("walk") or n:match("run") or n:match("stun") or n:match("hit")) then
                    if n:match("attack") or n:match("slash")  or n:match("punch")  or
                       n:match("swing")  or n:match("cast")   or n:match("skill")  or
                       n:match("m1")     or n:match("slam")   or n:match("smash")  or
                       n:match("charge") or n:match("burst")  or n:match("combo")  or
                       n:match("shoot")  or n:match("fire")   or n:match("gun")    or
                       n:match("ranged") or n:match("magic")  or n:match("throw")  or n:match("shot") then
                        isAttacking = true; break
                    end
                end
            end
        end
    end)
    return isAttacking
end

-- ==========================================
-- [12] DUNGEON LOCATION DETECTION
-- ==========================================
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon then
            pcall(function()
                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    local islands = workspace:FindFirstChild("Islands")
                    if islands then
                        local lobby   = islands:FindFirstChild("Lobby")
                        local dungeon = islands:FindFirstChild("Cupid Dungeon")
                        local getPos  = function(inst)
                            if not inst then return nil end
                            if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Position end
                            local part = inst:FindFirstChildWhichIsA("BasePart", true)
                            if part then return part.Position end
                        end
                        local lPos  = getPos(lobby)
                        local dPos  = getPos(dungeon)
                        local rPos  = root.Position
                        local lDist = lPos and (Vector2.new(lPos.X,lPos.Z) - Vector2.new(rPos.X,rPos.Z)).Magnitude or math.huge
                        local dDist = dPos and (Vector2.new(dPos.X,dPos.Z) - Vector2.new(rPos.X,rPos.Z)).Magnitude or math.huge

                        if dDist < lDist and dDist < 5000 then
                            if not HasWaitedForLoad then
                                HasWaitedForLoad      = true
                                IsFarmingReady        = false
                                DungeonStartTime      = tick()
                                SessionItems          = {}
                                ProcessedItems        = {}
                                ProcessedLabels       = setmetatable({}, {__mode = "k"})
                                WebhookSentForSession = false
                                _G.EndGameStarted     = false
                                _G.GoToPortal         = false
                                _G.IsProcessingFruit  = false
                                _G.SkillBlocking      = false
                                MobSearchCache        = {mobs = {}, time = 0, zone = -1}
                                CachedZoneFloors      = {}
                                _isUndergroundMode    = false
                                _undergroundCurrentY  = nil
                                StopStaminaSpoof()
                                task.wait(5)
                                CurrentZoneIndex = 1
                                ZoneState        = "FLYING"
                                IsFarmingReady   = true
                                -- V6 FIX: restart StaminaSpoof sau khi vào dungeon
                                -- V5 bug: StopStaminaSpoof() gọi nhưng StartStaminaSpoof() không bao giờ restart
                                StartStaminaSpoof()
                                print("💨 StaminaSpoof restarted on dungeon entry")
                            end
                        else
                            IsFarmingReady   = false
                            HasWaitedForLoad = false
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- [13] AUTO EQUIP HAKI
-- ==========================================
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
                            hasHaki = true; break
                        end
                    end
                    if not hasHaki then ReplicatedStorage.Events.Haki:FireServer("Buso") end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- [13-B] MAP OPTIMIZE + SKILL HIDE
-- FIX: _mapOptimized reset khi script re-run
-- Gọi ngay khi load script (không chờ dungeon entry)
-- ==========================================
local _mapOptimized    = false  -- reset mỗi lần load script (không dùng _G)
local _effectHiddenSet = setmetatable({}, {__mode = "k"})

local function HideVisualOfInst(v)
    if _effectHiddenSet[v] then return end
    _effectHiddenSet[v] = true
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
        or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
            v.Enabled = false
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            v.Enabled = false
        elseif v:IsA("SpecialMesh") then
            v.Scale = Vector3.zero
        elseif v:IsA("BasePart") and not v:IsA("Terrain") then
            v.LocalTransparencyModifier = 1
            v.CastShadow = false
            v.CanCollide = false  -- noclip thêm cho effect parts
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("Sound") then
            v.Volume = 0  -- tắt âm thanh effect → giảm CPU audio
        end
    end)
end

local function HideFolderEffects(folder)
    if not folder then return end
    pcall(function()
        for _, v in ipairs(folder:GetDescendants()) do
            HideVisualOfInst(v)
        end
        folder.DescendantAdded:Connect(function(inst)
            task.defer(function() HideVisualOfInst(inst) end)
        end)
    end)
end

local function DoMapOptimize()
    if _mapOptimized then return end
    _mapOptimized = true
    task.spawn(function()

        -- [A] Lighting
        pcall(function()
            local L = game:GetService("Lighting")
            L.GlobalShadows = false
            L.FogEnd        = 9e9
            L.Brightness    = 2
            L.ClockTime     = 14
            L.Ambient       = Color3.fromRGB(178, 178, 178)
            for _, v in ipairs(L:GetDescendants()) do
                if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect")
                or v:IsA("SunRaysEffect") or v:IsA("BloomEffect")
                or v:IsA("ColorCorrectionEffect") then
                    pcall(function() v.Enabled = false end)
                elseif v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
                    pcall(function() v:Destroy() end)
                end
            end
        end)

        -- [B] Render quality — thử cả 2 cách phổ biến nhất trong executors
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end)

        -- [C] Terrain
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                t.Decoration       = false
                t.WaterWaveSize    = 0
                t.WaterWaveSpeed   = 0
                t.WaterReflectance = 0
                t.WaterTransparency = 1
                t.CastShadow       = false
            end
        end)

        -- [D] Effects & Projectiles — ẩn visual, giữ BasePart để detect
        for _, fname in ipairs({"Effects", "Projectiles"}) do
            local f = workspace:FindFirstChild(fname)
            if f then HideFolderEffects(f) end
            workspace.ChildAdded:Connect(function(child)
                if child.Name == fname then
                    task.defer(function() HideFolderEffects(child) end)
                end
            end)
        end

        -- [E] Toàn bộ workspace — tắt shadow + particles + non-collision parts
        task.spawn(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if desc:IsA("ParticleEmitter") or desc:IsA("Beam")
                    or desc:IsA("Trail") or desc:IsA("Fire")
                    or desc:IsA("Smoke") or desc:IsA("Sparkles") then
                        desc.Enabled = false
                    elseif desc:IsA("BasePart") and not desc:IsA("Terrain") then
                        desc.CastShadow = false
                        -- Ẩn hoàn toàn parts trang trí không có collision
                        if not desc.CanCollide then
                            desc.LocalTransparencyModifier = 1
                        end
                    elseif desc:IsA("Sound") then
                        -- Tắt hầu hết âm thanh ambient
                        if desc.Parent and not (desc.Parent == Player.Character) then
                            desc.Volume = 0
                        end
                    end
                end)
            end
            -- Auto-hide mọi thứ mới spawn vào workspace
            workspace.DescendantAdded:Connect(function(inst)
                task.defer(function()
                    pcall(function()
                        if inst:IsA("ParticleEmitter") or inst:IsA("Beam")
                        or inst:IsA("Trail") or inst:IsA("Fire")
                        or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                            inst.Enabled = false
                        elseif inst:IsA("BasePart") and not inst:IsA("Terrain")
                        and not (Player.Character and inst:IsDescendantOf(Player.Character)) then
                            inst.CastShadow = false
                            if not inst.CanCollide then
                                inst.LocalTransparencyModifier = 1
                            end
                        end
                    end)
                end)
            end)
        end)

        print("🗺️ Map Optimized OK")
    end)
end

-- Gọi ngay khi load script — không chờ dungeon entry
DoMapOptimize()

-- Chạy optimize ngay khi vào dungeon (gọi từ [12] sau IsFarmingReady = true)
-- Và auto re-hide khi có effect mới spawn (DescendantAdded đã connect trong HideFolderEffects)

-- ==========================================
-- [14] HAZARD SCANNER (V5 — EVENT-DRIVEN QUEUE)
--
-- FIX PERFORMANCE: Thay CollectDescendants(workspace, 4) mỗi 20ms
-- bằng workspace.DescendantAdded event queue.
-- Chỉ process instance MỚI khi nó spawn vào game → không scan lại toàn bộ workspace.
-- CPU load giảm ~95% so với cách cũ.
-- ==========================================

-- Priority thấp hơn = quan trọng hơn
-- BossSkillDefs: CHỈ Enkai/Entei
-- FlamePillar, Firefly, Hiken → xử lý bởi general AoE scanner (DODGE 40 + BLOCK)
-- Underground zone (7+8): Enkai → đứng yên sâu hơn 5 studs, đợi hết chiêu
local BossSkillDefs = {
    {pattern = "enkai",  action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
    {pattern = "en_kai", action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
    {pattern = "entei",  action = "DODGE_DEEP", evadeDist = EVADE_ENTEI, priority = 1, noRadius = true},
}

-- Instance tên match những pattern này → bỏ qua hoàn toàn (không log, không react)
local IGNORE_NAME_PATTERNS = {
    "dmgind", "hitbox", "hurtbox", "indicator", "number",
    "billboard", "sfx", "sound", "particle", "debris",
    "decal", "highlight", "selection", "tag", "gui",
}

-- Khoảng cách tối đa để xét instance là nguy hiểm (boss zone)
local BOSS_PROX_RADIUS = 180  -- studs

-- Lấy vị trí instance — BasePart đệ quy
local function GetInstPos(inst)
    if not inst then return nil end
    local pos = nil
    pcall(function()
        if inst:IsA("BasePart") then
            pos = inst.Position
        elseif inst:IsA("Model") then
            if inst.PrimaryPart then
                pos = inst.PrimaryPart.Position
            else
                local bp = inst:FindFirstChildWhichIsA("BasePart", true)
                if bp then pos = bp.Position end
            end
            if not pos then pos = inst:GetModelCFrame().Position end
        end
    end)
    return pos
end

-- ==========================================
-- Queue-based: workspace.DescendantAdded đẩy instance vào queue
-- Scan loop chỉ drain queue → không tốn CPU scan lại toàn workspace
-- ==========================================
local _newInstQueue    = {}   -- queue drain mỗi scan tick
local _checkedInsts    = setmetatable({}, {__mode = "k"})  -- đã check (weak)
local _loggedUnknown   = setmetatable({}, {__mode = "k"})

-- Connect một lần duy nhất
local _descAddedConn
_descAddedConn = workspace.DescendantAdded:Connect(function(inst)
    if _G.DungeonScriptID ~= currentScriptID then
        _descAddedConn:Disconnect(); return
    end
    -- Chỉ quan tâm BasePart và Model (có vị trí)
    if inst:IsA("BasePart") or inst:IsA("Model") then
        _newInstQueue[#_newInstQueue + 1] = inst
    end
end)

-- Lấy vị trí instance — BasePart đệ quy
local function GetInstPos(inst)
    if not inst then return nil end
    local pos
    pcall(function()
        if inst:IsA("BasePart") then
            pos = inst.Position
        elseif inst:IsA("Model") then
            if inst.PrimaryPart then
                pos = inst.PrimaryPart.Position
            else
                local bp = inst:FindFirstChildWhichIsA("BasePart", true)
                if bp then pos = bp.Position end
            end
            if not pos then pos = inst:GetModelCFrame().Position end
        end
    end)
    return pos
end

-- Drain queue và check hazard — chỉ xử lý instance mới spawn
-- Returns bestDef, bestInst, bestPos
local function DrainQueueScan(playerPos)
    if #_newInstQueue == 0 then return nil, nil, nil end

    -- Ambil queue hiện tại, reset cho lần sau
    local queue = _newInstQueue
    _newInstQueue = {}

    local bestDef, bestInst, bestPos

    local char = Player.Character
    for _, v in ipairs(queue) do
        -- Bỏ qua nếu đã check, không còn trong game, hoặc là của char
        if _checkedInsts[v] then continue end
        if not v:IsDescendantOf(workspace) then continue end
        if char and v:IsDescendantOf(char) then continue end
        _checkedInsts[v] = true

        -- Ignore noise patterns
        local n = v.Name:lower()
        local skip = false
        for _, pat in ipairs(IGNORE_NAME_PATTERNS) do
            if n:find(pat, 1, true) then skip = true; break end
        end
        if skip then continue end

        local vPos = GetInstPos(v)
        if not vPos then continue end

        local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude

        for _, def in ipairs(BossSkillDefs) do
            local inRadius = def.noRadius or (dist <= BOSS_PROX_RADIUS)
            if inRadius and (not bestDef or def.priority < bestDef.priority) and n:match(def.pattern) then
                print("⚠️ [HazardQ] NEW:", v.Name, "→", def.action, "dist:", math.floor(dist))
                bestDef  = def
                bestInst = v
                bestPos  = vPos
            end
        end

        -- Log unknown gần player
        if not bestDef and dist <= BOSS_PROX_RADIUS and not _loggedUnknown[v] then
            _loggedUnknown[v] = true
            print("🔍 [HazardQ] UNKNOWN:", v.Name, "dist:", math.floor(dist), "|", v:GetFullName())
        end
    end

    return bestDef, bestInst, bestPos
end

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Dọn hazard hết hạn
                for obj, expireTime in pairs(IgnoredHazards) do
                    if tick() > expireTime or not obj:IsDescendantOf(workspace) then
                        IgnoredHazards[obj] = nil
                    end
                end

                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local playerPos       = root.Position
                local detectedHazard  = "None"
                local hazardPos       = nil
                local hazardInst      = nil
                local hazardAction    = "DODGE"
                local hazardEvadeDist = EvadeDistance
                local foundLavaPart   = nil
                local foundLavaPrompt = nil

                -- Boss skill scan (zone >= 5) — event-driven queue
                if CurrentZoneIndex >= 5 then
                    local def, inst, pos = DrainQueueScan(playerPos)
                    if def and inst then
                        detectedHazard  = "BossSkill"
                        hazardAction    = def.action
                        hazardEvadeDist = def.evadeDist
                        hazardInst      = inst
                        if def.action == "DODGE" and pos then
                            hazardPos = pos
                        elseif CurrentTargetRoot and CurrentTargetRoot.Parent then
                            hazardPos = CurrentTargetRoot.Position
                        else
                            hazardPos = playerPos
                        end
                    end
                end

                -- General AoE + Lava Curse (mọi zone)
                -- V6 FIX: ArrowRain / Lightning → dodge đúng 2s rồi hold block
                -- Các AoE khác → dodge theo evadeDist/MoveSpeed như cũ
                if detectedHazard == "None" then
                    local effectsFolder = workspace:FindFirstChild("Effects")
                    if effectsFolder then
                        local minDist = DangerRadius
                        for _, v in ipairs(effectsFolder:GetChildren()) do
                            local name = v.Name:lower()
                            local vPos = GetInstPos(v)
                            if vPos and not IgnoredHazards[v] then
                                local dist = (Vector2.new(vPos.X, vPos.Z) - Vector2.new(playerPos.X, playerPos.Z)).Magnitude
                                -- V6: phân biệt arrowrain/lightning vs AoE thường
                                -- TÌM VÀ XÓA ĐOẠN GỘP CHUNG isArrowOrLightning CŨ.
                                -- THAY BẰNG KHỐI PHÂN TÁCH RÕ RÀNG NÀY:

                                local isArrow = name:match("arrow") or name:match("rain")
                                local isLightning = name:match("lightning")

                                if isArrow and dist < minDist then
                                    detectedHazard = "ArrowRain"
                                    hazardPos = vPos
                                    minDist = dist
                                    hazardInst = v
                                    hazardAction = "DODGE"
                                    hazardEvadeDist = 80 -- Tăng khoảng cách né ra thật xa
                                    
                                elseif isLightning and dist < minDist then
                                    detectedHazard = "Lightning"
                                    hazardPos = vPos
                                    minDist = dist
                                    hazardInst = v
                                    hazardAction = "BLOCK" -- Đứng tại chỗ, không dodge
                                    hazardEvadeDist = 0    -- Không cần di chuyển
                                    
                                elseif (name:match("aoe") or name:match("circle") or name:match("bomb") or name:match("meteor") or name:match("projectile")) and dist < minDist then
                                    detectedHazard = "Normal"
                                    hazardPos = vPos
                                    minDist = dist
                                    hazardInst = v
                                    hazardAction = "DODGE"
                                    hazardEvadeDist = 40
                                end
                                if name:match("lava") and name:match("curse") and dist < 1500 then
                                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    local part   = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
                                    if part and prompt and prompt.Enabled then
                                        foundLavaPart   = part
                                        foundLavaPrompt = prompt
                                    end
                                end
                            end
                        end
                    end
                end

                CurrentHazard.Type      = detectedHazard
                CurrentHazard.Position  = hazardPos
                CurrentHazard.Instance  = hazardInst
                CurrentHazard.MinDist   = hazardEvadeDist
                CurrentHazard.Action    = hazardAction
                CurrentLava.Part        = foundLavaPart
                CurrentLava.Prompt      = foundLavaPrompt
            end)
        end
        -- Boss zone quét 0.02s, zone 5-6 quét 0.04s, bình thường 0.06s
        local scanInterval = IsFarmingReady and (
            CurrentZoneIndex >= 7 and 0.02 or
            CurrentZoneIndex >= 5 and 0.04 or 0.06
        ) or 0.1
        task.wait(scanInterval)
    end
end)

-- ==========================================
-- [15] MAIN ZONE LOGIC + END GAME
-- ==========================================
task.spawn(function()
    local lastZone      = 0
    local isHoldingLava = false

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                -- Invalidate mob cache khi đổi zone
                if lastZone ~= CurrentZoneIndex then
                    lastZone = CurrentZoneIndex
                    MobSearchCache = {mobs = {}, time = 0, zone = -1}
                end

                local char = Player.Character
                if not char or not char.Parent then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- ── END GAME ────────────────────────────────────────────────
                if CurrentZoneIndex > 8 then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    StopStaminaSpoof()

                    if not _G.EndGameStarted then
                        _G.EndGameStarted = true
                        task.spawn(function()
                            if root then root.Velocity = Vector3.zero end
                            task.wait(2.5)

                            pcall(function()
                                _G.IsProcessingFruit = true
                                local bp  = Player:FindFirstChild("Backpack")
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

                                            local activeTool  = char:FindFirstChildOfClass("Tool") or tool
                                            local exactName   = activeTool.Name:lower()
                                            local displayName = activeTool.Name
                                            local isVIP       = false
                                            for _, vip in ipairs(VIP_Fruits) do
                                                if exactName:match(vip) or exactName == vip then isVIP = true; break end
                                            end
                                            if isVIP then
                                                pcall(function() ReplicatedStorage.Events.FruitStorage:InvokeServer("Store", activeTool) end)
                                                task.wait(1.5)
                                                if activeTool.Parent == char or activeTool.Parent == bp then
                                                    pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                    table.insert(SessionItems, displayName .. " [ VIP Fruit - Dropped ]")
                                                else
                                                    table.insert(SessionItems, displayName .. " [ VIP Fruit - Stored ]")
                                                end
                                            else
                                                pcall(function() ReplicatedStorage.Events.Tools:InvokeServer("drop", activeTool) end)
                                                table.insert(SessionItems, displayName .. " [ Dropped ]")
                                            end
                                            pcall(function() hum:UnequipTools() end)
                                        end
                                    end
                                end
                            end)
                            _G.IsProcessingFruit = false

                            if not WebhookSentForSession then
                                local elapsed = tick() - DungeonStartTime
                                DungeonClearTimeStr = string.format("%02d:%02d", math.floor(elapsed/60), math.floor(elapsed%60))
                                SendWebhook()
                                task.wait(1.5)
                            end
                            _G.GoToPortal = true
                        end)
                    end

                    if _G.GoToPortal then
                        ZoneState    = "TO_PORTAL"
                        TargetCFrame = CFrame.new(EndPortalPos)
                    else
                        TargetCFrame = nil
                        if root then root.Velocity = Vector3.zero end
                    end
                    return
                end

                -- ── LAVA CURSE ──────────────────────────────────────────────
                local shouldAbsorbLava = false
                if CurrentLava.Part and CurrentLava.Prompt then
                    local lavaPos  = CurrentLava.Part.Position
                    local zonePart = nil
                    pcall(function() zonePart = workspace.Effects.Zones["Zone"..CurrentZoneIndex]:FindFirstChild("Zone") end)
                    if zonePart then
                        if (Vector2.new(lavaPos.X,lavaPos.Z) - Vector2.new(zonePart.Position.X,zonePart.Position.Z)).Magnitude <= 300 then
                            shouldAbsorbLava = true
                        end
                    else
                        if (Vector2.new(lavaPos.X,lavaPos.Z) - Vector2.new(root.Position.X,root.Position.Z)).Magnitude <= 350 then
                            shouldAbsorbLava = true
                        end
                    end
                end

                if shouldAbsorbLava then
                    if ZoneState ~= "ABSORBING_CURSE" then
                        PreviousZoneState    = ZoneState
                        ZoneState            = "ABSORBING_CURSE"
                        _G.LavaFailSafeTimer = tick()
                    end
                    if tick() - _G.LavaFailSafeTimer > 10 then
                        if CurrentLava.Part and CurrentLava.Part.Parent then
                            IgnoredHazards[CurrentLava.Part.Parent] = tick() + 60
                        end
                        ZoneState = PreviousZoneState or "FLYING"; return
                    end
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    TargetCFrame      = CFrame.new(CurrentLava.Part.Position)
                    if (root.Position - CurrentLava.Part.Position).Magnitude <= 12 then
                        root.Velocity = Vector3.zero
                        if not isHoldingLava then
                            isHoldingLava = true
                            task.spawn(function()
                                pcall(function()
                                    local p = CurrentLava.Prompt
                                    if p then
                                        p.RequiresLineOfSight   = false
                                        p.MaxActivationDistance = 50
                                        local holdTime = p.HoldDuration > 0 and p.HoldDuration or 2.0
                                        p:InputHoldBegin()
                                        VIM:SendKeyEvent(true,  Enum.KeyCode.E, false, game)
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
                        -- V7 FIX: Reset smoothPos khi thoát ABSORBING_CURSE ở zone 7
                        -- Nhân vật đang ở mặt đất → cần reinit underground smooth descent
                        _smoothPos = nil
                        _undergroundCurrentY = nil  -- force re-lerp xuống underground
                        ZoneState = PreviousZoneState or "FLYING"
                    end
                end

                -- ── SKILL_BLOCKING đã được xử lý background trong TriggerSkillBlock
                -- ZoneState không còn bị đổi sang SKILL_BLOCKING nữa
                -- → attack loop tiếp tục bình thường khi đỡ Firefly / Hiken

                -- ── DODGE TRIGGER ────────────────────────────────────────────
                if CurrentZoneIndex ~= 5 and CurrentHazard.Type ~= "None"
                and ZoneState ~= "DODGING" then

                    local action    = CurrentHazard.Action  or "DODGE"
                    local evadeDist = CurrentHazard.MinDist or EvadeDistance
                    if CurrentHazard.Instance then
                        IgnoredHazards[CurrentHazard.Instance] = tick() + 8
                    end
                    if ZoneState ~= "ABSORBING_CURSE" then PreviousZoneState = ZoneState end
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil

                    if action == "BLOCK" then
                        -- ── Lightning: đứng tại chỗ, hold block ngay, KHÔNG dodge ──
                        -- Không đổi ZoneState → attack loop tiếp tục sau khi block xong
                        local char2 = Player.Character
                        local wpn2  = char2 and char2:FindFirstChildOfClass("Tool")
                        TriggerSkillBlock(wpn2 and wpn2.Name or "Melee", 1.5)
                        print("🛡️⚡ Lightning BLOCK: đứng tại chỗ, hold 1.5s")

                    elseif action == "DODGE_DEEP" and _isUndergroundMode then
                        -- ── Enkai underground: sâu thêm 5 studs ─────────────────────
                        ZoneState = "DODGING"
                        _currentDodgeIsAoe = false
                        local deeperY = (_undergroundCurrentY or root.Position.Y) - 5
                        TargetCFrame = CFrame.new(root.Position.X, deeperY, root.Position.Z)
                        DodgeTimer = tick() + DODGE_RETURN_WAIT
                        print("⬇️ DODGE_DEEP underground: Enkai → sâu thêm 5 studs, đứng yên", DODGE_RETURN_WAIT, "s")

                    else
                        -- ── DODGE thường: ArrowRain (80 studs), Normal AoE (40), BossSkill ──
                        ZoneState = "DODGING"
                        -- ArrowRain type = "ArrowRain" → (type == "Normal") = false → không block sau
                        -- Normal AoE type = "Normal" → block sau
                        _currentDodgeIsAoe = (CurrentHazard.Type == "Normal")

                        local evadeDir = (root.Position - CurrentHazard.Position)
                        if evadeDir.Magnitude < 0.1 then
                            local rand = math.random(0, 3)
                            evadeDir = ({
                                Vector3.new(1,0,0), Vector3.new(-1,0,0),
                                Vector3.new(0,0,1), Vector3.new(0,0,-1)
                            })[rand+1]
                        end
                        local flatDir = Vector3.new(evadeDir.X, 0, evadeDir.Z)
                        DodgeTimer   = tick() + (evadeDist / MoveSpeed) + DODGE_RETURN_WAIT
                        TargetCFrame = CFrame.new(root.Position + flatDir.Unit * evadeDist)
                        print("🏃 DODGE:", CurrentHazard.Instance and CurrentHazard.Instance.Name or "Normal",
                              action, "→", evadeDist, "studs | aoe=", _currentDodgeIsAoe)
                    end
                end

                if ZoneState == "DODGING" then
                    IsReadyToAttack   = false
                    CurrentTargetRoot = nil
                    if tick() > DodgeTimer then
                        CurrentHazard.Type = "None"
                        if _currentDodgeIsAoe then
                            -- Normal AoE → trigger block ngắn 0.5s sau khi dodge xong
                            _currentDodgeIsAoe = false
                            local char2 = Player.Character
                            local wpn2  = char2 and char2:FindFirstChildOfClass("Tool")
                            TriggerSkillBlock(wpn2 and wpn2.Name or "Melee", 0.5)
                            -- Đợi block duration + overhead rồi mới resume attack
                            DodgeTimer = tick() + 0.7
                            print("🛡️ BLOCK 0.5s sau AoE dodge → resume sau 0.7s")
                        elseif _G.SkillBlocking then
                            -- Block đang chạy (từ lần trước): chờ thêm
                            DodgeTimer = tick() + 0.1
                        else
                            -- Không block hoặc block đã xong → resume attack
                            ZoneState = PreviousZoneState or "ATTACKING"
                            print("✅ DODGE xong → quay lại:", ZoneState)
                        end
                    else
                        return
                    end
                end

                -- ── ZONE STATE MACHINE ──────────────────────────────────────
                local zonePart = nil
                pcall(function() zonePart = workspace.Effects.Zones["Zone"..CurrentZoneIndex]:FindFirstChild("Zone") end)

                if zonePart then
                    local boxCenter = zonePart.Position
                    local floorY    = GetZoneFloor(CurrentZoneIndex, boxCenter)

                    -- Zone 7 & 8: đứng dưới lòng đất thay vì bay
                    -- Zone khác: bay trên đầu mob (floorY + 40 / floorY + 20)
                    local isUnderground = (CurrentZoneIndex >= 7)
                    local waitPos
                    if isUnderground then
                        waitPos = Vector3.new(boxCenter.X, floorY - UNDERGROUND_DEPTH, boxCenter.Z)
                        _isUndergroundMode = true
                    else
                        waitPos = Vector3.new(boxCenter.X, floorY + 20, boxCenter.Z)
                        _isUndergroundMode = false
                        _undergroundCurrentY = nil
                    end

                    local mobs = GetMobsInZone(boxCenter)

                    if ZoneState == "FLYING" then
                        local targetY
                        if isUnderground then
                            targetY = floorY - UNDERGROUND_DEPTH
                        else
                            targetY = math.max(root.Position.Y, floorY + 40)
                        end
                        TargetCFrame = CFrame.new(Vector3.new(boxCenter.X, targetY, boxCenter.Z))
                        CurrentTargetRoot = nil
                        local xzDist = (Vector2.new(root.Position.X, root.Position.Z)
                                      - Vector2.new(boxCenter.X, boxCenter.Z)).Magnitude
                        if xzDist < 15 then
                            if CurrentZoneIndex == 5 then
                                ZoneState = "ZONE5_SURVIVAL"; Timer = tick() + 30; Z5Index = 1
                            else
                                -- Nếu đã có mob ngay → attack luôn, không chờ
                                if #mobs > 0 then
                                    ZoneState = "ATTACKING"
                                else
                                    ZoneState = "WAITING_SPAWN"; Timer = tick() + WaitSpawnTime
                                end
                            end
                        end

                    elseif ZoneState == "ZONE5_SURVIVAL" then
                        IsReadyToAttack = false; CurrentTargetRoot = nil
                        local z5t = Zone5Points[Z5Index]
                        TargetCFrame = CFrame.new(z5t)
                        if (Vector3.new(root.Position.X,0,root.Position.Z)
                          - Vector3.new(z5t.X,0,z5t.Z)).Magnitude < 10 then
                            Z5Index = Z5Index < #Zone5Points and Z5Index + 1 or 1
                        end
                        if tick() > Timer then
                            CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.1)
                        end

                    elseif ZoneState == "WAITING_SPAWN" then
                        -- FIX: đứng ở waitPos nhưng KHÔNG reset mỗi frame
                        if TargetCFrame == nil then TargetCFrame = CFrame.new(waitPos) end
                        CurrentTargetRoot = nil; IsReadyToAttack = false
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            CurrentZoneIndex = CurrentZoneIndex + 1; ZoneState = "FLYING"; task.wait(0.1)
                        end

                    elseif ZoneState == "GATHERING" then
                        -- Shortcut: luôn vào ATTACKING ngay
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        else
                            ZoneState = "WAITING_SPAWN"; Timer = tick() + WaitSpawnTime
                        end

                    elseif ZoneState == "ATTACKING" then
                        if #mobs == 0 then
                            IsReadyToAttack = false; CurrentTargetRoot = nil
                            ZoneState = "VERIFY_CLEAR"; Timer = tick() + 0.8
                        else
                            -- Target mob gần nhất
                            local bestMob, bestD = mobs[1], math.huge
                            for _, m in ipairs(mobs) do
                                local mr = GetRoot(m)
                                if mr then
                                    local d = (mr.Position - root.Position).Magnitude
                                    if d < bestD then bestD = d; bestMob = m end
                                end
                            end
                            CurrentTargetRoot = GetRoot(bestMob)
                            IsReadyToAttack   = true
                        end

                    elseif ZoneState == "VERIFY_CLEAR" then
                        -- FIX: không bay về tâm zone, đứng im chờ 0.8s
                        IsReadyToAttack = false; CurrentTargetRoot = nil
                        if #mobs > 0 then
                            ZoneState = "ATTACKING"
                        elseif tick() > Timer then
                            if CurrentZoneIndex == 7 then
                                ZoneState = "WAIT_30S"; Timer = tick() + 20
                            else
                                CurrentZoneIndex = CurrentZoneIndex + 1
                                ZoneState = "FLYING"; task.wait(0.1)
                            end
                        end

                    elseif ZoneState == "WAIT_30S" then
                        TargetCFrame = CFrame.new(waitPos)
                        CurrentTargetRoot = nil; IsReadyToAttack = false
                        if tick() > Timer then CurrentZoneIndex = 8; ZoneState = "FLYING" end
                    end
                else
                    TargetCFrame      = nil
                    CurrentTargetRoot = nil
                    IsReadyToAttack   = false
                    ZoneState         = "FLYING"
                    task.wait(0.5)
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [16] AUTO BLOCK — ĐÃ XÓA (V4)
-- Thay bằng TriggerSkillBlock() trong [5-B]
-- Chỉ block khi detect Firefly hoặc Hiken
-- ==========================================

-- ==========================================
-- [17] AUTO ATTACK — V7 CORRECT SPEED + COMBO
-- V7 Changes vs V6:
--   • MAX_COMBO = 5 (đúng game combo count)
--   • strikeDelay = 0.366s (đúng game attack speed, V5 dùng 0.22 quá nhanh)
--   • comboResetDelay = 0.6s giữ nguyên
--   • Không double-push target list (giữ từ V6)
-- ==========================================
task.spawn(function()
    local CombatRegister   = ReplicatedStorage:WaitForChild("Events"):WaitForChild("CombatRegister")
    local CombatAnimFolder = ReplicatedStorage:WaitForChild("CombatAnimations")
    local currentCombo     = 1
    local MAX_COMBO        = 5      -- V7: đúng game combo (5 hit)
    local strikeDelay      = 0.366  -- V7: đúng game attack speed
    local comboResetDelay  = 0.6
    local _lastFireTime    = 0

    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsReadyToAttack and IsFarmingReady and not _G.IsProcessingFruit then
            local char = Player.Character
            if char and char.Parent then
                local now = tick()
                if now - _lastFireTime >= strikeDelay then
                    local fired = false
                    pcall(function()
                        local tool           = CheckAndEquipWeapon()
                        local realWeaponName = tool and tool.Name or "Melee"
                        local weaponType, fakeAnim = GetAttackAnim(realWeaponName, currentCombo)

                        if not fakeAnim or currentCombo > MAX_COMBO then
                            -- Anim không tồn tại hoặc combo vượt max → reset combo
                            currentCombo  = 1
                            _lastFireTime = now + comboResetDelay - strikeDelay
                            return
                        end

                        -- V6 FIX: chỉ push eRoot (BasePart), không push thêm m (Model)
                        -- → tránh server nhận double target, tránh lag/kick
                        local enemiesToHit = {}
                        local root         = char:FindFirstChild("HumanoidRootPart")
                        local primaryCFrame

                        if root then
                            for _, m in ipairs(GetMobsInZone(root.Position)) do
                                local eRoot = GetRoot(m)
                                if eRoot and (eRoot.Position - root.Position).Magnitude <= 300 then
                                    enemiesToHit[#enemiesToHit+1] = eRoot  -- chỉ BasePart, không push m
                                    if not primaryCFrame then primaryCFrame = eRoot.CFrame end
                                end
                            end
                        end
                        if not primaryCFrame and root then primaryCFrame = root.CFrame end

                        if #enemiesToHit > 0 and primaryCFrame then
                            _lastFireTime = now

                            local combo   = currentCombo
                            local wType   = weaponType
                            local anim    = fakeAnim
                            local targets = enemiesToHit
                            local pCF     = primaryCFrame

                            -- Song song: swingsfx + damage đồng thời
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1]="swingsfx",[2]=wType,[3]=combo,
                                        [4]="Ground",[5]=false,[6]=anim,[7]=2,[8]=1.5
                                    })
                                end)
                            end)
                            task.spawn(function()
                                pcall(function()
                                    CombatRegister:InvokeServer({
                                        [1]="damage",[2]=targets,[3]=wType,
                                        [4]={[1]=combo,[2]="Ground",[3]=wType},
                                        [5]=true,[6]=pCF,["aircombo"]="Ground"
                                    })
                                end)
                            end)

                            fired = true
                            currentCombo = currentCombo + 1
                        end
                    end)
                    if not fired then
                        -- Không có enemy / anim → không stamp time, retry ngay
                    end
                end
            end
        else
            currentCombo  = 1
            _lastFireTime = 0
        end
        task.wait(0.015)
    end
end)

-- ==========================================
-- [18] ANTI RAGDOLL / UNFREEZE LOOP
-- ==========================================
task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        if _G.AutoDungeon and IsFarmingReady then
            pcall(function()
                local char = Player.Character
                local hum  = char and char:FindFirstChild("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if char and char.Parent then
                    if hum then
                        hum.PlatformStand = false
                        hum.Sit           = false
                        -- V7 FIX: AutoRotate = false khi đang farm
                        -- AutoRotate = true → humanoid tự xoay về hướng velocity → conflict với CFrame manual → spinning
                        hum.AutoRotate = false
                        local state = hum:GetState()
                        if state == Enum.HumanoidStateType.Ragdoll
                        or state == Enum.HumanoidStateType.FallingDown
                        or state == Enum.HumanoidStateType.Physics then
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    end
                    if root and root.Anchored then root.Anchored = false end
                    if root then
                        for _, v in pairs(root:GetChildren()) do
                            -- V7 FIX: bảo vệ CVFD_AntiGravity — KHÔNG destroy
                            -- V5/V6 bug: destroy ALL BodyVelocity mỗi 0.1s → anti-grav bị xóa → character rơi/xoay
                            if v.Name == _antiGravName then continue end
                            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition")
                            or v:IsA("LinearVelocity") or v:IsA("VectorForce") or v:IsA("AlignPosition") then
                                v:Destroy()
                            end
                        end
                        -- Reset RotVelocity liên tục để tránh spin sau block
                        root.RotVelocity = Vector3.zero
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- ==========================================
-- [19] RUNSERVICE: STEPPED (ANTI STUN/FREEZE + NOCLIP)
-- V5 IMPROVE (từ fishing module):
--   • Cache BasePart list, chỉ rebuild khi character đổi (tránh GetDescendants mỗi frame)
--   • Backup noclip loop độc lập với task.wait(0.05) — vẫn chạy khi FPS < 5 / freeze
--   • Gen-based invalidation: Stop/Start nhanh không gây loop leak
-- ==========================================
local _noclipLastApply   = 0
local _noclipGen         = 0    -- tăng khi char đổi để invalidate backup loop cũ
local _noclipParts       = {}   -- cache BasePart list
local _noclipCharRef     = nil  -- character tương ứng với cache
local NOCLIP_APPLY_INTERVAL = 0.08

local function _rebuildNoclipCache(char)
    _noclipCharRef = char
    _noclipParts   = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then _noclipParts[#_noclipParts + 1] = p end
    end
end

-- Backup noclip loop: chạy song song với Stepped, đảm bảo CanCollide = false
-- ngay cả khi FPS < 5 hoặc game freeze (Stepped ngưng chạy)
local _backupNoclipGen = 0
local function _startBackupNoclip()
    _backupNoclipGen = _backupNoclipGen + 1
    local myGen = _backupNoclipGen
    task.spawn(function()
        while _G.AutoDungeon and _G.DungeonScriptID == currentScriptID and myGen == _backupNoclipGen do
            -- V7: dừng noclip trong khi block (block + noclip = kick)
            if not _G.NoclipPaused then
                local char = Player.Character
                if char and IsFarmingReady then
                    if char ~= _noclipCharRef then _rebuildNoclipCache(char) end
                    for _, p in ipairs(_noclipParts) do
                        if p and p.Parent then p.CanCollide = false end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end
_startBackupNoclip()

-- Restart backup loop khi character respawn
-- V7 FIX: game 1 mạng → khi Humanoid.Died, dừng toàn bộ automation ngay
local function OnCharacterDied()
    print("💀 Character died → dừng toàn bộ automation")
    _G.AutoDungeon       = false
    IsFarmingReady       = false
    IsReadyToAttack      = false
    _G.SkillBlocking     = false
    _G.NoclipPaused      = false
    _G.IsProcessingFruit = false
    CurrentTargetRoot    = nil
    TargetCFrame         = nil
    ZoneState            = "FLYING"
    -- Cleanup platform
    if fakePlatform and fakePlatform.Parent then
        fakePlatform.CFrame = CFrame.new(0, -9999, 0)
    end
    -- Xóa anti-grav ngay
    local char = Player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then _removeAntiGrav(root) end
end

-- Hook vào character hiện tại
local function HookCharacterDeath(char)
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
        or char:WaitForChild("Humanoid", 5)
    if hum then
        hum.Died:Connect(OnCharacterDied)
    end
end

-- Hook ngay với character đang có
HookCharacterDeath(Player.Character)

Player.CharacterAdded:Connect(function(newChar)
    _noclipCharRef = nil  -- force rebuild noclip cache
    _startBackupNoclip()
    -- Hook death cho character mới
    HookCharacterDeath(newChar)
    -- V7: Game 1 mạng → CharacterAdded nghĩa là respawn sau chết
    -- KHÔNG tự động restart dungeon — người dùng phải chủ động re-run script
    -- (AutoDungeon đã = false từ OnCharacterDied)
end)

_G.CupidStepped = RunService.Stepped:Connect(function()
    if not _G.AutoDungeon or not IsFarmingReady then return end
    if _G.IsProcessingFruit then return end
    local char = Player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char or not char.Parent then return end

    pcall(function()
        _G.canuse  = true
        _G.midM1   = false
        _G.knocked = false
        _G.ragdoll = false
        _G.stunned = false
        _G.zombie  = false
        if not _G.SkillBlocking then _G.blocking = false end

        if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end

        -- Attributes anti-stun
        for attr in pairs(char:GetAttributes()) do
            if type(attr) == "string" then
                local a = attr:lower()
                if a:match("stun") or a:match("busy") or a:match("freeze")
                or a:match("knock") or a:match("ragdoll") or a:match("zombie") or a:match("down") then
                    char:SetAttribute(attr, nil)
                end
            end
        end

        -- Noclip: dùng cache, rebuild chỉ khi char đổi
        -- V7: skip noclip khi đang block (_G.NoclipPaused) để tránh block+noclip=kick
        local now = tick()
        if not _G.NoclipPaused and now - _noclipLastApply >= NOCLIP_APPLY_INTERVAL then
            _noclipLastApply = now
            if char ~= _noclipCharRef then _rebuildNoclipCache(char) end
            for _, v in ipairs(_noclipParts) do
                if v and v.Parent then
                    v.CanCollide = false
                    v.CastShadow = false
                end
            end
            -- Dọn ValueBase / Instance stun còn sót lại (không trong BasePart cache)
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("ValueBase") then
                    local n = v.Name:lower()
                    if n:match("stun") or n:match("knock") or n:match("ragdoll")
                    or n:match("zombie") or n:match("busy") then
                        v:Destroy()
                    end
                elseif not v:IsA("BasePart") then
                    local name = v.Name:lower()
                    if name:match("stun") or name:match("knock")
                    or name == "ragdoll" or name == "zombie" then
                        v:Destroy()
                    end
                end
            end
        end
    end)
end)

-- ==========================================
-- [20] RUNSERVICE: HEARTBEAT (MOVEMENT)
-- V4 — FPS-safe tween + stamina spoof noclip:
--
--   ① Cap dt → MAX_DT (0.07s): khi FPS < 5 / freeze,
--      dt có thể lên tới 0.5-1s, gây bước nhảy 50-100 studs/frame
--      → bị server kick hoặc teleport về. Cap lại để bước không quá lớn.
--
--   ② Cap step/frame → MAX_STEP_PER_FRAME (10 studs):
--      Bảo vệ thêm một lớp, dù dt cap rồi nhưng tốc độ cao vẫn có thể vượt.
--
--   ③ StartStaminaSpoof khi dist > 1.5:
--      Fire TakeStam:FireServer(0.545, "dash") mỗi 50ms.
--      Server nhận dash liên tục → bypass distance/teleport check.
--      StopStaminaSpoof khi tới nơi.
-- ==========================================
local isMovingForStamina = false
-- Cache footstep event 1 lần — tránh FindFirstChild mỗi Heartbeat frame
local _footstepEvent = ReplicatedStorage:FindFirstChild("Events")
    and ReplicatedStorage.Events:FindFirstChild("footstep") or nil
task.spawn(function()
    -- Đợi nếu chưa load
    if not _footstepEvent then
        local ev = ReplicatedStorage:WaitForChild("Events", 10)
        if ev then _footstepEvent = ev:WaitForChild("footstep", 10) end
    end
end)

-- V5: Anti-gravity BodyVelocity (từ fishing module)
-- Giữ character không bị gravity kéo xuống khi tween ngang
-- Tên "CVFD_AntiGravity" để tránh xung đột với fishing
local _antiGravName = "CVFD_AntiGravity"

local function _ensureAntiGrav(root)
    local ag = root:FindFirstChild(_antiGravName)
    if not ag then
        ag             = Instance.new("BodyVelocity")
        ag.Name        = _antiGravName
        ag.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
        ag.Velocity    = Vector3.zero
        ag.Parent      = root
    end
    return ag
end

local function _removeAntiGrav(root)
    if not root then return end
    local ag = root:FindFirstChild(_antiGravName)
    if ag then ag:Destroy() end
end

-- V5: Watchdog — phát hiện character bị stuck, force CFrame snap
-- Chạy 1 loop duy nhất, check mỗi 3s
local _watchdogPos    = nil
local _watchdogTimer  = 0
local WATCHDOG_INTERVAL = 3    -- giây không nhích → snap
local WATCHDOG_MIN_MOVE = 3    -- studs tối thiểu phải di chuyển

task.spawn(function()
    while _G.DungeonScriptID == currentScriptID do
        task.wait(WATCHDOG_INTERVAL)
        if not _G.AutoDungeon or not IsFarmingReady or _G.IsProcessingFruit then
            _watchdogPos = nil; continue
        end
        local char = Player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local activeTarget = CurrentTargetRoot or (TargetCFrame and TargetCFrame.Position)
        if not root or not activeTarget then _watchdogPos = nil; continue end

        local targetPos = type(activeTarget) == "userdata" and activeTarget.Position or activeTarget
        local curPos    = root.Position
        local distToTarget = (curPos - targetPos).Magnitude

        -- Hướng tới target rồi thì không cần snap
        if distToTarget < 8 then _watchdogPos = nil; continue end

        -- Kiểm tra có di chuyển không
        if _watchdogPos and (curPos - _watchdogPos).Magnitude < WATCHDOG_MIN_MOVE then
            -- BỊ STUCK → V6 FIX: lerp từ từ thay vì CFrame snap trực tiếp
            -- CFrame snap bị anticheat flag là teleport
            print("⚠️ Watchdog: stuck", math.floor(distToTarget), "studs → lerp correct")
            pcall(function()
                -- Chỉ set _smoothPos về nil để force reinit smooth movement
                -- Không CFrame snap để tránh TP check
                _smoothPos = nil
                local ag = root:FindFirstChild(_antiGravName)
                if ag then ag.Velocity = Vector3.zero end
                -- Nếu stuck quá lâu (>2 lần watchdog interval), mới snap nhẹ (chỉ XZ)
                local snapY = _isUndergroundMode
                    and (_undergroundCurrentY or curPos.Y)
                    or curPos.Y
                -- Snap XZ với bước nhỏ (5 studs) thay vì nhảy thẳng đến target
                local toTarget = Vector3.new(targetPos.X - curPos.X, 0, targetPos.Z - curPos.Z)
                if toTarget.Magnitude > 0 then
                    local smallStep = toTarget.Unit * math.min(5, toTarget.Magnitude)
                    root.CFrame = CFrame.new(curPos.X + smallStep.X, snapY, curPos.Z + smallStep.Z)
                        * root.CFrame.Rotation
                end
            end)
        end
        _watchdogPos = curPos
    end
end)

_G.CupidHeartbeat = RunService.Heartbeat:Connect(function(dt)
    if not _G.AutoDungeon then return end
    if not IsFarmingReady then
        if fakePlatform then fakePlatform.CFrame = CFrame.new(0, -9999, 0) end
        return
    end
    if _G.IsProcessingFruit then return end

    local char = Player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root or not char.Parent then return end

    -- Fake platform theo chân player — V6: Y động theo trạng thái tilt
    -- Khi IsReadyToAttack (tilted -90°): body nằm ngang, lowest Y ≈ HRP.Y → platform gần hơn
    -- Khi bình thường (đứng/bay): feet ≈ HRP.Y - 3.2 → platform center ở HRP.Y - 3.7
    if fakePlatform then
        local platformY
        if IsReadyToAttack then
            -- Tilted -90°: sau khi rotate X, feet trở thành forward/backward
            -- World Y của body parts ≈ root.Y ± limb_radius (~1 stud)
            -- Đặt platform sát phía dưới: root.Y - 0.8 (top ≈ root.Y - 0.3)
            platformY = root.Position.Y - 0.8
        else
            -- Đứng/bay bình thường: feet ≈ root.Y - 3.2
            -- Đặt platform: center root.Y - 3.7, top = root.Y - 3.2 (đúng mức feet)
            platformY = root.Position.Y - 3.7
        end
        fakePlatform.CFrame = CFrame.new(root.Position.X, platformY, root.Position.Z)
    end

    -- ── UNDERGROUND Y LERP ────────────────────────────────────────────
    -- Zone 7+8: Y target = mob.Y - UNDERGROUND_DEPTH (hoặc sâu hơn khi dodging Enkai)
    -- V7 FIX: KHÔNG tính undergroundY khi ABSORBING_CURSE → cho phép lên nhặt lava curse
    local undergroundY = nil
    local _skipUnderground = (ZoneState == "ABSORBING_CURSE")
    if _isUndergroundMode and not _skipUnderground then
        local refY = nil
        if CurrentTargetRoot and CurrentTargetRoot.Parent then
            refY = CurrentTargetRoot.Position.Y
        else
            refY = CachedZoneFloors[CurrentZoneIndex]
        end
        if refY then
            -- Nếu đang DODGING Enkai underground: sâu thêm 5 studs nữa
            local targetUnderY = refY - UNDERGROUND_DEPTH
            if ZoneState == "DODGING" and not _currentDodgeIsAoe then
                targetUnderY = targetUnderY - 5
            end
            if _undergroundCurrentY == nil then
                _undergroundCurrentY = root.Position.Y
            end
            local yDiff   = targetUnderY - _undergroundCurrentY
            local maxStep = UNDERGROUND_LERP_SPEED * math.min(dt, MAX_DT)
            local expStep = math.abs(yDiff) * (1 - math.exp(-10 * math.min(dt, MAX_DT)))
            local step    = math.min(math.max(expStep, 0.01), maxStep)
            _undergroundCurrentY = math.abs(yDiff) <= 0.05
                and targetUnderY
                or (_undergroundCurrentY + math.sign(yDiff) * step)
            undergroundY = _undergroundCurrentY
        end
    else
        if _undergroundCurrentY ~= nil and not _isUndergroundMode then
            _undergroundCurrentY = nil
            _smoothPos = nil
        end
        -- Khi ABSORBING_CURSE: giữ _undergroundCurrentY nhưng không dùng làm target Y
    end

    -- ── TARGET POSITION ───────────────────────────────────────────────
    local activeTargetPos = nil
    if CurrentTargetRoot and CurrentTargetRoot.Parent then
        local mobX = CurrentTargetRoot.Position.X
        local mobY = CurrentTargetRoot.Position.Y
        local mobZ = CurrentTargetRoot.Position.Z
        if undergroundY then
            activeTargetPos = Vector3.new(mobX, undergroundY, mobZ)
        else
            activeTargetPos = Vector3.new(mobX, mobY + AttackOffset, mobZ)
        end
    elseif TargetCFrame then
        -- V7 FIX Bug1: ABSORBING_CURSE và DODGING → dùng TargetCFrame.Position thật
        -- không override Y về undergroundY để:
        --   [1] Lava curse: nhân vật lên mặt đất nhặt curse
        --   [2] ArrowRain/Lightning dodge: chỉ né ngang, Y giữ nguyên
        local bypassUnderY = (ZoneState == "DODGING") or (ZoneState == "ABSORBING_CURSE")
        if undergroundY and not bypassUnderY then
            local tp = TargetCFrame.Position
            activeTargetPos = Vector3.new(tp.X, undergroundY, tp.Z)
        else
            activeTargetPos = TargetCFrame.Position
        end
    end

    if activeTargetPos then
        local currentPos  = root.Position
        local effectiveDt = math.min(dt, MAX_DT)

        -- V5: Đảm bảo anti-gravity BodyVelocity tồn tại khi đang di chuyển
        local ag = _ensureAntiGrav(root)

        -- ── FIX 3: SMOOTH MOVEMENT ZONE 7+8 ────────────────────────────
        -- Zone 1-6: lerp đơn giản, nhanh
        -- Zone 7+8: exponential smoothing riêng cho XZ và Y
        --   → không jitter, không snap, cực mượt dù FPS thấp
        local newPos
        if _isUndergroundMode then
            -- Init smooth pos nếu chưa có
            if _smoothPos == nil then _smoothPos = currentPos end

            -- XZ: exponential approach với acceleration cap
            local targetXZ  = Vector3.new(activeTargetPos.X, _smoothPos.Y, activeTargetPos.Z)
            local xzDist    = (Vector3.new(_smoothPos.X, 0, _smoothPos.Z)
                             - Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)).Magnitude
            -- Tốc độ XZ: smooth curve — nhanh khi xa (>5 studs), chậm dần khi gần
            local xzSpeed
            if xzDist > 20 then
                xzSpeed = MoveSpeed
            elseif xzDist > 5 then
                -- Ramp down: tránh overshoot khi đến gần
                xzSpeed = MoveSpeed * (0.3 + 0.7 * (xzDist / 20))
            else
                -- Cực gần: creepcrawl để không jitter
                xzSpeed = MoveSpeed * 0.3
            end
            local xzStep    = math.min(xzSpeed * effectiveDt, MAX_STEP_PER_FRAME, xzDist)
            local newXZ     = xzDist > 0.05
                and Vector3.new(_smoothPos.X, 0, _smoothPos.Z)
                   + (Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)
                   - Vector3.new(_smoothPos.X, 0, _smoothPos.Z)).Unit * xzStep
                or Vector3.new(activeTargetPos.X, 0, activeTargetPos.Z)

            -- Y: V8 FIX — khi DODGING (ArrowRain dodge) chỉ né ngang, Y = activeTargetPos.Y
            -- không force về undergroundY → tránh nhân vật đi lên/xuống khi dodge
            -- Tương tự ABSORBING_CURSE: lên mặt đất nhặt lava
            local useY
            if ZoneState == "DODGING" or ZoneState == "ABSORBING_CURSE" then
                -- Lerp Y về activeTargetPos.Y (giữ nguyên Y hoặc đến lava Y)
                local targetY  = activeTargetPos.Y
                local currentY = _smoothPos.Y
                local yDiff    = targetY - currentY
                local yStep    = math.min(math.abs(yDiff), UNDERGROUND_LERP_SPEED * math.min(dt, MAX_DT))
                useY = math.abs(yDiff) <= 0.1 and targetY or (currentY + math.sign(yDiff) * yStep)
            else
                useY = undergroundY or _smoothPos.Y
            end
            _smoothPos = Vector3.new(newXZ.X, useY, newXZ.Z)
            newPos     = _smoothPos

        else
            -- Zone thường: lerp đơn giản, nhưng Y phải có cap riêng chống anticheat
            _smoothPos = nil
            local dist = (currentPos - activeTargetPos).Magnitude
            if dist > 0.3 then
                local rawStep    = MoveSpeed * effectiveDt
                local cappedStep = math.min(rawStep, MAX_STEP_PER_FRAME)
                local direction  = (activeTargetPos - currentPos).Unit
                local stepVec    = direction * math.min(cappedStep, dist)

                -- V7 FIX: Chỉ cap Y DƯƠNG (đi lên) — anticheat chỉ flag "+Y Axis too fast"
                -- Y âm (hạ xuống) không cần cap → hạ nhanh mượt, không giật
                local cappedStepY
                if stepVec.Y > 0 then
                    cappedStepY = math.min(stepVec.Y, MAX_STEP_Y_PER_FRAME)
                else
                    cappedStepY = stepVec.Y  -- xuống: tự do
                end
                newPos = Vector3.new(
                    currentPos.X + stepVec.X,
                    currentPos.Y + cappedStepY,
                    currentPos.Z + stepVec.Z
                )
            else
                newPos = activeTargetPos
            end
        end

        -- ── ROTATION ─────────────────────────────────────────────────
        if IsReadyToAttack then
            if _isUndergroundMode then
                -- Zone 7+8 underground: mặt hướng mob theo XZ
                if CurrentTargetRoot and CurrentTargetRoot.Parent then
                    local flat = Vector3.new(
                        CurrentTargetRoot.Position.X - newPos.X, 0,
                        CurrentTargetRoot.Position.Z - newPos.Z)
                    if flat.Magnitude > 0.5 then
                        root.CFrame = CFrame.new(newPos, newPos + flat.Unit)
                    else
                        root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                    end
                else
                    root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                end
            else
                -- Zone thường (bay): giữ nguyên -90 tilt để attack đúng hướng
                -- V7 FIX: Chỉ lấy yaw hiện tại, giữ nguyên, không tính lại mỗi frame
                local _, currentYaw, _ = root.CFrame:ToOrientation()
                root.CFrame = CFrame.new(newPos)
                    * CFrame.Angles(0, currentYaw, 0)
                    * CFrame.Angles(math.rad(-90), 0, 0)
            end
            -- V7 FIX: XOÁ root.Velocity và hum:Move hoàn toàn
            -- root.Velocity = LookVector * WalkSpeed → xung đột BodyVelocity anti-grav → jitter
            -- hum:Move(0.01, 0, 0.01) → humanoid cố xoay về hướng northeast mỗi frame → spinning
            -- BodyVelocity đã handle anti-gravity, không cần set velocity thủ công
            root.RotVelocity = Vector3.new(0, 0, 0)
        else
            -- Đang di chuyển đến target: lerp rotation
            -- V7 FIX: dùng newPos thay vì currentPos → direction đúng sau khi move
            -- Dead zone 1.5 studs: tránh flip khi đã gần target
            -- =======================================================
            -- THAY THẾ TOÀN BỘ BẰNG ĐOẠN SAU (Bảo vệ triệt để vụ xoay):
            if _G.SkillBlocking then
                -- Nếu đang block: chỉ update vị trí, KHÔNG ép xoay để tránh lỗi vật lý
                root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                -- V8 FIX: reset RotVelocity mỗi frame TRONG block window
                -- Tránh angular velocity accumulate trong lúc block (gây spin sau release)
                root.RotVelocity = Vector3.zero
                pcall(function() root.AssemblyAngularVelocity = Vector3.zero end)
            else
                local flatDir = Vector3.new(activeTargetPos.X - newPos.X, 0, activeTargetPos.Z - newPos.Z)
                if flatDir.Magnitude > 1.5 then
                    local rotSpeed   = _isUndergroundMode and 8 or 12
                    local lerpFactor = 1 - math.exp(-rotSpeed * effectiveDt)
                    local targetRot  = CFrame.lookAt(newPos, newPos + flatDir.Unit)
                    local smoothRot  = root.CFrame:Lerp(targetRot, lerpFactor).Rotation
                    root.CFrame = CFrame.new(newPos) * smoothRot
                else
                    root.CFrame = CFrame.new(newPos) * root.CFrame.Rotation
                end
            end

            -- BẮT BUỘC THÊM DÒNG NÀY Ở DƯỚI CÙNG CỦA BLOCK LỆNH MOVE:
            -- Triệt tiêu hoàn toàn lực xoay vật lý rác sinh ra do va chạm
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.Velocity = Vector3.new(0, root.Velocity.Y, 0) -- Chỉ giữ nguyên Y để không rớt
        end
    else
        -- Không có target: reset smooth pos + xóa anti-gravity
        if _smoothPos then _smoothPos = nil end
        _removeAntiGrav(root)
    end
end)
