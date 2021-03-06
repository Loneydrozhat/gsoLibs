local gsoMenu = nil
local gsoDrawSelMenu = nil
local gsoDrawLHMenu = nil
local gsoDrawALHMenu = nil
local gsoSelectedTarget = nil
local gsoLastSelTick = 0
local gsoLastHeroTarget = nil
local gsoLastMinionLastHit = nil
local gsoFarmMinions = {}
local gsoPriorities = {
        ["Aatrox"] = 3, ["Ahri"] = 2, ["Akali"] = 2, ["Alistar"] = 5, ["Amumu"] = 5, ["Anivia"] = 2, ["Annie"] = 2, ["Ashe"] = 1, ["AurelionSol"] = 2, ["Azir"] = 2,
        ["Bard"] = 3, ["Blitzcrank"] = 5, ["Brand"] = 2, ["Braum"] = 5, ["Caitlyn"] = 1, ["Camille"] = 3, ["Cassiopeia"] = 2, ["Chogath"] = 5, ["Corki"] = 1,
        ["Darius"] = 4, ["Diana"] = 2, ["DrMundo"] = 5, ["Draven"] = 1, ["Ekko"] = 2, ["Elise"] = 3, ["Evelynn"] = 2, ["Ezreal"] = 1, ["Fiddlesticks"] = 3, ["Fiora"] = 3,
        ["Fizz"] = 2, ["Galio"] = 5, ["Gangplank"] = 2, ["Garen"] = 5, ["Gnar"] = 5, ["Gragas"] = 4, ["Graves"] = 2, ["Hecarim"] = 4, ["Heimerdinger"] = 3, ["Illaoi"] =  3,
        ["Irelia"] = 3, ["Ivern"] = 5, ["Janna"] = 4, ["JarvanIV"] = 3, ["Jax"] = 3, ["Jayce"] = 2, ["Jhin"] = 1, ["Jinx"] = 1, ["Kalista"] = 1, ["Karma"] = 2, ["Karthus"] = 2,
        ["Kassadin"] = 2, ["Katarina"] = 2, ["Kayle"] = 2, ["Kayn"] = 2, ["Kennen"] = 2, ["Khazix"] = 2, ["Kindred"] = 2, ["Kled"] = 4, ["KogMaw"] = 1, ["Leblanc"] = 2,
        ["LeeSin"] = 3, ["Leona"] = 5, ["Lissandra"] = 2, ["Lucian"] = 1, ["Lulu"] = 3, ["Lux"] = 2, ["Malphite"] = 5, ["Malzahar"] = 3, ["Maokai"] = 4, ["MasterYi"] = 1,
        ["MissFortune"] = 1, ["MonkeyKing"] = 3, ["Mordekaiser"] = 2, ["Morgana"] = 3, ["Nami"] = 3, ["Nasus"] = 4, ["Nautilus"] = 5, ["Nidalee"] = 2, ["Nocturne"] = 2,
        ["Nunu"] = 4, ["Olaf"] = 4, ["Orianna"] = 2, ["Ornn"] = 4, ["Pantheon"] = 3, ["Poppy"] = 4, ["Quinn"] = 1, ["Rakan"] = 3, ["Rammus"] = 5, ["RekSai"] = 4,
        ["Renekton"] = 4, ["Rengar"] = 2, ["Riven"] = 2, ["Rumble"] = 2, ["Ryze"] = 2, ["Sejuani"] = 4, ["Shaco"] = 2, ["Shen"] = 5, ["Shyvana"] = 4, ["Singed"] = 5,
        ["Sion"] = 5, ["Sivir"] = 1, ["Skarner"] = 4, ["Sona"] = 3, ["Soraka"] = 3, ["Swain"] = 3, ["Syndra"] = 2, ["TahmKench"] = 5, ["Taliyah"] = 2, ["Talon"] = 2,
        ["Taric"] = 5, ["Teemo"] = 2, ["Thresh"] = 5, ["Tristana"] = 1, ["Trundle"] = 4, ["Tryndamere"] = 2, ["TwistedFate"] = 2, ["Twitch"] = 1, ["Udyr"] = 4, ["Urgot"] = 4,
        ["Varus"] = 1, ["Vayne"] = 1, ["Veigar"] = 2, ["Velkoz"] = 2, ["Vi"] = 4, ["Viktor"] = 2, ["Vladimir"] = 3, ["Volibear"] = 4, ["Warwick"] = 4, ["Xayah"] = 1,
        ["Xerath"] = 2, ["XinZhao"] = 3, ["Yasuo"] = 2, ["Yorick"] = 4, ["Zac"] = 5, ["Zed"] = 2, ["Ziggs"] = 2, ["Zilean"] = 3, ["Zoe"] = 2, ["Zyra"] = 2
}
local gsoPriorityMultiplier = {
        [1] = 1,
        [2] = 1.15,
        [3] = 1.3,
        [4] = 1.45,
        [5] = 1.6,
        [6] = 1.75
}

local function gsoCreatePriorityMenu(charName)
        local priority = gsoPriorities[charName] ~= nil and gsoPriorities[charName] or 5
        gsoMenu.priority:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
end

class "__gsoTS"
        
        function __gsoTS:GetSelectedTarget()
                return gsoSelectedTarget
        end
        
        function __gsoTS:CreateMenu(menu)
                self.mainMenu = menu
                gsoMenu = menu:MenuElement({name = "Target Selector", id = "ts", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ts.png" })
                        gsoMenu:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = { "Auto", "Closest", "Least Health", "Least Priority" } })
                        gsoMenu:MenuElement({ id = "priority", name = "Priorities", type = MENU })
                                _G.gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) gsoCreatePriorityMenu(hero.charName) end)
                        gsoMenu:MenuElement({ id = "selected", name = "Selected Target", type = MENU })
                                gsoMenu.selected:MenuElement({ id = "enable", name = "Enable", value = true })
                        gsoMenu:MenuElement({name = "LastHit Mode", id = "lasthitmode", value = 1, drop = { "Accuracy", "Fast" } })
                        gsoMenu:MenuElement({name = "LaneClear Should Wait Time", id = "shouldwaittime", value = 200, min = 0, max = 1000, step = 50, tooltip = "Less Value = Faster LaneClear" })
                        gsoMenu:MenuElement({name = "LaneClear Harass", id = "laneset", value = true })
        end
        
        function __gsoTS:CreateDrawMenu(menu)
                gsoDrawSelMenu = menu:MenuElement({name = "Selected Target",  id = "selected", type = MENU})
                        gsoDrawSelMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
                        gsoDrawSelMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(255, 204, 0, 0)})
                        gsoDrawSelMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                        gsoDrawSelMenu:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
                gsoDrawLHMenu = menu:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = MENU})
                        gsoDrawLHMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
                        gsoDrawLHMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 255, 255, 255)})
                        gsoDrawLHMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                        gsoDrawLHMenu:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
                gsoDrawALHMenu = menu:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = MENU})
                        gsoDrawALHMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
                        gsoDrawALHMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 239, 159, 55)})
                        gsoDrawALHMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                        gsoDrawALHMenu:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
        end
        
        function __gsoTS:GetTarget(enemyHeroes, dmgAP)
                local selectedID
                if gsoMenu.selected.enable:Value() and gsoSelectedTarget then
                        selectedID = gsoSelectedTarget.networkID
                end
                local result = nil
                local num = 10000000
                local mode = gsoMenu.Mode:Value()
                for i = 1, #enemyHeroes do
                        local x
                        local unit = enemyHeroes[i]
                        if selectedID and unit.networkID == selectedID then
                                return gsoSelectedTarget
                        elseif mode == 1 then
                                local unitName = unit.charName
                                local multiplier = gsoPriorityMultiplier[gsoMenu.priority[unitName] and gsoMenu.priority[unitName]:Value() or 6]
                                local def = dmgAP and multiplier * (unit.magicResist - myHero.magicPen) or multiplier * (unit.armor - myHero.armorPen)
                                if def > 0 then
                                        def = dmgAP and myHero.magicPenPercent * def or myHero.bonusArmorPenPercent * def
                                end
                                x = ( ( unit.health * multiplier * ( ( 100 + def ) / 100 ) ) - ( unit.totalDamage * unit.attackSpeed * 2 ) ) - unit.ap
                        elseif mode == 2 then
                                x = unit.pos:DistanceTo(myHero.pos)
                        elseif mode == 3 then
                                x = unit.health
                        elseif mode == 4 then
                                local unitName = unit.charName
                                x = gsoMenu.priority[unitName] and gsoMenu.priority[unitName]:Value() or 6
                        end
                        if x < num then
                                num = x
                                result = unit
                        end
                end
                return result
        end
        
        function __gsoTS:GetLastHeroTarget()
                return gsoLastHeroTarget
        end
        
        function __gsoTS:GetLastMinionLastHit()
                return gsoLastMinionLastHit
        end
        
        function __gsoTS:GetFarmMinions()
                return gsoFarmMinions
        end
        
        function __gsoTS:GetComboTarget()
                local comboT = self:GetTarget(_G.gsoSDK.ObjectManager:GetEnemyHeroes(myHero.range+myHero.boundingRadius - 35, true, "attack"), false)
                if comboT ~= nil then
                        gsoLastHeroTarget = comboT
                end
                return comboT
        end
        
        function __gsoTS:GetLastHitTarget()
                local min = 10000000
                local result = nil
                for i = 1, #gsoFarmMinions do
                        local enemyMinion = gsoFarmMinions[i]
                        if enemyMinion.LastHitable and enemyMinion.PredictedHP < min then
                                min = enemyMinion.PredictedHP
                                result = enemyMinion.Minion
                        end
                end
                if result ~= nil then
                        gsoLastMinionLastHit = result
                end
                return result
        end
        
        function __gsoTS:GetLaneClearTarget()
                local enemyTurrets = _G.gsoSDK.ObjectManager:GetEnemyTurrets(myHero.range+myHero.boundingRadius - 35, true)
                for i = 1, #enemyTurrets do
                        return enemyTurrets[i]
                end
                if gsoMenu.laneset:Value() then
                        local result = self:GetComboTarget()
                        if result then return result end
                end
                local result = nil
                if _G.gsoSDK.Farm:CanLaneClearTime() then
                        local min = 10000000
                        for i = 1, #gsoFarmMinions do
                                local enemyMinion = gsoFarmMinions[i]
                                if enemyMinion.PredictedHP < min then
                                        min = enemyMinion.PredictedHP
                                        result = enemyMinion.Minion
                                end
                        end
                end
                return result
        end
        
        function __gsoTS:Tick()
                if not self.mainMenu.orb.enabledorb:Value() then return end
                local enemyMinions = _G.gsoSDK.ObjectManager:GetEnemyMinions(myHero.range + myHero.boundingRadius - 35, true)
                local allyMinions = _G.gsoSDK.ObjectManager:GetAllyMinions(1500, false)
                local lastHitMode = gsoMenu.lasthitmode:Value() == 1 and "accuracy" or "fast"
                local cacheFarmMinions = {}
                for i = 1, #enemyMinions do
                        local enemyMinion = enemyMinions[i]
                        local FlyTime = myHero.attackData.windUpTime + ( myHero.pos:DistanceTo(enemyMinion.pos) / myHero.attackData.projectileSpeed )
                        cacheFarmMinions[#cacheFarmMinions+1] = _G.gsoSDK.Farm:SetLastHitable(enemyMinion, FlyTime, myHero.totalDamage, lastHitMode, allyMinions)
                end
                gsoFarmMinions = cacheFarmMinions
        end
        
        function __gsoTS:WndMsg(msg, wParam)
                if msg == WM_LBUTTONDOWN and gsoMenu.selected.enable:Value() and GetTickCount() > gsoLastSelTick + 100 then
                        gsoSelectedTarget = nil
                        local num = 10000000
                        local enemyList = _G.gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                        for i = 1, #enemyList do
                                local unit = enemyList[i]
                                local distance = mousePos:DistanceTo(unit.pos)
                                if distance < 150 and distance < num then
                                        gsoSelectedTarget = unit
                                        num = distance
                                end
                        end
                        gsoLastSelTick = GetTickCount()
                end
        end
        
        function __gsoTS:Draw()
                if gsoDrawSelMenu.enabled:Value() then
                        if gsoSelectedTarget and not gsoSelectedTarget.dead and gsoSelectedTarget.isTargetable and gsoSelectedTarget.visible and gsoSelectedTarget.valid then
                                Draw.Circle(gsoSelectedTarget.pos, gsoDrawSelMenu.radius:Value(), gsoDrawSelMenu.width:Value(), gsoDrawSelMenu.color:Value())
                        end
                end
                if not self.mainMenu.orb.enabledorb:Value() then return end
                if gsoDrawLHMenu.enabled:Value() or gsoDrawALHMenu.enabled:Value() then
                        for i = 1, #gsoFarmMinions do
                                local minion = gsoFarmMinions[i]
                                if minion.LastHitable and gsoDrawLHMenu.enabled:Value() then
                                        Draw.Circle(minion.Minion.pos, gsoDrawLHMenu.radius:Value(), gsoDrawLHMenu.width:Value(), gsoDrawLHMenu.color:Value())
                                elseif minion.AlmostLastHitable and gsoDrawALHMenu.enabled:Value() then
                                        Draw.Circle(minion.Minion.pos, gsoDrawALHMenu.radius:Value(), gsoDrawALHMenu.width:Value(), gsoDrawALHMenu.color:Value())
                                end
                        end
                end
        end