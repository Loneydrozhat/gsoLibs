local gsoLastFound = -99999
local gsoLoadedChamps = false
local gsoAllyHeroes = {}
local gsoEnemyHeroes = {}
local gsoAllyHeroLoad = {}
local gsoEnemyHeroLoad = {}
local gsoUndyingBuffs = { ["zhonyasringshield"] = true }

class "__gsoOB"
        
        function __gsoOB:OnAllyHeroLoad(func)
                gsoAllyHeroLoad[#gsoAllyHeroLoad+1] = func
        end
        
        function __gsoOB:OnEnemyHeroLoad(func)
                gsoEnemyHeroLoad[#gsoEnemyHeroLoad+1] = func
        end
        
        function __gsoOB:IsUnitValid(unit, range, bb)
                local extraRange = bb and unit.boundingRadius or 0
                if  unit.pos:DistanceTo(myHero.pos) < range + extraRange and not unit.dead and unit.isTargetable and unit.valid and unit.visible then
                        return true
                end
                return false
        end
        
        function __gsoOB:IsUnitValid_invisible(unit, range, bb)
                local extraRange = bb and unit.boundingRadius or 0
                if  unit.pos:DistanceTo(myHero.pos) < range + extraRange and not unit.dead and unit.isTargetable and unit.valid then
                        return true
                end
                return false
        end
        
        function __gsoOB:IsHeroImmortal(unit, jaxE)
                local hp = 100 * ( unit.health / unit.maxHealth )
                if gsoUndyingBuffs["JaxCounterStrike"] ~= nil then gsoUndyingBuffs["JaxCounterStrike"] = jaxE end
                if gsoUndyingBuffs["kindredrnodeathbuff"] ~= nil then gsoUndyingBuffs["kindredrnodeathbuff"] = hp < 10 end
                if gsoUndyingBuffs["UndyingRage"] ~= nil then gsoUndyingBuffs["UndyingRage"] = hp < 15 end
                if gsoUndyingBuffs["ChronoShift"] ~= nil then gsoUndyingBuffs["ChronoShift"] = hp < 15; gsoUndyingBuffs["chronorevive"] = hp < 15 end
                for i = 0, unit.buffCount do
                        local buff = unit:GetBuff(i)
                        if buff and buff.count > 0 and gsoUndyingBuffs[buff.name] then
                                return true
                        end
                end
                return false
        end
        
        function __gsoOB:GetAllyHeroes(range, bb)
                local result = {}
                for i = 1, Game.HeroCount() do
                        local hero = Game.Hero(i)
                        if hero and hero.team == myHero.team and self:IsUnitValid(hero, range, bb) then
                                result[#result+1] = hero
                        end
                end
                return result
        end
        
        function __gsoOB:GetEnemyHeroes(range, bb, state)
                local result = {}
                if state == "spell" then
                        for i = 1, Game.HeroCount() do
                                local hero = Game.Hero(i)
                                if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) and not self:IsHeroImmortal(hero, false) then
                                        result[#result+1] = hero
                                end
                        end
                elseif state == "attack" then
                        for i = 1, Game.HeroCount() do
                                local hero = Game.Hero(i)
                                if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) and not self:IsHeroImmortal(hero, true) then
                                        result[#result+1] = hero
                                end
                        end
                elseif state == "immortal" then
                        for i = 1, Game.HeroCount() do
                                local hero = Game.Hero(i)
                                if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) then
                                        result[#result+1] = hero
                                end
                        end
                elseif state == "spell_invisible" then
                        for i = 1, Game.HeroCount() do
                                local hero = Game.Hero(i)
                                if hero and hero.team ~= myHero.team and self:IsUnitValid_invisible(hero, range, bb) then
                                        result[#result+1] = hero
                                end
                        end
                end
                return result
        end
        
        function __gsoOB:GetAllyTurrets(range, bb)
                local result = {}
                for i = 1, Game.TurretCount() do
                        local turret = Game.Turret(i)
                        if turret and turret.team == myHero.team and self:IsUnitValid(turret, range, bb)  then
                                result[#result+1] = turret
                        end
                end
                return result
        end
        
        function __gsoOB:GetEnemyTurrets(range, bb)
                local result = {}
                for i = 1, Game.TurretCount() do
                        local turret = Game.Turret(i)
                        if turret and turret.team ~= myHero.team and self:IsUnitValid(turret, range, bb) and not turret.isImmortal then
                                result[#result+1] = turret
                        end
                end
                return result
        end
        
        function __gsoOB:GetAllyMinions(range, bb)
                local result = {}
                for i = 1, Game.MinionCount() do
                        local minion = Game.Minion(i)
                        if minion and minion.team == myHero.team and self:IsUnitValid(minion, range, bb) then
                                result[#result+1] = minion
                        end
                end
                return result
        end
        
        function __gsoOB:GetEnemyMinions(range, bb)
                local result = {}
                for i = 1, Game.MinionCount() do
                        local minion = Game.Minion(i)
                        if minion and minion.team ~= myHero.team and self:IsUnitValid(minion, range, bb) and not minion.isImmortal then
                                result[#result+1] = minion
                        end
                end
                return result
        end
        
        function __gsoOB:Tick()
                for i = 1, Game.HeroCount() do end
                for i = 1, Game.TurretCount() do end
                for i = 1, Game.MinionCount() do end
                if gsoLoadedChamps then return end
                for i = 1, Game.HeroCount() do
                        local hero = Game.Hero(i)
                        local eName = hero.charName
                        if eName and #eName > 0 then
                                local isNewHero = true
                                if hero.team ~= myHero.team then
                                        for j = 1, #gsoEnemyHeroes do
                                                if hero == gsoEnemyHeroes[j] then
                                                        isNewHero = false
                                                        break
                                                end
                                        end
                                        if isNewHero then
                                                gsoEnemyHeroes[#gsoEnemyHeroes+1] = hero
                                                gsoLastFound = Game.Timer()
                                                if eName == "Kayle" then gsoUndyingBuffs["JudicatorIntervention"] = true
                                                elseif eName == "Taric" then gsoUndyingBuffs["TaricR"] = true
                                                elseif eName == "Kindred" then gsoUndyingBuffs["kindredrnodeathbuff"] = true
                                                elseif eName == "Zilean" then gsoUndyingBuffs["ChronoShift"] = true; gsoUndyingBuffs["chronorevive"] = true
                                                elseif eName == "Tryndamere" then gsoUndyingBuffs["UndyingRage"] = true
                                                elseif eName == "Jax" then gsoUndyingBuffs["JaxCounterStrike"] = true; gsoIsJax = true
                                                elseif eName == "Fiora" then gsoUndyingBuffs["FioraW"] = true
                                                elseif eName == "Aatrox" then gsoUndyingBuffs["aatroxpassivedeath"] = true
                                                elseif eName == "Vladimir" then gsoUndyingBuffs["VladimirSanguinePool"] = true
                                                elseif eName == "KogMaw" then gsoUndyingBuffs["KogMawIcathianSurprise"] = true
                                                elseif eName == "Karthus" then gsoUndyingBuffs["KarthusDeathDefiedBuff"] = true
                                                end
                                        end
                                else
                                        for j = 1, #gsoAllyHeroes do
                                                if hero == gsoAllyHeroes[j] then
                                                        isNewHero = false
                                                        break
                                                end
                                        end
                                        if isNewHero then
                                                gsoAllyHeroes[#gsoEnemyHeroes+1] = hero
                                        end
                                end
                        end
                end
                if Game.Timer() > gsoLastFound + 2.5 and Game.Timer() < gsoLastFound + 5 then
                        gsoLoadedChamps = true
                        for i = 1, #gsoAllyHeroes do
                                for j = 1, #gsoAllyHeroLoad do
                                        gsoAllyHeroLoad[j](gsoAllyHeroes[i])
                                end
                        end
                        for i = 1, #gsoEnemyHeroes do
                                for j = 1, #gsoEnemyHeroLoad do
                                        gsoEnemyHeroLoad[j](gsoEnemyHeroes[i])
                                end
                        end
                end
        end