local myHero = myHero
local gsoLastQ = 0
local gsoLastQk = 0
local gsoLastW = 0
local gsoLastWk = 0
local gsoLastE = 0
local gsoLastEk = 0
local gsoLastR = 0
local gsoLastRk = 0
local gsoDelayedSpell = {}

local function gsoReducedDmg(unit, dmg, isAP)
        local def = isAP and unit.magicResist - myHero.magicPen or unit.armor - myHero.armorPen
        if def > 0 then def = isAP and myHero.magicPenPercent * def or myHero.bonusArmorPenPercent * def end
        return def > 0 and dmg * ( 100 / ( 100 + def ) ) or dmg * ( 2 - ( 100 / ( 100 - def ) ) )
end

local function gsoCalculateDmg(unit, spellData)
        local dmgType = spellData.dmgType and spellData.dmgType or ""
        if not unit then assert(false, "[234] CalculateDmg: unit is nil !") end
        if dmgType == "ad" and spellData.dmgAD then
                local dmgAD = spellData.dmgAD - unit.shieldAD
                return dmgAD < 0 and 0 or gsoReducedDmg(unit, dmgAD, false) 
        elseif dmgType == "ap" and spellData.dmgAP then
                local dmgAP = spellData.dmgAP - unit.shieldAD - unit.shieldAP
                return dmgAP < 0 and 0 or gsoReducedDmg(unit, dmgAP, true) 
        elseif dmgType == "true" and spellData.dmgTrue then
                return spellData.dmgTrue - unit.shieldAD
        elseif dmgType == "mixed" and spellData.dmgAD and spellData.dmgAP then
                local dmgAD = spellData.dmgAD - unit.shieldAD
                local shieldAD = dmgAD < 0 and (-1) * dmgAD or 0
                dmgAD = dmgAD < 0 and 0 or gsoReducedDmg(unit, dmgAD, false)
                local dmgAP = spellData.dmgAP - shieldAD - unit.shieldAP
                dmgAP = dmgAP < 0 and 0 or gsoReducedDmg(unit, dmgAP, true)
                return dmgAD + dmgAP
        end
        assert(false, "[234] CalculateDmg: spellData - expected array { dmgType = string(ap or ad or mixed or true), dmgAP = number or dmgAD = number or ( dmgAP = number and dmgAD = number ) or dmgTrue = number } !")
end


class "__gsoSpell"
        
        function __gsoSpell:__init()
                self.spellDraw = { q = false, w = false, e = false, r = false }
                if myHero.charName == "Aatrox" then
                        self.spellDraw = { q = true, qr = 650, e = true, er = 1000, r = true, rr = 550 }
                elseif myHero.charName == "Ahri" then
                        self.spellDraw = { q = true, qr = 880, w = true, wr = 700, e = true, er = 975, r = true, rr = 450 }
                elseif myHero.charName == "Akali" then
                        self.spellDraw = { q = true, qr = 600 + 120, w = true, wr = 475, e = true, er = 300, r = true, rr = 700 + 120 }
                elseif myHero.charName == "Alistar" then
                        self.spellDraw = { q = true, qr = 365, w = true, wr = 650 + 120, e = true, er = 350 }
                elseif myHero.charName == "Amumu" then
                        self.spellDraw = { q = true, qr = 1100, w = true, wr = 300, e = true, er = 350, r = true, rr = 550 }
                elseif myHero.charName == "Anivia" then
                        self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 650 + 120, r = true, rr = 750 }
                elseif myHero.charName == "Annie" then
                        self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 625, r = true, rr = 600 }
                elseif myHero.charName == "Ashe" then
                        self.spellDraw = { w = true, wr = 1200 }
                elseif myHero.charName == "AurelionSol" then
                        self.spellDraw = { q = true, qr = 1075, w = true, wr = 600, e = true, ef = function() local eLvl = myHero:GetSpellData(_E).level; if eLvl == 0 then return 3000 else return 2000 + 1000 * eLvl end end, r = true, rr = 1500 }
                elseif myHero.charName == "Azir" then
                        self.spellDraw = { q = true, qr = 740, w = true, wr = 500, e = true, er = 1100, r = true, rr = 250 }
                elseif myHero.charName == "Bard" then
                        self.spellDraw = { q = true, qr = 950, w = true, wr = 800, e = true, er = 900, r = true, rr = 3400 }
                elseif myHero.charName == "Blitzcrank" then
                        self.spellDraw = { q = true, qr = 925, e = true, er = 300, r = true, rr = 600 }
                elseif myHero.charName == "Brand" then
                        self.spellDraw = { q = true, qr = 1050, w = true, wr = 900, e = true, er = 625 + 120, r = true, rr = 750 + 120 }
                elseif myHero.charName == "Braum" then
                        self.spellDraw = { q = true, qr = 1000, w = true, wr = 650 + 120, r = true, rr = 1250 }
                elseif myHero.charName == "Caitlyn" then
                        self.spellDraw = { q = true, qr = 1250, w = true, wr = 800, e = true, er = 750, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 2000 else return 1500 + 500 * rLvl end end }
                elseif myHero.charName == "Camille" then
                        self.spellDraw = { q = true, qr = 325, w = true, wr = 610, e = true, er = 800, r = true, rr = 475 }
                elseif myHero.charName == "Cassiopeia" then
                        self.spellDraw = { q = true, qr = 850, w = true, wr = 800, e = true, er = 700, r = true, rr = 825 }
                elseif myHero.charName == "Chogath" then
                        self.spellDraw = { q = true, qr = 950, w = true, wr = 650, e = true, er = 500, r = true, rr = 175 + 120 }
                elseif myHero.charName == "Corki" then
                        self.spellDraw = { q = true, qr = 825, w = true, wr = 600, r = true, rr = 1225 }
                elseif myHero.charName == "Darius" then
                        self.spellDraw = { q = true, qr = 425, w = true, wr = 300, e = true, er = 535, r = true, rr = 460 + 120 }
                elseif myHero.charName == "Diana" then
                        self.spellDraw = { q = true, qr = 900, w = true, wr = 200, e = true, er = 450, r = true, rr = 825 }
                elseif myHero.charName == "DrMundo" then
                        self.spellDraw = { q = true, qr = 975, w = true, wr = 325 }
                elseif myHero.charName == "Draven" then
                        self.spellDraw = { e = true, er = 1050 }
                elseif myHero.charName == "Ekko" then
                        self.spellDraw = { q = true, qr = 1075, w = true, wr = 1600, e = true, er = 325 }
                elseif myHero.charName == "Elise" then
                        -- self.spellDraw = { need check form buff qHuman = 625, qSpider = 475, wHuman = 950, wSpider = math.huge(none), eHuman = 1075, eSpider = 750 }
                elseif myHero.charName == "Evelynn" then
                        self.spellDraw = { q = true, qr = 800, w = true, wf = function() local wLvl = myHero:GetSpellData(_W).level; if wLvl == 0 then return 1200 else return 1100 + 100 * wLvl end end, e = true, er = 210, r = true, rr = 450 }
                elseif myHero.charName == "Ezreal" then
                        self.spellDraw = { q = true, qr = 1150, w = true, wr = 1000, e = true, er = 475 }
                elseif myHero.charName == "Fiddlesticks" then
                        self.spellDraw = { q = true, qr = 575 + 120, w = true, wr = 650, e = true, er = 750 + 120, r = true, rr = 800 }
                elseif myHero.charName == "Fiora" then
                        self.spellDraw = { q = true, qr = 400, w = true, wr = 750, r = true, rr = 500 + 120 }
                elseif myHero.charName == "Fizz" then
                        self.spellDraw = { q = true, qr = 550 + 120, e = true, er = 400, r = true, rr = 1300 }
                elseif myHero.charName == "Galio" then
                        self.spellDraw = { q = true, qr = 825, w = true, wr = 350, e = true, er = 650, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 4000 else return 3250 + 750 * rLvl end end }
                elseif myHero.charName == "Gangplank" then
                        self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 650, e = true, er = 1000 }
                elseif myHero.charName == "Garen" then
                        self.spellDraw = { e = true, er = 325, r = true, rr = 400 + 120 }
                elseif myHero.charName == "Gnar" then
                        self.spellDraw = { q = true, qr = 1100, r = true, rr = 475, w = false, e = false } -- wr (mega gnar) = 550, er (mini gnar) = 475, er (mega gnar) = 600
                elseif myHero.charName == "Gragas" then
                        self.spellDraw = { q = true, qr = 850, e = true, er = 600, r = true, rr = 1000 }
                elseif myHero.charName == "Graves" then
                        self.spellDraw = { q = true, qr = 925, w = true, wr = 950, e = true, er = 475, r = true, rr = 1000 }
                elseif myHero.charName == "Hecarim" then
                        self.spellDraw = { q = true, qr = 350, w = true, wr = 575 + 120, r = true, rr = 1000 }
                elseif myHero.charName == "Heimerdinger" then
                        self.spellDraw = { q = false, w = true, wr = 1325, e = true, er = 970 } --  qr (noR) = 350, wr (R) = 450
                elseif myHero.charName == "Illaoi" then
                        self.spellDraw = { q = true, qr = 850, w = true, wr = 350 + 120, e = true, er = 900, r = true, rr = 450 }
                elseif myHero.charName == "Irelia" then
                        self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 825, e = true, er = 900, r = true, rr = 1000 }
                elseif myHero.charName == "Ivern" then
                        self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 750 + 120 }
                elseif myHero.charName == "Janna" then
                        self.spellDraw = { q = true, qf = function() local qt = Game.Timer() - gsoLastQk;if qt > 3 then return 1000 end local qrange = qt * 250;if qrange > 1750 then return 1750 end return qrange end, w = true, wr = 550 + 120, e = true, er = 800 + 120, r = true, rr = 725 }
                elseif myHero.charName == "JarvanIV" then
                        self.spellDraw = { q = true, qr = 770, w = true, wr = 625, e = true, er = 860, r = true, rr = 650 + 120 }
                elseif myHero.charName == "Jax" then
                        self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300, r = true }
                elseif myHero.charName == "Jayce" then
                        --self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300, r = true }  (Mercury Hammer: q=600+120, w=285, e=240+120; Mercury Cannon: q=1050/1470, w=active, e=650
                elseif myHero.charName == "Jhin" then
                        self.spellDraw = { q = true, qr = 550 + 120, w = true, wr = 3000, e = true, er = 750, r = true, rr = 3500 }
                elseif myHero.charName == "Jinx" then
                        self.spellDraw = { q = true, qf = function() if self:HasBuff(myHero, "jinxq") then return 525 + myHero.boundingRadius + 35 else local qExtra = 25 * myHero:GetSpellData(_Q).level; return 575 + qExtra + myHero.boundingRadius + 35 end end, w = true, wr = 1450, e = true, er = 900 }
                elseif myHero.charName == "KogMaw" then
                        self.spellDraw = { q = true, qr = 1175, e = true, er = 1280, r = true, rf = function() local rlvl = myHero:GetSpellData(_R).level; if rlvl == 0 then return 1200 else return 900 + 300 * rlvl end end }
                elseif myHero.charName == "Lucian" then
                        self.spellDraw = { q = true, qr = 500+120, w = true, wr = 900+350, e = true, er = 425, r = true, rr = 1200 }
                elseif myHero.charName == "Nami" then
                        self.spellDraw = { q = true, qr = 875, w = true, wr = 725, e = true, er = 800, r = true, rr = 2750 }
                elseif myHero.charName == "Sivir" then
                        self.spellDraw = { q = true, qr = 1250, r = true, rr = 1000 }
                elseif myHero.charName == "Teemo" then
                        self.spellDraw = { q = true, qr = 680, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then rLvl = 1 end return 150 + ( 250 * rLvl ) end }
                elseif myHero.charName == "Twitch" then
                        self.spellDraw = { w = true, wr = 950, e = true, er = 1200, r = true, rf = function() return myHero.range + 300 + ( myHero.boundingRadius * 2 ) end }
                elseif myHero.charName == "Tristana" then
                        self.spellDraw = { w = true, wr = 900 }
                elseif myHero.charName == "Varus" then
                        self.spellDraw = { q = true, qr = 1650, e = true, er = 950, r = true, rr = 1075 }
                elseif myHero.charName == "Vayne" then
                        self.spellDraw = { q = true, qr = 300, e = true, er = 550 }
                elseif myHero.charName == "Viktor" then
                        self.spellDraw = { q = true, qr = 600 + 2 * myHero.boundingRadius, w = true, wr = 700, e = true, er = 550 }
                elseif myHero.charName == "Xayah" then
                        self.spellDraw = { q = true, qr = 1100 }
                end
        end
        
        function __gsoSpell:GetLastSpellTimers()
                return gsoLastQ, gsoLastQk, gsoLastW, gsoLastWk, gsoLastE, gsoLastEk, gsoLastR, gsoLastRk
        end
        
        function __gsoSpell:HasBuff(unit, bName)
                bName = bName:lower()
                for i = 0, unit.buffCount do
                        local buff = unit:GetBuff(i)
                        if buff and buff.count > 0 and buff.name:lower() == bName then
                                return true
                        end
                end
                return false
        end
        
        function __gsoSpell:GetBuffDuration(unit, bName)
                bName = bName:lower()
                for i = 0, unit.buffCount do
                        local buff = unit:GetBuff(i)
                        if buff and buff.count > 0 and buff.name:lower() == bName then
                                return buff.duration
                        end
                end
                return 0
        end
        
        function __gsoSpell:GetBuffCount(unit, bName)
                bName = bName:lower()
                for i = 0, unit.buffCount do
                        local buff = unit:GetBuff(i)
                        if buff and buff.count > 0 and buff.name:lower() == bName then
                                return buff.count
                        end
                end
                return 0
        end
        
        function __gsoSpell:GetBuffStacks(unit, bName)
                bName = bName:lower()
                for i = 0, unit.buffCount do
                        local buff = unit:GetBuff(i)
                        if buff and buff.count > 0 and buff.name:lower() == bName then
                                return buff.stacks
                        end
                end
                return 0
        end
        
        function __gsoSpell:GetDamage(unit, spellData)
                return gsoCalculateDmg(unit, spellData)
        end
        
        function __gsoSpell:CheckSpellDelays(delays)
                if Game.Timer() < gsoLastQ + delays.q or Game.Timer() < gsoLastQk + delays.q then return false end
                if Game.Timer() < gsoLastW + delays.w or Game.Timer() < gsoLastWk + delays.w then return false end
                if Game.Timer() < gsoLastE + delays.e or Game.Timer() < gsoLastEk + delays.e then return false end
                if Game.Timer() < gsoLastR + delays.r or Game.Timer() < gsoLastRk + delays.r then return false end
                return true
        end
        
        function __gsoSpell:CustomIsReady(spell, cd)
                local passT
                if spell == _Q then
                        passT = Game.Timer() - gsoLastQk
                elseif spell == _W then
                        passT = Game.Timer() - gsoLastWk
                elseif spell == _E then
                        passT = Game.Timer() - gsoLastEk
                elseif spell == _R then
                        passT = Game.Timer() - gsoLastRk
                end
                local cdr = 1 - myHero.cdr
                cd = cd * cdr
                if passT - _G.gsoSDK.Utilities:GetMaxLatency() - 0.15 > cd then
                      return true
                end
                return false
        end
        
        function __gsoSpell:IsReady(spell, delays)
                return _G.gsoSDK.Cursor.IsCursorReady() and self:CheckSpellDelays(delays) and Game.CanUseSpell(spell) == 0
        end
        
        function __gsoSpell:CastSpell(spell, target, linear)
                if not spell then return false end
                local isQ = spell == _Q
                local isW = spell == _W
                local isE = spell == _E
                local isR = spell == _R
                if isQ then
                        spell = HK_Q
                        if Game.Timer() < gsoLastQ + 0.35 then
                                return false
                        end
                elseif isW then
                        spell = HK_W
                        if Game.Timer() < gsoLastW + 0.35 then
                                return false
                        end
                elseif isE then
                        spell = HK_E
                        if Game.Timer() < gsoLastE + 0.35 then
                                return false
                        end
                elseif isR then
                        spell = HK_R
                        if Game.Timer() < gsoLastR + 0.35 then
                                return false
                        end
                end
                local result = false
                if not target then
                        Control.KeyDown(spell)
                        Control.KeyUp(spell)
                        result = true
                else
                        local castpos = target.x and target or target.pos
                        if linear then myHero.pos:Extended(castpos, 750) end
                        if castpos:ToScreen().onScreen then
                                _G.gsoSDK.Cursor:SetCursor(cursorPos, castpos, 0.06)
                                Control.SetCursorPos(castpos)
                                Control.KeyDown(spell)
                                Control.KeyUp(spell)
                                _G.gsoSDK.Orbwalker:ResetMove()
                                result = true
                        end
                end
                if result then
                        if isQ then
                                gsoLastQ = Game.Timer()
                        elseif isW then
                                gsoLastW = Game.Timer()
                        elseif isE then
                                gsoLastE = Game.Timer()
                        elseif isR then
                                gsoLastR = Game.Timer()
                        end
                end
                return result
        end
        
        function __gsoSpell:CastManualSpell(spell)
                local kNum = 0
                if spell == _W then
                        kNum = 1
                elseif spell == _E then
                        kNum = 2
                elseif spell == _R then
                        kNum = 3
                end
                if Game.CanUseSpell(spell) == 0 then
                        for k,v in pairs(gsoDelayedSpell) do
                                if k == kNum then
                                        if _G.gsoSDK.Cursor.IsCursorReady() then
                                                v[1]()
                                                _G.gsoSDK.Cursor:SetCursor(cursorPos, nil, 0.05)
                                                if k == 0 then
                                                        gsoLastQ = Game.Timer()
                                                elseif k == 1 then
                                                        gsoLastW = Game.Timer()
                                                elseif k == 2 then
                                                        gsoLastE = Game.Timer()
                                                elseif k == 3 then
                                                        gsoLastR = Game.Timer()
                                                end
                                                gsoDelayedSpell[k] = nil
                                                break
                                        end
                                        if Game.Timer() - v[2] > 0.125 then
                                                gsoDelayedSpell[k] = nil
                                        end
                                        break
                                end
                        end
                end
        end
        
        function __gsoSpell:WndMsg(msg, wParam)
                local manualNum = -1
                if wParam == HK_Q and Game.Timer() > gsoLastQk + 1 and Game.CanUseSpell(_Q) == 0 then
                        gsoLastQk = Game.Timer()
                        manualNum = 0
                elseif wParam == HK_W and Game.Timer() > gsoLastWk + 1 and Game.CanUseSpell(_W) == 0 then
                        gsoLastWk = Game.Timer()
                        manualNum = 1
                elseif wParam == HK_E and Game.Timer() > gsoLastEk + 1 and Game.CanUseSpell(_E) == 0 then
                        gsoLastEk = Game.Timer()
                        manualNum = 2
                elseif wParam == HK_R and Game.Timer() > gsoLastRk + 1 and Game.CanUseSpell(_R) == 0 then
                        gsoLastRk = Game.Timer()
                        manualNum = 3 end
                if manualNum > -1 and not gsoDelayedSpell[manualNum] then
                        local drawMenu = _G.gsoSDK.Menu.gsodraw.circle1
                        if _G.gsoSDK.Menu.orb.keys.combo:Value() or _G.gsoSDK.Menu.orb.keys.harass:Value() or _G.gsoSDK.Menu.orb.keys.lasthit:Value() or _G.gsoSDK.Menu.orb.keys.laneclear:Value() or _G.gsoSDK.Menu.orb.keys.flee:Value() then
                                gsoDelayedSpell[manualNum] = {
                                        function()
                                                Control.KeyDown(wParam)
                                                Control.KeyUp(wParam)
                                                Control.KeyDown(wParam)
                                                Control.KeyUp(wParam)
                                                Control.KeyDown(wParam)
                                                Control.KeyUp(wParam)
                                        end,
                                        Game.Timer()
                                }
                        end
                end
        end
        
        function __gsoSpell:CreateDrawMenu()
                _G.gsoSDK.Menu.gsodraw:MenuElement({name = "Spell Ranges", id = "circle1", type = MENU,
                        onclick = function()
                                if self.spellDraw.q then
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrange:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrangecolor:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrangewidth:Hide(true)
                                end
                                if self.spellDraw.w then
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrange:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrangecolor:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrangewidth:Hide(true)
                                end
                                if self.spellDraw.e then
                                        _G.gsoSDK.Menu.gsodraw.circle1.erange:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.erangecolor:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.erangewidth:Hide(true)
                                end
                                if self.spellDraw.r then
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrange:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrangecolor:Hide(true)
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrangewidth:Hide(true)
                                end
                        end
                })
                if self.spellDraw.q then
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "Q Range", id = "note5", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                                onclick = function()
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrange:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrangecolor:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.qrangewidth:Hide()
                                end
                        })
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrange", name = "        Enabled", value = true})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrangecolor", name = "        Color", color = Draw.Color(255, 66, 134, 244)})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrangewidth", name = "        Width", value = 1, min = 1, max = 10})
                end
                if self.spellDraw.w then
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "W Range", id = "note6", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                                onclick = function()
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrange:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrangecolor:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.wrangewidth:Hide()
                                end
                        })
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrange", name = "        Enabled", value = true})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrangecolor", name = "        Color", color = Draw.Color(255, 92, 66, 244)})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrangewidth", name = "        Width", value = 1, min = 1, max = 10})
                end
                if self.spellDraw.e then
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "E Range", id = "note7", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                                onclick = function()
                                        _G.gsoSDK.Menu.gsodraw.circle1.erange:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.erangecolor:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.erangewidth:Hide()
                                end
                        })
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erange", name = "        Enabled", value = true})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erangecolor", name = "        Color", color = Draw.Color(255, 66, 244, 149)})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erangewidth", name = "        Width", value = 1, min = 1, max = 10})
                end
                if self.spellDraw.r then
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "R Range", id = "note8", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                                onclick = function()
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrange:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrangecolor:Hide()
                                        _G.gsoSDK.Menu.gsodraw.circle1.rrangewidth:Hide()
                                end
                        })
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrange", name = "        Enabled", value = true})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrangecolor", name = "        Color", color = Draw.Color(255, 244, 182, 66)})
                        _G.gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrangewidth", name = "        Width", value = 1, min = 1, max = 10})
                end
        end
        
        function __gsoSpell:Draw()
                local drawMenu = _G.gsoSDK.Menu.gsodraw.circle1
                if self.spellDraw.q and drawMenu.qrange:Value() then
                        local qrange = self.spellDraw.qf and self.spellDraw.qf() or self.spellDraw.qr
                        Draw.Circle(myHero.pos, qrange, drawMenu.qrangewidth:Value(), drawMenu.qrangecolor:Value())
                end
                if self.spellDraw.w and drawMenu.wrange:Value() then
                        local wrange = self.spellDraw.wf and self.spellDraw.wf() or self.spellDraw.wr
                        Draw.Circle(myHero.pos, wrange, drawMenu.wrangewidth:Value(), drawMenu.wrangecolor:Value())
                end
                if self.spellDraw.e and drawMenu.erange:Value() then
                        local erange = self.spellDraw.ef and self.spellDraw.ef() or self.spellDraw.er
                        Draw.Circle(myHero.pos, erange, drawMenu.erangewidth:Value(), drawMenu.erangecolor:Value())
                end
                if self.spellDraw.r and drawMenu.rrange:Value() then
                        local rrange = self.spellDraw.rf and self.spellDraw.rf() or self.spellDraw.rr
                        Draw.Circle(myHero.pos, rrange, drawMenu.rrangewidth:Value(), drawMenu.rrangecolor:Value())
                end
        end