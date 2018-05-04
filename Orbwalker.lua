local gsoLoadTime = Game.Timer()
local gsoIsTeemo = false
local gsoIsBlindedByTeemo = false
local gsoLastAttackLocal = 0
local gsoLastAttackServer = 0
local gsoLastMoveLocal = 0
local gsoMainMenu = nil
local gsoMenu = nil
local gsoDrawMenuMe = nil
local gsoDrawMenuHe = nil
local gsoLastMouseDown = 0
local gsoLastMovePos = myHero.pos
local gsoResetAttack = false
local gsoLastTarget = nil
local gsoTestCount = 0
local gsoTestStartTime = 0
local gsoLastAttackDiff = 0
local gsoBaseAASpeed = 1 / myHero.attackData.animationTime / myHero.attackSpeed
local gsoBaseWindUp = myHero.attackData.windUpTime / myHero.attackData.animationTime
local gsoAttackEndTime = myHero.attackData.endTime + 0.1
local gsoWindUpTime = myHero.attackData.windUpTime
local gsoAnimTime = myHero.attackData.animationTime
local gsoUOLoaded = { Ic = false, Gamsteron = false, Gos = false }
local gsoOnPreAttackC = {}
local gsoOnPostAttackC = {}
local gsoOnAttackC = {}
local gsoOnPreMoveC = {}
local gsoPostAttackBool = false
local gsoAttackEnabled = true
local gsoMovementEnabled = true

local function gsoGetAttackSpeed()
        return myHero.attackSpeed
end

local function gsoGetAvgLatency()
        local currentLatency = Game.Latency() * 0.001
        local latency = _G.gsoSDK.Utilities:GetMinLatency() + _G.gsoSDK.Utilities:GetMaxLatency() + currentLatency
        return latency / 3
end

local function gsoSetAttackTimers()
        gsoBaseAASpeed = 1 / myHero.attackData.animationTime / myHero.attackSpeed
        gsoBaseWindUp = myHero.attackData.windUpTime / myHero.attackData.animationTime
        local aaSpeed = gsoGetAttackSpeed() * gsoBaseAASpeed
        local animT = 1 / aaSpeed
        local windUpT = animT * gsoBaseWindUp
        gsoAnimTime = animT > myHero.attackData.animationTime and animT or myHero.attackData.animationTime
        gsoWindUpTime = windUpT > myHero.attackData.windUpTime and windUpT or myHero.attackData.windUpTime
end

local function gsoCheckTeemoBlind()
        for i = 0, myHero.buffCount do
                local buff = myHero:GetBuff(i)
                if buff and buff.count > 0 and buff.name:lower() == "blindingdart" and buff.duration > 0 then
                        return true
                end
        end
        return false
end

local function gsoCanAttack()
        return true
end

local function gsoCanMove()
        return true
end

class "__gsoOrbwalker"
        
        function __gsoOrbwalker:__init()
                self.Loaded = false
                self.SpellMoveDelays = { q = 0, w = 0, e = 0, r = 0 }
                self.SpellAttackDelays = { q = 0, w = 0, e = 0, r = 0 }
                _G.gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) if hero.charName == "Teemo" then gsoIsTeemo = true end end)
        end
        
        function __gsoOrbwalker:SetSpellMoveDelays(delays)
                self.SpellMoveDelays = delays
        end
        
        function __gsoOrbwalker:SetSpellAttackDelays(delays)
                self.SpellAttackDelays = delays
        end
        
        function __gsoOrbwalker:GetLastMovePos()
                return gsoLastMovePos
        end
        
        function __gsoOrbwalker:ResetMove()
                gsoLastMoveLocal = 0
        end
        
        function __gsoOrbwalker:ResetAttack()
                gsoResetAttack = true
        end
        
        function __gsoOrbwalker:GetLastTarget()
                return gsoLastTarget
        end
        
        function __gsoOrbwalker:CreateMenu(menu, uolMenu)
                gsoMainMenu = uolMenu
                gsoMenu = menu:MenuElement({name = "Orbwalker", id = "orb", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/orb.png" })
                        gsoMenu:MenuElement({name = "Enabled",  id = "enabledorb", tooltip = "Enabled Gamsteron's OnTick and OnDraw - Attack, Move, Draw Attack Range etc.", value = true})
                        gsoMenu:MenuElement({name = "Keys", id = "keys", type = MENU})
                                gsoMenu.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
                                gsoMenu.keys:MenuElement({name = "Harass Key", id = "harass", key = string.byte("C")})
                                gsoMenu.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
                                gsoMenu.keys:MenuElement({name = "LaneClear Key", id = "laneclear", key = string.byte("V")})
                                gsoMenu.keys:MenuElement({name = "Flee Key", id = "flee", key = string.byte("A")})
                        gsoMenu:MenuElement({name = "Extra WindUp Delay", tooltip = "Less Value = Better KITE", id = "windupdelay", value = 25, min = 0, max = 150, step = 10 })
                        gsoMenu:MenuElement({name = "Extra Anim Delay", tooltip = "Less Value = Better DPS [ for me 80 is ideal ] - lower value than 80 cause slow KITE ! Maybe for your PC ideal value is 0 ? You need test it in debug mode.", id = "animdelay", value = 80, min = 0, max = 150, step = 10 })
                        gsoMenu:MenuElement({name = "Extra LastHit Delay", tooltip = "Less Value = Faster Last Hit Reaction", id = "lhDelay", value = 0, min = 0, max = 50, step = 1 })
                        gsoMenu:MenuElement({name = "Extra Move Delay", tooltip = "Less Value = More Movement Clicks Per Sec", id = "humanizer", value = 200, min = 120, max = 300, step = 10 })
                        gsoMenu:MenuElement({name = "Debug Mode", tooltip = "Will Print Some Data", id = "enabled", value = false})
        end
        
        function __gsoOrbwalker:EnableGamsteronOrb()
                if not gsoMenu.enabledorb:Value() then gsoMenu.enabledorb:Value(true) end
                gsoMenu:Hide(false)
                gsoUOLoaded.Gamsteron = true
                gsoDrawMenuMe:Hide(false)
                gsoDrawMenuHe:Hide(false)
                _G.gsoSDK.TS.mainMenu.gsodraw.lasthit:Hide(false)
                _G.gsoSDK.TS.mainMenu.gsodraw.almostlasthit:Hide(false)
        end
        
        function __gsoOrbwalker:DisableGamsteronOrb()
                if gsoMenu.enabledorb:Value() then gsoMenu.enabledorb:Value(false) end
                gsoMenu:Hide(true)
                gsoUOLoaded.Gamsteron = false
                gsoDrawMenuMe:Hide(true)
                gsoDrawMenuHe:Hide(true)
                _G.gsoSDK.TS.mainMenu.gsodraw.lasthit:Hide(true)
                _G.gsoSDK.TS.mainMenu.gsodraw.almostlasthit:Hide(true)
        end
        
        function __gsoOrbwalker:EnableGosOrb()
                if not _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(true) end
                _G.Orbwalker:Hide(false)
                gsoUOLoaded.Gos = true
        end
        
        function __gsoOrbwalker:DisableGosOrb()
                if _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(false) end
                _G.Orbwalker:Hide(true)
                gsoUOLoaded.Gos = false
        end
        
        function __gsoOrbwalker:EnableIcOrb()
                if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.Loaded then
                        if not _G.SDK.Orbwalker.Menu.Enabled:Value() then _G.SDK.Orbwalker.Menu.Enabled:Value(true) end
                        _G.SDK.Orbwalker.Menu:Hide(false)
                        gsoUOLoaded.Ic = true
                end
        end
        
        function __gsoOrbwalker:DisableIcOrb()
                if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.Loaded then
                        if _G.SDK.Orbwalker.Menu.Enabled:Value() then _G.SDK.Orbwalker.Menu.Enabled:Value(false) end
                        _G.SDK.Orbwalker.Menu:Hide(true)
                        gsoUOLoaded.Ic = false
                end
        end
        
        ------------------------------------------------------------------------ UOL START
        function __gsoOrbwalker:UOL()
                if not self.Loaded and Game.Timer() > gsoLoadTime + 2.5 then
                        self.Loaded = true
                end
                if not self.Loaded then return end
                if gsoMainMenu.orbsel:Value() == 1 then
                        self:DisableIcOrb()
                        self:DisableGosOrb()
                        self:EnableGamsteronOrb()
                else
                        if _G.gsoSDK.Spell:CheckSpellDelays(self.SpellMoveDelays) then
                                self:UOL_SetMovement(true)
                        else
                                self:UOL_SetMovement(false)
                        end
                        if _G.gsoSDK.Spell:CheckSpellDelays(self.SpellAttackDelays) then
                                self:UOL_SetAttack(true)
                        else
                                self:UOL_SetAttack(false)
                        end
                        if gsoMainMenu.orbsel:Value() == 2 then
                                self:DisableIcOrb()
                                self:EnableGosOrb()
                                self:DisableGamsteronOrb()
                        elseif gsoMainMenu.orbsel:Value() == 3 then
                                if not _G.SDK or not _G.SDK.Orbwalker then
                                        print("To use IC's Orbwalker you need load it !")
                                        gsoMainMenu.orbsel:Value(1)
                                else
                                        self:EnableIcOrb()
                                        self:DisableGosOrb()
                                        self:DisableGamsteronOrb()
                                end
                        end
                end
        end
        function __gsoOrbwalker:UOL_ResetAttack()
                if _G.SDK and _G.SDK.Orbwalker then
                        _G.SDK.Orbwalker.AutoAttackResetted = true
                        _G.SDK.Orbwalker.LastAutoAttackSent = 0
                end
                gsoResetAttack = true
                GOS.AA.state = 1
                GOS.castAttack.state = 0
                GOS.castAttack.casting = GetTickCount() - 1000
        end
        function __gsoOrbwalker:UOL_SetMovement(boolean)
                if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:SetMovement(boolean) end
                gsoMovementEnabled = boolean
                GOS.BlockMovement = not boolean
        end
        function __gsoOrbwalker:UOL_SetAttack(boolean)
                if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:SetAttack(boolean) end
                gsoAttackEnabled = boolean
                GOS.BlockAttack = not boolean
        end
        function __gsoOrbwalker:UOL_OnPreAttack(func)
                _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPreAttack(func) end end, 2)
                gsoOnPreAttackC[#gsoOnPreAttackC+1] = func
        end
        function __gsoOrbwalker:UOL_OnPostAttack(func)
                _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPostAttack(func) end end, 2)
                gsoOnPostAttackC[#gsoOnPostAttackC+1] = func
                GOS:OnAttackComplete(func)
        end
        function __gsoOrbwalker:UOL_OnAttack(func)
                _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnAttack(func) end end, 2)
                gsoOnAttackC[#gsoOnAttackC+1] = func
                GOS:OnAttack(func)
        end
        function __gsoOrbwalker:UOL_OnPreMovement(func)
                _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPreMovement(func) end end, 2)
                gsoOnPreMoveC[#gsoOnPreMoveC+1] = func
        end
        function __gsoOrbwalker:UOL_CanMove()
                if gsoMainMenu.orbsel:Value() == 1 then
                        return self:CanMove()
                elseif gsoMainMenu.orbsel:Value() == 2 then
                        return GOS:CanMove()
                elseif gsoMainMenu.orbsel:Value() == 3 then
                        return _G.SDK.Orbwalker:CanMove(myHero)
                end
        end
        function __gsoOrbwalker:UOL_CanAttack()
                if gsoMainMenu.orbsel:Value() == 1 then
                        return self:CanAttack()
                elseif gsoMainMenu.orbsel:Value() == 2 then
                        return GOS:CanAttack()
                elseif gsoMainMenu.orbsel:Value() == 3 then
                        return _G.SDK.Orbwalker:CanAttack(myHero)
                end
        end
        function __gsoOrbwalker:UOL_IsAttacking()
                if gsoMainMenu.orbsel:Value() == 1 then
                        return not self:CanMove()
                elseif gsoMainMenu.orbsel:Value() == 2 then
                        return GOS:IsAttacking()
                elseif gsoMainMenu.orbsel:Value() == 3 then
                        return _G.SDK.Orbwalker:IsAutoAttacking(myHero)
                end
        end
        function __gsoOrbwalker:UOL_GetMode()
                if gsoMainMenu.orbsel:Value() == 1 then
                        if gsoMenu.keys.combo:Value() then
                                return "Combo"
                        elseif gsoMenu.keys.harass:Value() then
                                return "Harass"
                        elseif gsoMenu.keys.lasthit:Value() then
                                return "Lasthit"
                        elseif gsoMenu.keys.laneclear:Value() then
                                return "Clear"
                        elseif gsoMenu.keys.flee:Value() then
                                return "Flee"
                        else
                                return ""
                        end
                elseif gsoMainMenu.orbsel:Value() == 2 then
                        return GOS:GetMode()
                elseif gsoMainMenu.orbsel:Value() == 3 then
                        if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
                                return "Combo"
                        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
                                return "Harass"
                        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then
                                return "Clear"
                        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
                                return "Lasthit"
                        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
                                return "Flee"
                        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
                                return "Jungleclear"
                        else
                                return ""
                        end
                end
        end
        function __gsoOrbwalker:UOL_LoadedIc()
                return gsoUOLoaded.Ic
        end
        function __gsoOrbwalker:UOL_LoadedGos()
                return gsoUOLoaded.Gos
        end
        function __gsoOrbwalker:UOL_LoadedGamsteron()
                return gsoUOLoaded.Gamsteron
        end

        ------------------------------------------------------------------------ UOL END
        
        function __gsoOrbwalker:CreateDrawMenu(menu)
                gsoDrawMenuMe = menu:MenuElement({name = "MyHero Attack Range", id = "me", type = MENU})
                        gsoDrawMenuMe:MenuElement({name = "Enabled",  id = "enabled", value = true})
                        gsoDrawMenuMe:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 49, 210, 0)})
                        gsoDrawMenuMe:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
                gsoDrawMenuHe = menu:MenuElement({name = "Enemy Attack Range", id = "he", type = MENU})
                        gsoDrawMenuHe:MenuElement({name = "Enabled",  id = "enabled", value = true})
                        gsoDrawMenuHe:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 255, 0, 0)})
                        gsoDrawMenuHe:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
        end
        
        function __gsoOrbwalker:WndMsg(msg, wParam)
                if wParam == HK_TCO then
                        gsoLastAttackLocal = Game.Timer()
                end
        end
        
        function __gsoOrbwalker:Draw()
                if not gsoMenu.enabledorb:Value() then return end
                if gsoDrawMenuMe.enabled:Value() and myHero.pos:ToScreen().onScreen then
                        Draw.Circle(myHero.pos, myHero.range + myHero.boundingRadius + 35, gsoDrawMenuMe.width:Value(), gsoDrawMenuMe.color:Value())
                end
                if gsoDrawMenuHe.enabled:Value() then
                        local enemyHeroes = _G.gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                        for i = 1, #enemyHeroes do
                                local enemy = enemyHeroes[i]
                                if enemy.pos:ToScreen().onScreen then
                                        Draw.Circle(enemy.pos, enemy.range + enemy.boundingRadius + 35, gsoDrawMenuHe.width:Value(), gsoDrawMenuHe.color:Value())
                                end
                        end
                end
        end
        
        ------------------------------------------------------------
        ------------------------------------------------------------
        ------------------------------------------------------------
        
        function __gsoOrbwalker:CanAttackEvent(func)
                gsoCanAttack = func
        end
        
        function __gsoOrbwalker:CanMoveEvent(func)
                gsoCanMove = func
        end
        
        function __gsoOrbwalker:Attack(unit)
                gsoResetAttack = false
                _G.gsoSDK.Cursor:SetCursor(cursorPos, unit.pos, 0.06)
                Control.SetCursorPos(unit.pos)
                Control.KeyDown(HK_TCO)
                Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
                Control.mouse_event(MOUSEEVENTF_RIGHTUP)
                Control.KeyUp(HK_TCO)
                gsoLastMoveLocal = 0
                gsoLastAttackLocal  = Game.Timer()
                gsoLastTarget = unit
        end
        
        function __gsoOrbwalker:Move()
                if Control.IsKeyDown(2) then gsoLastMouseDown = Game.Timer() end
                gsoLastMovePos = mousePos
                Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
                Control.mouse_event(MOUSEEVENTF_RIGHTUP)
                gsoLastMoveLocal = Game.Timer() + gsoMenu.humanizer:Value() * 0.001
        end
        
        function __gsoOrbwalker:MoveToPos(pos)
                if Control.IsKeyDown(2) then gsoLastMouseDown = Game.Timer() end
                _G.gsoSDK.Cursor:SetCursor(cursorPos, pos, 0.06)
                Control.SetCursorPos(pos)
                Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
                Control.mouse_event(MOUSEEVENTF_RIGHTUP)
                gsoLastMoveLocal = Game.Timer() + gsoMenu.humanizer:Value() * 0.001
        end
        
        function __gsoOrbwalker:CanAttack()
                if not gsoCanAttack() then return false end
                if not _G.gsoSDK.Spell:CheckSpellDelays(self.SpellAttackDelays) then return false end
                if gsoIsBlindedByTeemo then
                        return false
                end
                if gsoResetAttack then
                        return true
                end
                local animDelay = gsoMenu.animdelay:Value() * 0.001
                if Game.Timer() < gsoLastAttackLocal + gsoAnimTime + gsoLastAttackDiff + animDelay - 0.15 - gsoGetAvgLatency() then
                        return false
                end
                return true
        end
        
        function __gsoOrbwalker:CanMove()
                if not gsoCanMove() then return false end
                if not _G.gsoSDK.Spell:CheckSpellDelays(self.SpellMoveDelays) then return false end
                local latency = math.min(_G.gsoSDK.Utilities:GetMinLatency(), Game.Latency() * 0.001) * 0.75
                latency = math.min(latency, _G.gsoSDK.Utilities:GetUserLatency())
                local windUpDelay = gsoMenu.windupdelay:Value() * 0.001
                if Game.Timer() < gsoLastAttackLocal + gsoWindUpTime + gsoLastAttackDiff - latency - 0.025 + windUpDelay then
                        return false
                end
                if gsoLastAttackLocal > gsoLastAttackServer and Game.Timer() < gsoLastAttackLocal + gsoWindUpTime + gsoLastAttackDiff - latency + 0.025 + windUpDelay then return false end
                return true
        end
        
        function __gsoOrbwalker:AttackMove(unit)
                gsoLastTarget = nil
                if gsoAttackEnabled and unit and unit.pos:ToScreen().onScreen and self:CanAttack() then
                        local args = { Target = unit, Process = true }
                        for i = 1, #gsoOnPreAttackC do
                                gsoOnPreAttackC[i](args)
                        end
                        if args.Process and args.Target and not args.Target.dead and args.Target.isTargetable and args.Target.valid then
                                self:Attack(args.Target)
                                gsoPostAttackBool = true
                        end
                elseif gsoMovementEnabled and self:CanMove() then
                        if gsoPostAttackBool then
                                for i = 1, #gsoOnPostAttackC do
                                        gsoOnPostAttackC[i]()
                                end
                                gsoPostAttackBool = false
                        end
                        if Game.Timer() > gsoLastMoveLocal then
                                local args = { Target = nil, Process = true }
                                for i = 1, #gsoOnPreMoveC do
                                        gsoOnPreMoveC[i](args)
                                end
                                if args.Process then
                                        if not args.Target then
                                                self:Move()
                                        elseif args.Target.x then
                                                self:MoveToPos(args.Target)
                                        elseif args.Target.pos then
                                                self:MoveToPos(args.Target.pos)
                                        else
                                                assert(false, "Gamsteron OnPreMovement Event: expected Vector !")
                                        end
                                end
                        end
                end
        end
        
        function __gsoOrbwalker:Tick()
                self:UOL()
                if not gsoMenu.enabledorb:Value() then return end
                if gsoIsTeemo then gsoIsBlindedByTeemo = gsoCheckTeemoBlind() end
                -- SERVER ATTACK START TIME
                if myHero.attackData.endTime > gsoAttackEndTime then
                        for i = 1, #gsoOnAttackC do
                                gsoOnAttackC[i]()
                        end
                        local serverStart = myHero.attackData.endTime - myHero.attackData.animationTime
                        gsoLastAttackDiff = serverStart - gsoLastAttackLocal
                        gsoLastAttackServer = Game.Timer()
                        gsoAttackEndTime = myHero.attackData.endTime
                        if gsoMenu.enabled:Value() then
                                if gsoTestCount == 0 then
                                        gsoTestStartTime = Game.Timer()
                                end
                                gsoTestCount = gsoTestCount + 1
                                if gsoTestCount == 5 then
                                        print("5 attacks in time: " .. tostring(Game.Timer() - gsoTestStartTime) .. "[sec]")
                                        gsoTestCount = 0
                                        gsoTestStartTime = 0
                                end
                        end
                end
                -- RESET ATTACK
                if gsoLastAttackLocal > gsoLastAttackServer and Game.Timer() > gsoLastAttackLocal + 0.15 + _G.gsoSDK.Utilities:GetMaxLatency() then
                        if gsoMenu.enabled:Value() then
                                print("reset attack1")
                        end
                        gsoLastAttackLocal = 0
                elseif gsoLastAttackLocal < gsoLastAttackServer and Game.Timer() < gsoLastAttackLocal + myHero.attackData.windUpTime and myHero.pathing.hasMovePath then
                        if gsoMenu.enabled:Value() then
                                print("reset attack2")
                        end
                        gsoLastAttackLocal = 0
                end
                -- ATTACK TIMERS
                gsoSetAttackTimers()
                -- CHECK IF CAN ORBWALK
                local isEvading = ExtLibEvade and ExtLibEvade.Evading
                if not _G.gsoSDK.Cursor:IsCursorReady() or Game.IsChatOpen() or isEvading then
                        return
                end
                -- ORBWALKER MODE
                if gsoMenu.keys.combo:Value() then
                        self:AttackMove(_G.gsoSDK.TS:GetComboTarget())
                elseif gsoMenu.keys.harass:Value() then
                        if _G.gsoSDK.Farm:CanLastHit() then
                                self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
                        else
                                self:AttackMove(_G.gsoSDK.TS:GetComboTarget())
                        end
                elseif gsoMenu.keys.lasthit:Value() then
                        self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
                elseif gsoMenu.keys.laneclear:Value() then
                        if _G.gsoSDK.Farm:CanLastHit() then
                                self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
                        elseif _G.gsoSDK.Farm:CanLaneClear() then
                                self:AttackMove(_G.gsoSDK.TS:GetLaneClearTarget())
                        else
                                self:AttackMove()
                        end
                elseif gsoMenu.keys.flee:Value() then
                        if gsoMovementEnabled and Game.Timer() > gsoLastMoveLocal and self:CanMove() then
                                self:Move()
                        end
                elseif Game.Timer() < gsoLastMouseDown + 1 then
                        Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
                        gsoLastMouseDown = 0
                end
        end
