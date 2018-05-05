--[[
▒█▀▀█ █░░█ █▀▀█ █▀▀ █▀▀█ █▀▀█ 
▒█░░░ █░░█ █▄▄▀ ▀▀█ █░░█ █▄▄▀ 
▒█▄▄█ ░▀▀▀ ▀░▀▀ ▀▀▀ ▀▀▀▀ ▀░▀▀ 
]]
class "__gsoCursor"
      function __gsoCursor:__init()
            self.CursorReady = true
            self.ExtraSetCursor = nil
            self.SetCursorPos = nil
            self.DrawMenu = nil
      end
      function __gsoCursor:IsCursorReady()
            return self.CursorReady and not self.SetCursorPos and not self.ExtraSetCursor
      end
      function __gsoCursor:CreateDrawMenu(menu)
            self.DrawMenu = menu:MenuElement({name = "Cursor Pos",  id = "cursor", type = MENU})
                  self.DrawMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  self.DrawMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(255, 153, 0, 76)})
                  self.DrawMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                  self.DrawMenu:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
      end
      function __gsoCursor:SetCursor(cPos, castPos, delay)
            self.ExtraSetCursor = castPos
            self.CursorReady = false
            self.SetCursorPos = { EndTime = Game.Timer() + delay, Action = function() Control.SetCursorPos(cPos.x, cPos.y) end, Active = true }
      end
      function __gsoCursor:Tick()
            if self.SetCursorPos then
                  if self.SetCursorPos.Active and Game.Timer() > self.SetCursorPos.EndTime then
                        self.SetCursorPos.Action()
                        self.SetCursorPos.Active = false
                        self.ExtraSetCursor = nil
                  elseif not self.SetCursorPos.Active and Game.Timer() > self.SetCursorPos.EndTime + 0.025 then
                        self.CursorReady = true
                        self.SetCursorPos = nil
                  end
            end
            if self.ExtraSetCursor then
                  Control.SetCursorPos(self.ExtraSetCursor)
            end
      end
      function __gsoCursor:Draw()
            if self.DrawMenu.enabled:Value() then
                  Draw.Circle(mousePos, self.DrawMenu.radius:Value(), self.DrawMenu.width:Value(), self.DrawMenu.color:Value())
            end
      end
--[[
▒█▀▀▀ █▀▀█ █▀▀█ █▀▄▀█ 
▒█▀▀▀ █▄▄█ █▄▄▀ █░▀░█ 
▒█░░░ ▀░░▀ ▀░▀▀ ▀░░░▀ 
]]
class "__gsoFarm"
      function __gsoFarm:__init()
            self.ActiveAttacks = {}
            self.ShouldWait = false
            self.ShouldWaitTime = 0
            self.IsLastHitable = false
      end
      function __gsoFarm:PredPos(speed, pPos, unit)
            if unit.pathing.hasMovePath then
                  local uPos = unit.pos
                  local ePos = unit.pathing.endPos
                  local distUP = pPos:DistanceTo(uPos)
                  local distEP = pPos:DistanceTo(ePos)
                  local unitMS = unit.ms
                  if distEP > distUP then
                        return uPos:Extended(ePos, 25+(unitMS*(distUP / (speed - unitMS))))
                  else
                        return uPos:Extended(ePos, 25+(unitMS*(distUP / (speed + unitMS))))
                  end
            end
            return unit.pos
      end
      function __gsoFarm:UpdateActiveAttacks()
            for k1, v1 in pairs(self.ActiveAttacks) do
                  local count = 0
                  for k2, v2 in pairs(self.ActiveAttacks[k1]) do
                        count = count + 1
                        if v2.Speed == 0 and (not v2.Ally or v2.Ally.dead) then
                              self.ActiveAttacks[k1] = nil
                              break
                        end
                        if not v2.Canceled then
                              local ranged = v2.Speed > 0
                              if ranged then
                                    self.ActiveAttacks[k1][k2].FlyTime = v2.Ally.pos:DistanceTo(self:PredPos(v2.Speed, v2.Pos, v2.Enemy)) / v2.Speed
                              end
                              local projectileOnEnemy = 0.025 + _G.gsoSDK.Utilities:GetMaxLatency()
                              if Game.Timer() > v2.StartTime + self.ActiveAttacks[k1][k2].FlyTime - projectileOnEnemy or not v2.Enemy or v2.Enemy.dead then
                                    self.ActiveAttacks[k1][k2] = nil
                              elseif ranged then
                                    self.ActiveAttacks[k1][k2].Pos = v2.Ally.pos:Extended(v2.Enemy.pos, ( Game.Timer() - v2.StartTime ) * v2.Speed)
                              end
                        end
                  end
                  if count == 0 then
                        self.ActiveAttacks[k1] = nil
                  end
            end
      end
      function __gsoFarm:SetLastHitable(enemyMinion, time, damage, mode, allyMinions)
            if mode == "fast" then
                  local hpPred = self:MinionHpPredFast(enemyMinion, allyMinions, time)
                  local lastHitable = hpPred - damage < 0
                  if lastHitable then self.IsLastHitable = true end
                  local almostLastHitable = lastHitable and false or self:MinionHpPredFast(enemyMinion, allyMinions, myHero.attackData.animationTime * 3) - damage < 0
                  if almostLastHitable then
                        self.ShouldWait = true
                        self.ShouldWaitTime = Game.Timer()
                  end
                  return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = enemyMinion }
            elseif mode == "accuracy" then
                  local hpPred = self:MinionHpPredAccuracy(enemyMinion, time)
                  local lastHitable = hpPred - damage < 0
                  if lastHitable then self.IsLastHitable = true end
                  local almostLastHitable = lastHitable and false or self:MinionHpPredFast(enemyMinion, allyMinions, myHero.attackData.animationTime * 3) - damage < 0
                  if almostLastHitable then
                        self.ShouldWait = true
                        self.ShouldWaitTime = Game.Timer()
                  end
                  return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = enemyMinion }
            end
      end
      function __gsoFarm:CanLastHit()
            return self.IsLastHitable
      end
      function __gsoFarm:CanLaneClear()
            return not self.ShouldWait
      end
      function __gsoFarm:CanLaneClearTime()
            local shouldWait = _G.gsoSDK.TS.mainMenu.ts.shouldwaittime:Value() * 0.001
            return Game.Timer() > self.ShouldWaitTime + shouldWait
      end
      function __gsoFarm:MinionHpPredFast(unit, allyMinions, time)
            local unitHandle, unitPos, unitHealth = unit.handle, unit.pos, unit.health
            for i = 1, #allyMinions do
                  local allyMinion = allyMinions[i]
                  if allyMinion.attackData.target == unitHandle then
                        local minionDmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-unit.flatDamageReduction
                        local flyTime = allyMinion.attackData.projectileSpeed > 0 and allyMinion.pos:DistanceTo(unitPos) / allyMinion.attackData.projectileSpeed or 0
                        local endTime = (allyMinion.attackData.endTime - allyMinion.attackData.animationTime) + flyTime + allyMinion.attackData.windUpTime
                        endTime = endTime > Game.Timer() and endTime or endTime + allyMinion.attackData.animationTime + flyTime
                        while endTime - Game.Timer() < time do
                              unitHealth = unitHealth - minionDmg
                              endTime = endTime + allyMinion.attackData.animationTime + flyTime
                        end
                  end
            end
            return unitHealth
      end
      function __gsoFarm:MinionHpPredAccuracy(unit, time)
            local unitHealth, unitHandle = unit.health, unit.handle
            for allyID, allyActiveAttacks in pairs(self.ActiveAttacks) do
                  for activeAttackID, activeAttack in pairs(self.ActiveAttacks[allyID]) do
                        if not activeAttack.Canceled and unitHandle == activeAttack.Enemy.handle then
                              local endTime = activeAttack.StartTime + activeAttack.FlyTime
                              if endTime > Game.Timer() and endTime - Game.Timer() < time then
                                    unitHealth = unitHealth - activeAttack.Dmg
                              end
                        end
                  end
            end
            return unitHealth
      end
      function __gsoFarm:Tick(allyMinions, enemyMinions)
            for i = 1, #allyMinions do
                  local allyMinion = allyMinions[i]
                  if allyMinion.attackData.endTime > Game.Timer() then
                        for j = 1, #enemyMinions do
                              local enemyMinion = enemyMinions[j]
                              if enemyMinion.handle == allyMinion.attackData.target then
                                    local flyTime = allyMinion.attackData.projectileSpeed > 0 and allyMinion.pos:DistanceTo(enemyMinion.pos) / allyMinion.attackData.projectileSpeed or 0
                                    if not self.ActiveAttacks[allyMinion.handle] then
                                          self.ActiveAttacks[allyMinion.handle] = {}
                                    end
                                    if Game.Timer() < (allyMinion.attackData.endTime - allyMinion.attackData.windDownTime) + flyTime then
                                          if allyMinion.attackData.projectileSpeed > 0 then
                                                if Game.Timer() > allyMinion.attackData.endTime - allyMinion.attackData.windDownTime then
                                                      if not self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] then
                                                            self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                                  Canceled = false,
                                                                  Speed = allyMinion.attackData.projectileSpeed,
                                                                  StartTime = allyMinion.attackData.endTime - allyMinion.attackData.windDownTime,
                                                                  FlyTime = flyTime,
                                                                  Pos = allyMinion.pos:Extended(enemyMinion.pos, allyMinion.attackData.projectileSpeed * ( Game.Timer() - ( allyMinion.attackData.endTime - allyMinion.attackData.windDownTime ) ) ),
                                                                  Ally = allyMinion,
                                                                  Enemy = enemyMinion,
                                                                  Dmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-enemyMinion.flatDamageReduction
                                                            }
                                                      end
                                                elseif allyMinion.pathing.hasMovePath then
                                                      self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                            Canceled = true,
                                                            Ally = allyMinion
                                                      }
                                                end
                                          elseif not self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] then
                                                self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                      Canceled = false,
                                                      Speed = allyMinion.attackData.projectileSpeed,
                                                      StartTime = (allyMinion.attackData.endTime - allyMinion.attackData.windDownTime) - allyMinion.attackData.windUpTime,
                                                      FlyTime = allyMinion.attackData.windUpTime,
                                                      Pos = allyMinion.pos,
                                                      Ally = allyMinion,
                                                      Enemy = enemyMinion,
                                                      Dmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-enemyMinion.flatDamageReduction
                                                }
                                          end
                                    end
                                    break
                              end
                        end
                  end
            end
            self:UpdateActiveAttacks()
            self.IsLastHitable = false
            self.ShouldWait = false
      end
--[[
▒█▀▀▀█ █▀▀▄ ░░▀ █▀▀ █▀▀ ▀▀█▀▀ 　 ▒█▀▄▀█ █▀▀█ █▀▀▄ █▀▀█ █▀▀▀ █▀▀ █▀▀█ 
▒█░░▒█ █▀▀▄ ░░█ █▀▀ █░░ ░░█░░ 　 ▒█▒█▒█ █▄▄█ █░░█ █▄▄█ █░▀█ █▀▀ █▄▄▀ 
▒█▄▄▄█ ▀▀▀░ █▄█ ▀▀▀ ▀▀▀ ░░▀░░ 　 ▒█░░▒█ ▀░░▀ ▀░░▀ ▀░░▀ ▀▀▀▀ ▀▀▀ ▀░▀▀ 
]]
class "__gsoOB"
      function __gsoOB:__init()
            self.LastFound = -99999
            self.LoadedChamps = false
            self.AllyHeroes = {}
            self.EnemyHeroes = {}
            self.AllyHeroLoad = {}
            self.EnemyHeroLoad = {}
            self.UndyingBuffs = { ["zhonyasringshield"] = true }
      end
      function __gsoOB:OnAllyHeroLoad(func)
            self.AllyHeroLoad[#self.AllyHeroLoad+1] = func
      end
      function __gsoOB:OnEnemyHeroLoad(func)
            self.EnemyHeroLoad[#self.EnemyHeroLoad+1] = func
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
            if self.UndyingBuffs["JaxCounterStrike"] ~= nil then self.UndyingBuffs["JaxCounterStrike"] = jaxE end
            if self.UndyingBuffs["kindredrnodeathbuff"] ~= nil then self.UndyingBuffs["kindredrnodeathbuff"] = hp < 10 end
            if self.UndyingBuffs["UndyingRage"] ~= nil then self.UndyingBuffs["UndyingRage"] = hp < 15 end
            if self.UndyingBuffs["ChronoShift"] ~= nil then self.UndyingBuffs["ChronoShift"] = hp < 15; self.UndyingBuffs["chronorevive"] = hp < 15 end
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and self.UndyingBuffs[buff.name] then
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
            if self.LoadedChamps then return end
            for i = 1, Game.HeroCount() do
                  local hero = Game.Hero(i)
                  local eName = hero.charName
                  if eName and #eName > 0 then
                        local isNewHero = true
                        if hero.team ~= myHero.team then
                              for j = 1, #self.EnemyHeroes do
                                    if hero == self.EnemyHeroes[j] then
                                          isNewHero = false
                                          break
                                    end
                              end
                              if isNewHero then
                                    self.EnemyHeroes[#self.EnemyHeroes+1] = hero
                                    self.LastFound = Game.Timer()
                                    if eName == "Kayle" then self.UndyingBuffs["JudicatorIntervention"] = true
                                    elseif eName == "Taric" then self.UndyingBuffs["TaricR"] = true
                                    elseif eName == "Kindred" then self.UndyingBuffs["kindredrnodeathbuff"] = true
                                    elseif eName == "Zilean" then self.UndyingBuffs["ChronoShift"] = true; self.UndyingBuffs["chronorevive"] = true
                                    elseif eName == "Tryndamere" then self.UndyingBuffs["UndyingRage"] = true
                                    elseif eName == "Jax" then self.UndyingBuffs["JaxCounterStrike"] = true; gsoIsJax = true
                                    elseif eName == "Fiora" then self.UndyingBuffs["FioraW"] = true
                                    elseif eName == "Aatrox" then self.UndyingBuffs["aatroxpassivedeath"] = true
                                    elseif eName == "Vladimir" then self.UndyingBuffs["VladimirSanguinePool"] = true
                                    elseif eName == "KogMaw" then self.UndyingBuffs["KogMawIcathianSurprise"] = true
                                    elseif eName == "Karthus" then self.UndyingBuffs["KarthusDeathDefiedBuff"] = true
                                    end
                              end
                        else
                              for j = 1, #self.AllyHeroes do
                                    if hero == self.AllyHeroes[j] then
                                          isNewHero = false
                                          break
                                    end
                              end
                              if isNewHero then
                                    self.AllyHeroes[#self.EnemyHeroes+1] = hero
                              end
                        end
                  end
            end
            if Game.Timer() > self.LastFound + 2.5 and Game.Timer() < self.LastFound + 5 then
                  self.LoadedChamps = true
                  for i = 1, #self.AllyHeroes do
                        for j = 1, #self.AllyHeroLoad do
                              self.AllyHeroLoad[j](self.AllyHeroes[i])
                        end
                  end
                  for i = 1, #self.EnemyHeroes do
                        for j = 1, #self.EnemyHeroLoad do
                              self.EnemyHeroLoad[j](self.EnemyHeroes[i])
                        end
                  end
            end
      end
--[[
▒█▀▀▀█ █▀▀█ █▀▀▄ █░░░█ █▀▀█ █░░ █░█ █▀▀ █▀▀█ 
▒█░░▒█ █▄▄▀ █▀▀▄ █▄█▄█ █▄▄█ █░░ █▀▄ █▀▀ █▄▄▀ 
▒█▄▄▄█ ▀░▀▀ ▀▀▀░ ░▀░▀░ ▀░░▀ ▀▀▀ ▀░▀ ▀▀▀ ▀░▀▀ 
]]
class "__gsoOrbwalker"
      function __gsoOrbwalker:__init()
            self.LoadTime = Game.Timer()
            self.IsTeemo = false
            self.IsBlindedByTeemo = false
            self.LastAttackLocal = 0
            self.LastAttackServer = 0
            self.LastMoveLocal = 0
            self.MainMenu = nil
            self.Menu = nil
            self.DrawMenuMe = nil
            self.DrawMenuHe = nil
            self.LastMouseDown = 0
            self.LastMovePos = myHero.pos
            self.ResetAttack = false
            self.LastTarget = nil
            self.TestCount = 0
            self.TestStartTime = 0
            self.LastAttackDiff = 0
            self.BaseAASpeed = 1 / myHero.attackData.animationTime / myHero.attackSpeed
            self.BaseWindUp = myHero.attackData.windUpTime / myHero.attackData.animationTime
            self.AttackEndTime = myHero.attackData.endTime + 0.1
            self.WindUpTime = myHero.attackData.windUpTime
            self.AnimTime = myHero.attackData.animationTime
            self.UOLoaded = { Ic = false, Gamsteron = false, Gos = false }
            self.OnPreAttackC = {}
            self.OnPostAttackC = {}
            self.OnAttackC = {}
            self.OnPreMoveC = {}
            self.PostAttackBool = false
            self.AttackEnabled = true
            self.MovementEnabled = true
            self.Loaded = false
            self.SpellMoveDelays = { q = 0, w = 0, e = 0, r = 0 }
            self.SpellAttackDelays = { q = 0, w = 0, e = 0, r = 0 }
            _G.gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) if hero.charName == "Teemo" then self.IsTeemo = true end end)
      end
      function __gsoOrbwalker:GetAttackSpeed()
            return myHero.attackSpeed
      end
      function __gsoOrbwalker:GetAvgLatency()
            local currentLatency = Game.Latency() * 0.001
            local latency = _G.gsoSDK.Utilities:GetMinLatency() + _G.gsoSDK.Utilities:GetMaxLatency() + currentLatency
            return latency / 3
      end
      function __gsoOrbwalker:SetAttackTimers()
            self.BaseAASpeed = 1 / myHero.attackData.animationTime / myHero.attackSpeed
            self.BaseWindUp = myHero.attackData.windUpTime / myHero.attackData.animationTime
            local aaSpeed = self:GetAttackSpeed() * self.BaseAASpeed
            local animT = 1 / aaSpeed
            local windUpT = animT * self.BaseWindUp
            self.AnimTime = animT > myHero.attackData.animationTime and animT or myHero.attackData.animationTime
            self.WindUpTime = windUpT > myHero.attackData.windUpTime and windUpT or myHero.attackData.windUpTime
      end
      function __gsoOrbwalker:CheckTeemoBlind()
            for i = 0, myHero.buffCount do
                  local buff = myHero:GetBuff(i)
                  if buff and buff.count > 0 and buff.name:lower() == "blindingdart" and buff.duration > 0 then
                        return true
                  end
            end
            return false
      end
      function __gsoOrbwalker:CanAttack()
            return true
      end
      function __gsoOrbwalker:CanMove()
            return true
      end
      function __gsoOrbwalker:SetSpellMoveDelays(delays)
            self.SpellMoveDelays = delays
      end
      function __gsoOrbwalker:SetSpellAttackDelays(delays)
            self.SpellAttackDelays = delays
      end
      function __gsoOrbwalker:GetLastMovePos()
            return self.LastMovePos
      end
      function __gsoOrbwalker:ResetMove()
            self.LastMoveLocal = 0
      end
      function __gsoOrbwalker:ResetAttack()
            self.ResetAttack = true
      end
      function __gsoOrbwalker:GetLastTarget()
            return self.LastTarget
      end
      function __gsoOrbwalker:CreateMenu(menu, uolMenu)
            self.MainMenu = uolMenu
            self.Menu = menu:MenuElement({name = "Orbwalker", id = "orb", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/orb.png" })
            self.Menu:MenuElement({name = "Enabled",  id = "enabledorb", tooltip = "Enabled Gamsteron's OnTick and OnDraw - Attack, Move, Draw Attack Range etc.", value = true})
            self.Menu:MenuElement({name = "Keys", id = "keys", type = MENU})
            self.Menu.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
            self.Menu.keys:MenuElement({name = "Harass Key", id = "harass", key = string.byte("C")})
            self.Menu.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
            self.Menu.keys:MenuElement({name = "LaneClear Key", id = "laneclear", key = string.byte("V")})
            self.Menu.keys:MenuElement({name = "Flee Key", id = "flee", key = string.byte("A")})
            self.Menu:MenuElement({name = "Extra WindUp Delay", tooltip = "Less Value = Better KITE", id = "windupdelay", value = 25, min = 0, max = 150, step = 10 })
            self.Menu:MenuElement({name = "Extra Anim Delay", tooltip = "Less Value = Better DPS [ for me 80 is ideal ] - lower value than 80 cause slow KITE ! Maybe for your PC ideal value is 0 ? You need test it in debug mode.", id = "animdelay", value = 80, min = 0, max = 150, step = 10 })
            self.Menu:MenuElement({name = "Extra LastHit Delay", tooltip = "Less Value = Faster Last Hit Reaction", id = "lhDelay", value = 0, min = 0, max = 50, step = 1 })
            self.Menu:MenuElement({name = "Extra Move Delay", tooltip = "Less Value = More Movement Clicks Per Sec", id = "humanizer", value = 200, min = 120, max = 300, step = 10 })
            self.Menu:MenuElement({name = "Debug Mode", tooltip = "Will Print Some Data", id = "enabled", value = false})
      end
      function __gsoOrbwalker:EnableGamsteronOrb()
            if not self.Menu.enabledorb:Value() then self.Menu.enabledorb:Value(true) end
            self.Menu:Hide(false)
            self.UOLoaded.Gamsteron = true
            self.DrawMenuMe:Hide(false)
            self.DrawMenuHe:Hide(false)
            _G.gsoSDK.TS.mainMenu.gsodraw.lasthit:Hide(false)
            _G.gsoSDK.TS.mainMenu.gsodraw.almostlasthit:Hide(false)
      end
      function __gsoOrbwalker:DisableGamsteronOrb()
            if self.Menu.enabledorb:Value() then self.Menu.enabledorb:Value(false) end
            self.Menu:Hide(true)
            self.UOLoaded.Gamsteron = false
            self.DrawMenuMe:Hide(true)
            self.DrawMenuHe:Hide(true)
            _G.gsoSDK.TS.mainMenu.gsodraw.lasthit:Hide(true)
            _G.gsoSDK.TS.mainMenu.gsodraw.almostlasthit:Hide(true)
      end
      function __gsoOrbwalker:EnableGosOrb()
            if not _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(true) end
            _G.Orbwalker:Hide(false)
            self.UOLoaded.Gos = true
      end
      function __gsoOrbwalker:DisableGosOrb()
            if _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(false) end
            _G.Orbwalker:Hide(true)
            self.UOLoaded.Gos = false
      end
      function __gsoOrbwalker:EnableIcOrb()
            if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.Loaded then
                  if not _G.SDK.Orbwalker.Menu.Enabled:Value() then _G.SDK.Orbwalker.Menu.Enabled:Value(true) end
                  _G.SDK.Orbwalker.Menu:Hide(false)
                  self.UOLoaded.Ic = true
            end
      end
      function __gsoOrbwalker:DisableIcOrb()
            if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.Loaded then
                  if _G.SDK.Orbwalker.Menu.Enabled:Value() then _G.SDK.Orbwalker.Menu.Enabled:Value(false) end
                  _G.SDK.Orbwalker.Menu:Hide(true)
                  self.UOLoaded.Ic = false
            end
      end
      ------------------------------------------------------------------------ UOL START
      function __gsoOrbwalker:UOL()
            if not self.Loaded and Game.Timer() > self.LoadTime + 2.5 then
                  self.Loaded = true
            end
            if not self.Loaded then return end
            if self.MainMenu.orbsel:Value() == 1 then
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
                  if self.MainMenu.orbsel:Value() == 2 then
                        self:DisableIcOrb()
                        self:EnableGosOrb()
                        self:DisableGamsteronOrb()
                  elseif self.MainMenu.orbsel:Value() == 3 then
                        if not _G.SDK or not _G.SDK.Orbwalker then
                              print("To use IC's Orbwalker you need load it !")
                              self.MainMenu.orbsel:Value(1)
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
            self.ResetAttack = true
            GOS.AA.state = 1
            GOS.castAttack.state = 0
            GOS.castAttack.casting = GetTickCount() - 1000
      end
      function __gsoOrbwalker:UOL_SetMovement(boolean)
            if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:SetMovement(boolean) end
            self.MovementEnabled = boolean
            GOS.BlockMovement = not boolean
      end
      function __gsoOrbwalker:UOL_SetAttack(boolean)
            if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:SetAttack(boolean) end
            self.AttackEnabled = boolean
            GOS.BlockAttack = not boolean
      end
      function __gsoOrbwalker:UOL_OnPreAttack(func)
            _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPreAttack(func) end end, 2)
            self.OnPreAttackC[#self.OnPreAttackC+1] = func
      end
      function __gsoOrbwalker:UOL_OnPostAttack(func)
            _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPostAttack(func) end end, 2)
            self.OnPostAttackC[#self.OnPostAttackC+1] = func
            GOS:OnAttackComplete(func)
      end
      function __gsoOrbwalker:UOL_OnAttack(func)
            _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnAttack(func) end end, 2)
            self.OnAttackC[#self.OnAttackC+1] = func
            GOS:OnAttack(func)
      end
      function __gsoOrbwalker:UOL_OnPreMovement(func)
            _G.gsoSDK.Utilities:AddAction(function() if _G.SDK and _G.SDK.Orbwalker then _G.SDK.Orbwalker:OnPreMovement(func) end end, 2)
            self.OnPreMoveC[#self.OnPreMoveC+1] = func
      end
      function __gsoOrbwalker:UOL_CanMove()
            if self.MainMenu.orbsel:Value() == 1 then
                  return self:CanMove()
            elseif self.MainMenu.orbsel:Value() == 2 then
                  return GOS:CanMove()
            elseif self.MainMenu.orbsel:Value() == 3 then
                  return _G.SDK.Orbwalker:CanMove(myHero)
            end
      end
      function __gsoOrbwalker:UOL_CanAttack()
            if self.MainMenu.orbsel:Value() == 1 then
                  return self:CanAttack()
            elseif self.MainMenu.orbsel:Value() == 2 then
                  return GOS:CanAttack()
            elseif self.MainMenu.orbsel:Value() == 3 then
                  return _G.SDK.Orbwalker:CanAttack(myHero)
            end
      end
      function __gsoOrbwalker:UOL_IsAttacking()
            if self.MainMenu.orbsel:Value() == 1 then
                  return not self:CanMove()
            elseif self.MainMenu.orbsel:Value() == 2 then
                  return GOS:IsAttacking()
            elseif self.MainMenu.orbsel:Value() == 3 then
                  return _G.SDK.Orbwalker:IsAutoAttacking(myHero)
            end
      end
      function __gsoOrbwalker:UOL_GetMode()
            if self.MainMenu.orbsel:Value() == 1 then
                  if self.Menu.keys.combo:Value() then
                        return "Combo"
                  elseif self.Menu.keys.harass:Value() then
                        return "Harass"
                  elseif self.Menu.keys.lasthit:Value() then
                        return "Lasthit"
                  elseif self.Menu.keys.laneclear:Value() then
                        return "Clear"
                  elseif self.Menu.keys.flee:Value() then
                        return "Flee"
                  else
                        return ""
                  end
            elseif self.MainMenu.orbsel:Value() == 2 then
                  return GOS:GetMode()
            elseif self.MainMenu.orbsel:Value() == 3 then
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
            return self.UOLoaded.Ic
      end
      function __gsoOrbwalker:UOL_LoadedGos()
            return self.UOLoaded.Gos
      end
      function __gsoOrbwalker:UOL_LoadedGamsteron()
            return self.UOLoaded.Gamsteron
      end
      ------------------------------------------------------------------------ UOL END
      function __gsoOrbwalker:CreateDrawMenu(menu)
            self.DrawMenuMe = menu:MenuElement({name = "MyHero Attack Range", id = "me", type = MENU})
            self.DrawMenuMe:MenuElement({name = "Enabled",  id = "enabled", value = true})
            self.DrawMenuMe:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 49, 210, 0)})
            self.DrawMenuMe:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
            self.DrawMenuHe = menu:MenuElement({name = "Enemy Attack Range", id = "he", type = MENU})
            self.DrawMenuHe:MenuElement({name = "Enabled",  id = "enabled", value = true})
            self.DrawMenuHe:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 255, 0, 0)})
            self.DrawMenuHe:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
      end
      function __gsoOrbwalker:WndMsg(msg, wParam)
            if wParam == HK_TCO then
                  self.LastAttackLocal = Game.Timer()
            end
      end
      function __gsoOrbwalker:Draw()
            if not self.Menu.enabledorb:Value() then return end
            if self.DrawMenuMe.enabled:Value() and myHero.pos:ToScreen().onScreen then
                  Draw.Circle(myHero.pos, myHero.range + myHero.boundingRadius + 35, self.DrawMenuMe.width:Value(), self.DrawMenuMe.color:Value())
            end
            if self.DrawMenuHe.enabled:Value() then
                  local enemyHeroes = _G.gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                  for i = 1, #enemyHeroes do
                        local enemy = enemyHeroes[i]
                        if enemy.pos:ToScreen().onScreen then
                              Draw.Circle(enemy.pos, enemy.range + enemy.boundingRadius + 35, self.DrawMenuHe.width:Value(), self.DrawMenuHe.color:Value())
                        end
                  end
            end
      end
      function __gsoOrbwalker:CanAttackEvent(func)
            self:CanAttack = func
      end
      function __gsoOrbwalker:CanMoveEvent(func)
            self:CanMove = func
      end
      function __gsoOrbwalker:Attack(unit)
            self.ResetAttack = false
            _G.gsoSDK.Cursor:SetCursor(cursorPos, unit.pos, 0.06)
            Control.SetCursorPos(unit.pos)
            Control.KeyDown(HK_TCO)
            Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
            Control.mouse_event(MOUSEEVENTF_RIGHTUP)
            Control.KeyUp(HK_TCO)
            self.LastMoveLocal = 0
            self.LastAttackLocal  = Game.Timer()
            self.LastTarget = unit
      end
      function __gsoOrbwalker:Move()
            if Control.IsKeyDown(2) then self.LastMouseDown = Game.Timer() end
            self.LastMovePos = mousePos
            Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
            Control.mouse_event(MOUSEEVENTF_RIGHTUP)
            self.LastMoveLocal = Game.Timer() + self.Menu.humanizer:Value() * 0.001
      end
      function __gsoOrbwalker:MoveToPos(pos)
            if Control.IsKeyDown(2) then self.LastMouseDown = Game.Timer() end
            _G.gsoSDK.Cursor:SetCursor(cursorPos, pos, 0.06)
            Control.SetCursorPos(pos)
            Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
            Control.mouse_event(MOUSEEVENTF_RIGHTUP)
            self.LastMoveLocal = Game.Timer() + self.Menu.humanizer:Value() * 0.001
      end
      function __gsoOrbwalker:CanAttack()
            if not self:CanAttack() then return false end
            if not _G.gsoSDK.Spell:CheckSpellDelays(self.SpellAttackDelays) then return false end
            if self.IsBlindedByTeemo then
                  return false
            end
            if self.ResetAttack then
                  return true
            end
            local animDelay = self.Menu.animdelay:Value() * 0.001
            if Game.Timer() < self.LastAttackLocal + self.AnimTime + self.LastAttackDiff + animDelay - 0.15 - self:GetAvgLatency() then
                  return false
            end
            return true
      end
      function __gsoOrbwalker:CanMove()
            if not self:CanMove() then return false end
            if not _G.gsoSDK.Spell:CheckSpellDelays(self.SpellMoveDelays) then return false end
            local latency = math.min(_G.gsoSDK.Utilities:GetMinLatency(), Game.Latency() * 0.001) * 0.75
            latency = math.min(latency, _G.gsoSDK.Utilities:GetUserLatency())
            local windUpDelay = self.Menu.windupdelay:Value() * 0.001
            if Game.Timer() < self.LastAttackLocal + self.WindUpTime + self.LastAttackDiff - latency - 0.025 + windUpDelay then
                  return false
            end
            if self.LastAttackLocal > self.LastAttackServer and Game.Timer() < self.LastAttackLocal + self.WindUpTime + self.LastAttackDiff - latency + 0.025 + windUpDelay then return false end
            return true
      end
      function __gsoOrbwalker:AttackMove(unit)
            self.LastTarget = nil
            if self.AttackEnabled and unit and unit.pos:ToScreen().onScreen and self:CanAttack() then
                  local args = { Target = unit, Process = true }
                  for i = 1, #self.OnPreAttackC do
                        self.OnPreAttackC[i](args)
                  end
                  if args.Process and args.Target and not args.Target.dead and args.Target.isTargetable and args.Target.valid then
                        self:Attack(args.Target)
                        self.PostAttackBool = true
                  end
            elseif self.MovementEnabled and self:CanMove() then
                  if self.PostAttackBool then
                        for i = 1, #self.OnPostAttackC do
                              self.OnPostAttackC[i]()
                        end
                        self.PostAttackBool = false
                  end
                  if Game.Timer() > self.LastMoveLocal then
                        local args = { Target = nil, Process = true }
                        for i = 1, #self.OnPreMoveC do
                              self.OnPreMoveC[i](args)
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
            if not self.Menu.enabledorb:Value() then return end
            if self.IsTeemo then self.IsBlindedByTeemo = self:CheckTeemoBlind() end
            -- SERVER ATTACK START TIME
            if myHero.attackData.endTime > self.AttackEndTime then
                  for i = 1, #self.OnAttackC do
                        self.OnAttackC[i]()
                  end
                  local serverStart = myHero.attackData.endTime - myHero.attackData.animationTime
                  self.LastAttackDiff = serverStart - self.LastAttackLocal
                  self.LastAttackServer = Game.Timer()
                  self.AttackEndTime = myHero.attackData.endTime
                  if self.Menu.enabled:Value() then
                        if self.TestCount == 0 then
                              self.TestStartTime = Game.Timer()
                        end
                        self.TestCount = self.TestCount + 1
                        if self.TestCount == 5 then
                              print("5 attacks in time: " .. tostring(Game.Timer() - self.TestStartTime) .. "[sec]")
                              self.TestCount = 0
                              self.TestStartTime = 0
                        end
                  end
            end
            -- RESET ATTACK
            if self.LastAttackLocal > self.LastAttackServer and Game.Timer() > self.LastAttackLocal + 0.15 + _G.gsoSDK.Utilities:GetMaxLatency() then
                  if self.Menu.enabled:Value() then
                        print("reset attack1")
                  end
                  self.LastAttackLocal = 0
            elseif self.LastAttackLocal < self.LastAttackServer and Game.Timer() < self.LastAttackLocal + myHero.attackData.windUpTime and myHero.pathing.hasMovePath then
                  if self.Menu.enabled:Value() then
                        print("reset attack2")
                  end
                  self.LastAttackLocal = 0
            end
            -- ATTACK TIMERS
            self:SetAttackTimers()
            -- CHECK IF CAN ORBWALK
            local isEvading = ExtLibEvade and ExtLibEvade.Evading
            if not _G.gsoSDK.Cursor:IsCursorReady() or Game.IsChatOpen() or isEvading then
                  return
            end
            -- ORBWALKER MODE
            if self.Menu.keys.combo:Value() then
                  self:AttackMove(_G.gsoSDK.TS:GetComboTarget())
            elseif self.Menu.keys.harass:Value() then
                  if _G.gsoSDK.Farm:CanLastHit() then
                        self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
                  else
                        self:AttackMove(_G.gsoSDK.TS:GetComboTarget())
                  end
            elseif self.Menu.keys.lasthit:Value() then
                  self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
            elseif self.Menu.keys.laneclear:Value() then
                  if _G.gsoSDK.Farm:CanLastHit() then
                        self:AttackMove(_G.gsoSDK.TS:GetLastHitTarget())
                  elseif _G.gsoSDK.Farm:CanLaneClear() then
                        self:AttackMove(_G.gsoSDK.TS:GetLaneClearTarget())
                  else
                        self:AttackMove()
                  end
            elseif self.Menu.keys.flee:Value() then
                  if self.MovementEnabled and Game.Timer() > self.LastMoveLocal and self:CanMove() then
                        self:Move()
                  end
            elseif Game.Timer() < self.LastMouseDown + 1 then
                  Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
                  self.LastMouseDown = 0
            end
      end
--[[
▒█▀▀█ ▒█▀▀█ ▒█▀▀▀ ▒█▀▀▄ ▀█▀ ▒█▀▀█ ▀▀█▀▀ ▀█▀ ▒█▀▀▀█ ▒█▄░▒█ 
▒█▄▄█ ▒█▄▄▀ ▒█▀▀▀ ▒█░▒█ ▒█░ ▒█░░░ ░▒█░░ ▒█░ ▒█░░▒█ ▒█▒█▒█ 
▒█░░░ ▒█░▒█ ▒█▄▄▄ ▒█▄▄▀ ▄█▄ ▒█▄▄█ ░▒█░░ ▄█▄ ▒█▄▄▄█ ▒█░░▀█ 
]]
class "__gsoPrediction"
      function __gsoPrediction:__init(menu)
            self.Noddy_OnVision = {}
            self.Noddy_Tick = GetTickCount()
            self.Noddy_OnWaypoint = {}
            self.menu = menu
            require "TPred"
            self.hpredloaded = false
            if not _G.gsoTicks.All or not _G.gsoTicks.HPred then self.menu.predsel:Value(2) end
            self.selectedPred = self.menu.predsel:Value()
            if _G.gsoTicks.HPred and _G.gsoTicks.All and self.selectedPred == 3 then require "HPred"; self.hpredloaded = true end
      end
      function __gsoPrediction:Tick()
            if self.hpredloaded and self.selectedPred ~= 1 and self.menu.predsel:Value() == 1 then
                  print("Noddy - Please press 2x F6 to unload HPred - for better performance")
                  self.selectedPred = 1
            elseif self.hpredloaded and self.selectedPred ~= 2 and self.menu.predsel:Value() == 2 then
                  print("Trus - Please press 2x F6 to unload HPred - for better performance")
                  self.selectedPred = 2
            elseif not self.hpredloaded and _G.gsoTicks.HPred and _G.gsoTicks.All and self.selectedPred ~= 3 and self.menu.predsel:Value() == 3 then
                  require "HPred"
                  self.selectedPred = 3
                  print("Sikaka HPred")
                  self.hpredloaded = true
            elseif self.hpredloaded and self.selectedPred ~= 4 and self.menu.predsel:Value() == 4 then
                  print("Gamsteron - Please press 2x F6 to unload HPred - for better performance")
                  self.selectedPred = 4
            elseif self.menu.predsel:Value() == 3 then
                  if not _G.gsoTicks.All or not _G.gsoTicks.HPred then
                        self.menu.predsel:Value(2)
                  end
            end
      end
      function __gsoPrediction:UPL_GetPrediction(unit, delay, radius, range, speed, from, collision, sType)
            if not unit then return -1, nil end
            from = from.x and from or from.pos
            if self.menu.predsel:Value() == 1 then
                  local castpos = self:NoddyGetPred(unit, speed, delay)
                  if not castpos then return -1, nil end
                  if Vector(castpos):DistanceTo(Vector(from)) > range - 35 then return -1, nil end
                  if collision and unit:GetCollision(radius,speed, delay) > 0 then return -1, nil end
                  return 10, castpos
            elseif self.menu.predsel:Value() == 2 then
                  if not TPred then return -1, nil end
                  local CastPosition, HitChance, Position = TPred:GetBestCastPosition(unit, delay, radius, range, speed, from, false, sType)
                  if not CastPosition or HitChance < 1 then return -1, nil end
                  if Vector(CastPosition):DistanceTo(Vector(from)) > range - 35 then return -1, nil end
                  if collision and unit:GetCollision(radius,speed, delay) > 0 then return -1, nil end
                  return HitChance, CastPosition
            elseif self.menu.predsel:Value() == 3 then
                  if not HPred then return -1, nil end
                  local HitChance, CastPosition = HPred:GetHitchance(from, unit, range, delay, speed, radius, collision)
                  if not CastPosition or HitChance < 1 then return -1, nil end
                  if Vector(CastPosition):DistanceTo(Vector(from)) > range - 35 then return -1, nil end
                  if collision and unit:GetCollision(radius,speed, delay) > 0 then return -1, nil end
                  return HitChance, CastPosition
            end
      end
      -- NODDY PRED START
      function __gsoPrediction:NoddyGetDistance(p1,p2)
            return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
      end
      function __gsoPrediction:NoddyIsImmobileTarget(unit)
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
                        return true
                  end
            end
            return false
      end
      function __gsoPrediction:NoddyOnVision(unit)
            if self.Noddy_OnVision[unit.networkID] == nil then self.Noddy_OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
            if self.Noddy_OnVision[unit.networkID].state == true and not unit.visible then self.Noddy_OnVision[unit.networkID].state = false self.Noddy_OnVision[unit.networkID].tick = GetTickCount() end
            if self.Noddy_OnVision[unit.networkID].state == false and unit.visible then self.Noddy_OnVision[unit.networkID].state = true self.Noddy_OnVision[unit.networkID].tick = GetTickCount() end
            return self.Noddy_OnVision[unit.networkID]
      end
      function __gsoPrediction:NoddyOnWaypoint(unit)
            if self.Noddy_OnWaypoint[unit.networkID] == nil then self.Noddy_OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
            if self.Noddy_OnWaypoint[unit.networkID].pos ~= unit.posTo then 
                  self.Noddy_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
                  DelayAction(function()
                        local time = (Game.Timer() - self.Noddy_OnWaypoint[unit.networkID].time)
                        local speed = self:NoddyGetDistance(self.Noddy_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - self.Noddy_OnWaypoint[unit.networkID].time)
                        if speed > 1250 and time > 0 and unit.posTo == self.Noddy_OnWaypoint[unit.networkID].pos and self:NoddyGetDistance(unit.pos,self.Noddy_OnWaypoint[unit.networkID].pos) > 200 then
                              self.Noddy_OnWaypoint[unit.networkID].speed = self:NoddyGetDistance(self.Noddy_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - self.Noddy_OnWaypoint[unit.networkID].time)
                        end
                  end, 0.05)
            end
            return self.Noddy_OnWaypoint[unit.networkID]
      end
      function __gsoPrediction:NoddyTick()
            if not _G.gsoTicks.Noddy or not _G.gsoTicks.All then return end
            if GetTickCount() - self.Noddy_Tick > 100 then
                  for i = 1, Game.HeroCount() do
                        local hero = Game.Hero(i)
                        if hero and hero.team ~= myHero.team then
                              self:NoddyOnVision(hero)
                              self:NoddyOnWaypoint(hero)
                        end
                  end
                  self.Noddy_Tick = GetTickCount()
            end
      end
      function __gsoPrediction:NoddyGetPred(unit,speed,delay)
            speed = speed or math.huge
            delay = delay or 0.25
            local unitSpeed = unit.ms
            if self:NoddyOnWaypoint(unit).speed > unitSpeed then unitSpeed = self:NoddyOnWaypoint(unit).speed end
            if self:NoddyOnVision(unit).state == false then
                  local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - self:NoddyOnVision(unit).tick)/1000 * unitSpeed)
                  local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (self:NoddyGetDistance(myHero.pos,unitPos)/speed)))
                  if self:NoddyGetDistance(unit.pos,predPos) > self:NoddyGetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
                  return predPos
            else
                  if unitSpeed > unit.ms then
                        local predPos = unit.pos + Vector(self:NoddyOnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (self:NoddyGetDistance(myHero.pos,unit.pos)/speed)))
                        if self:NoddyGetDistance(unit.pos,predPos) > self:NoddyGetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
                        return predPos
                  elseif self:NoddyIsImmobileTarget(unit) then
                        return unit.pos
                  else
                        return unit:GetPrediction(speed,delay)
                  end
            end
      end
      -- NODDY PRED END
--[[
▒█▀▀▀█ █▀▀█ █▀▀ █░░ █░░ 
░▀▀▀▄▄ █░░█ █▀▀ █░░ █░░ 
▒█▄▄▄█ █▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ 
]]
class "__gsoSpell"
      function __gsoSpell:__init()
            self.LastQ = 0
            self.LastQk = 0
            self.LastW = 0
            self.LastWk = 0
            self.LastE = 0
            self.LastEk = 0
            self.LastR = 0
            self.LastRk = 0
            self.DelayedSpell = {}
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
                  self.spellDraw = { q = true, qf = function() local qt = Game.Timer() - self.LastQk;if qt > 3 then return 1000 end local qrange = qt * 250;if qrange > 1750 then return 1750 end return qrange end, w = true, wr = 550 + 120, e = true, er = 800 + 120, r = true, rr = 725 }
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
      function __gsoSpell:ReducedDmg(unit, dmg, isAP)
            local def = isAP and unit.magicResist - myHero.magicPen or unit.armor - myHero.armorPen
            if def > 0 then def = isAP and myHero.magicPenPercent * def or myHero.bonusArmorPenPercent * def end
            return def > 0 and dmg * ( 100 / ( 100 + def ) ) or dmg * ( 2 - ( 100 / ( 100 - def ) ) )
      end
      function __gsoSpell:CalculateDmg(unit, spellData)
            local dmgType = spellData.dmgType and spellData.dmgType or ""
            if not unit then assert(false, "[234] CalculateDmg: unit is nil !") end
            if dmgType == "ad" and spellData.dmgAD then
                  local dmgAD = spellData.dmgAD - unit.shieldAD
                  return dmgAD < 0 and 0 or self:ReducedDmg(unit, dmgAD, false) 
            elseif dmgType == "ap" and spellData.dmgAP then
                  local dmgAP = spellData.dmgAP - unit.shieldAD - unit.shieldAP
                  return dmgAP < 0 and 0 or self:ReducedDmg(unit, dmgAP, true) 
            elseif dmgType == "true" and spellData.dmgTrue then
                  return spellData.dmgTrue - unit.shieldAD
            elseif dmgType == "mixed" and spellData.dmgAD and spellData.dmgAP then
                  local dmgAD = spellData.dmgAD - unit.shieldAD
                  local shieldAD = dmgAD < 0 and (-1) * dmgAD or 0
                  dmgAD = dmgAD < 0 and 0 or self:ReducedDmg(unit, dmgAD, false)
                  local dmgAP = spellData.dmgAP - shieldAD - unit.shieldAP
                  dmgAP = dmgAP < 0 and 0 or self:ReducedDmg(unit, dmgAP, true)
                  return dmgAD + dmgAP
            end
            assert(false, "[234] CalculateDmg: spellData - expected array { dmgType = string(ap or ad or mixed or true), dmgAP = number or dmgAD = number or ( dmgAP = number and dmgAD = number ) or dmgTrue = number } !")
      end
      function __gsoSpell:GetLastSpellTimers()
            return self.LastQ, self.LastQk, self.LastW, self.LastWk, self.LastE, self.LastEk, self.LastR, self.LastRk
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
            return self:CalculateDmg(unit, spellData)
      end
      function __gsoSpell:CheckSpellDelays(delays)
            if Game.Timer() < self.LastQ + delays.q or Game.Timer() < self.LastQk + delays.q then return false end
            if Game.Timer() < self.LastW + delays.w or Game.Timer() < self.LastWk + delays.w then return false end
            if Game.Timer() < self.LastE + delays.e or Game.Timer() < self.LastEk + delays.e then return false end
            if Game.Timer() < self.LastR + delays.r or Game.Timer() < self.LastRk + delays.r then return false end
            return true
      end
      function __gsoSpell:CustomIsReady(spell, cd)
            local passT
            if spell == _Q then
                  passT = Game.Timer() - self.LastQk
            elseif spell == _W then
                  passT = Game.Timer() - self.LastWk
            elseif spell == _E then
                  passT = Game.Timer() - self.LastEk
            elseif spell == _R then
                  passT = Game.Timer() - self.LastRk
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
                  if Game.Timer() < self.LastQ + 0.35 then
                        return false
                  end
            elseif isW then
                  spell = HK_W
                  if Game.Timer() < self.LastW + 0.35 then
                        return false
                  end
            elseif isE then
                  spell = HK_E
                  if Game.Timer() < self.LastE + 0.35 then
                        return false
                  end
            elseif isR then
                  spell = HK_R
                  if Game.Timer() < self.LastR + 0.35 then
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
                        self.LastQ = Game.Timer()
                  elseif isW then
                        self.LastW = Game.Timer()
                  elseif isE then
                        self.LastE = Game.Timer()
                  elseif isR then
                        self.LastR = Game.Timer()
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
                  for k,v in pairs(self.DelayedSpell) do
                        if k == kNum then
                              if _G.gsoSDK.Cursor.IsCursorReady() then
                                    v[1]()
                                    _G.gsoSDK.Cursor:SetCursor(cursorPos, nil, 0.05)
                                    if k == 0 then
                                          self.LastQ = Game.Timer()
                                    elseif k == 1 then
                                          self.LastW = Game.Timer()
                                    elseif k == 2 then
                                          self.LastE = Game.Timer()
                                    elseif k == 3 then
                                          self.LastR = Game.Timer()
                                    end
                                    self.DelayedSpell[k] = nil
                                    break
                              end
                              if Game.Timer() - v[2] > 0.125 then
                                    self.DelayedSpell[k] = nil
                              end
                              break
                        end
                  end
            end
      end
      function __gsoSpell:WndMsg(msg, wParam)
            local manualNum = -1
            if wParam == HK_Q and Game.Timer() > self.LastQk + 1 and Game.CanUseSpell(_Q) == 0 then
                  self.LastQk = Game.Timer()
                  manualNum = 0
            elseif wParam == HK_W and Game.Timer() > self.LastWk + 1 and Game.CanUseSpell(_W) == 0 then
                  self.LastWk = Game.Timer()
                  manualNum = 1
            elseif wParam == HK_E and Game.Timer() > self.LastEk + 1 and Game.CanUseSpell(_E) == 0 then
                  self.LastEk = Game.Timer()
                  manualNum = 2
            elseif wParam == HK_R and Game.Timer() > self.LastRk + 1 and Game.CanUseSpell(_R) == 0 then
                  self.LastRk = Game.Timer()
                  manualNum = 3
            end
            if manualNum > -1 and not self.DelayedSpell[manualNum] then
                  local drawMenu = _G.gsoSDK.Menu.gsodraw.circle1
                  if _G.gsoSDK.Menu.orb.keys.combo:Value() or _G.gsoSDK.Menu.orb.keys.harass:Value() or _G.gsoSDK.Menu.orb.keys.lasthit:Value() or _G.gsoSDK.Menu.orb.keys.laneclear:Value() or _G.gsoSDK.Menu.orb.keys.flee:Value() then
                        self.DelayedSpell[manualNum] = {
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
--[[
▀▀█▀▀ █▀▀█ █▀▀█ █▀▀▀ █▀▀ ▀▀█▀▀ 　 ▒█▀▀▀█ █▀▀ █░░ █▀▀ █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
░▒█░░ █▄▄█ █▄▄▀ █░▀█ █▀▀ ░░█░░ 　 ░▀▀▀▄▄ █▀▀ █░░ █▀▀ █░░ ░░█░░ █░░█ █▄▄▀ 
░▒█░░ ▀░░▀ ▀░▀▀ ▀▀▀▀ ▀▀▀ ░░▀░░ 　 ▒█▄▄▄█ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░▀▀ 
]]
class "__gsoTS"
      function __gsoTS:__init()
            self.Menu = nil
            self.DrawSelMenu = nil
            self.DrawLHMenu = nil
            self.DrawALHMenu = nil
            self.SelectedTarget = nil
            self.LastSelTick = 0
            self.LastHeroTarget = nil
            self.LastMinionLastHit = nil
            self.FarmMinions = {}
            self.Priorities = {
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
            self.PriorityMultiplier = {
                  [1] = 1,
                  [2] = 1.15,
                  [3] = 1.3,
                  [4] = 1.45,
                  [5] = 1.6,
                  [6] = 1.75
            }
      end
      function __gsoTS:GetSelectedTarget()
            return self.SelectedTarget
      end
      function __gsoTS:CreatePriorityMenu(charName)
            local priority = self.Priorities[charName] ~= nil and self.Priorities[charName] or 5
            self.Menu.priority:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
      end
      function __gsoTS:CreateMenu(menu)
            self.mainMenu = menu
            self.Menu = menu:MenuElement({name = "Target Selector", id = "ts", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ts.png" })
            self.Menu:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = { "Auto", "Closest", "Least Health", "Least Priority" } })
            self.Menu:MenuElement({ id = "priority", name = "Priorities", type = MENU })
            _G.gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) self:CreatePriorityMenu(hero.charName) end)
            self.Menu:MenuElement({ id = "selected", name = "Selected Target", type = MENU })
            self.Menu.selected:MenuElement({ id = "enable", name = "Enable", value = true })
            self.Menu:MenuElement({name = "LastHit Mode", id = "lasthitmode", value = 1, drop = { "Accuracy", "Fast" } })
            self.Menu:MenuElement({name = "LaneClear Should Wait Time", id = "shouldwaittime", value = 200, min = 0, max = 1000, step = 50, tooltip = "Less Value = Faster LaneClear" })
            self.Menu:MenuElement({name = "LaneClear Harass", id = "laneset", value = true })
      end
      function __gsoTS:CreateDrawMenu(menu)
            self.DrawSelMenu = menu:MenuElement({name = "Selected Target",  id = "selected", type = MENU})
            self.DrawSelMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
            self.DrawSelMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(255, 204, 0, 0)})
            self.DrawSelMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
            self.DrawSelMenu:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
            self.DrawLHMenu = menu:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = MENU})
            self.DrawLHMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
            self.DrawLHMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 255, 255, 255)})
            self.DrawLHMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
            self.DrawLHMenu:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
            self.DrawALHMenu = menu:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = MENU})
            self.DrawALHMenu:MenuElement({name = "Enabled",  id = "enabled", value = true})
            self.DrawALHMenu:MenuElement({name = "Color",  id = "color", color = Draw.Color(150, 239, 159, 55)})
            self.DrawALHMenu:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
            self.DrawALHMenu:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
      end
      function __gsoTS:GetTarget(enemyHeroes, dmgAP)
      local selectedID
      if self.Menu.selected.enable:Value() and self.SelectedTarget then
      selectedID = self.SelectedTarget.networkID
      end
      local result = nil
      local num = 10000000
      local mode = self.Menu.Mode:Value()
      for i = 1, #enemyHeroes do
      local x
      local unit = enemyHeroes[i]
      if selectedID and unit.networkID == selectedID then
      return self.SelectedTarget
      elseif mode == 1 then
      local unitName = unit.charName
      local multiplier = self.PriorityMultiplier[self.Menu.priority[unitName] and self.Menu.priority[unitName]:Value() or 6]
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
      x = self.Menu.priority[unitName] and self.Menu.priority[unitName]:Value() or 6
      end
      if x < num then
      num = x
      result = unit
      end
      end
      return result
      end
      function __gsoTS:GetLastHeroTarget()
            return self.LastHeroTarget
      end
      function __gsoTS:GetLastMinionLastHit()
            return self.LastMinionLastHit
      end
      function __gsoTS:GetFarmMinions()
            return self.FarmMinions
      end
      function __gsoTS:GetComboTarget()
            local comboT = self:GetTarget(_G.gsoSDK.ObjectManager:GetEnemyHeroes(myHero.range+myHero.boundingRadius - 35, true, "attack"), false)
            if comboT ~= nil then
                  self.LastHeroTarget = comboT
            end
            return comboT
      end
      function __gsoTS:GetLastHitTarget()
            local min = 10000000
            local result = nil
            for i = 1, #self.FarmMinions do
                  local enemyMinion = self.FarmMinions[i]
                  if enemyMinion.LastHitable and enemyMinion.PredictedHP < min then
                        min = enemyMinion.PredictedHP
                        result = enemyMinion.Minion
                  end
            end
            if result ~= nil then
                  self.LastMinionLastHit = result
            end
            return result
      end
      function __gsoTS:GetLaneClearTarget()
            local enemyTurrets = _G.gsoSDK.ObjectManager:GetEnemyTurrets(myHero.range+myHero.boundingRadius - 35, true)
            for i = 1, #enemyTurrets do
                  return enemyTurrets[i]
            end
            if self.Menu.laneset:Value() then
                  local result = self:GetComboTarget()
                  if result then return result end
            end
            local result = nil
            if _G.gsoSDK.Farm:CanLaneClearTime() then
                  local min = 10000000
                  for i = 1, #self.FarmMinions do
                        local enemyMinion = self.FarmMinions[i]
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
            local lastHitMode = self.Menu.lasthitmode:Value() == 1 and "accuracy" or "fast"
            local cacheFarmMinions = {}
            for i = 1, #enemyMinions do
                  local enemyMinion = enemyMinions[i]
                  local FlyTime = myHero.attackData.windUpTime + ( myHero.pos:DistanceTo(enemyMinion.pos) / myHero.attackData.projectileSpeed )
                  cacheFarmMinions[#cacheFarmMinions+1] = _G.gsoSDK.Farm:SetLastHitable(enemyMinion, FlyTime, myHero.totalDamage, lastHitMode, allyMinions)
            end
            self.FarmMinions = cacheFarmMinions
      end
      function __gsoTS:WndMsg(msg, wParam)
            if msg == WM_LBUTTONDOWN and self.Menu.selected.enable:Value() and GetTickCount() > self.LastSelTick + 100 then
                  self.SelectedTarget = nil
                  local num = 10000000
                  local enemyList = _G.gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                  for i = 1, #enemyList do
                        local unit = enemyList[i]
                        local distance = mousePos:DistanceTo(unit.pos)
                        if distance < 150 and distance < num then
                              self.SelectedTarget = unit
                              num = distance
                        end
                  end
                  self.LastSelTick = GetTickCount()
            end
      end
      function __gsoTS:Draw()
            if self.DrawSelMenu.enabled:Value() then
                  if self.SelectedTarget and not self.SelectedTarget.dead and self.SelectedTarget.isTargetable and self.SelectedTarget.visible and self.SelectedTarget.valid then
                        Draw.Circle(self.SelectedTarget.pos, self.DrawSelMenu.radius:Value(), self.DrawSelMenu.width:Value(), self.DrawSelMenu.color:Value())
                  end
            end
            if not self.mainMenu.orb.enabledorb:Value() then return end
            if self.DrawLHMenu.enabled:Value() or self.DrawALHMenu.enabled:Value() then
                  for i = 1, #self.FarmMinions do
                        local minion = self.FarmMinions[i]
                        if minion.LastHitable and self.DrawLHMenu.enabled:Value() then
                              Draw.Circle(minion.Minion.pos, self.DrawLHMenu.radius:Value(), self.DrawLHMenu.width:Value(), self.DrawLHMenu.color:Value())
                        elseif minion.AlmostLastHitable and self.DrawALHMenu.enabled:Value() then
                              Draw.Circle(minion.Minion.pos, self.DrawALHMenu.radius:Value(), self.DrawALHMenu.width:Value(), self.DrawALHMenu.color:Value())
                        end
                  end
            end
      end
--[[
▒█░▒█ ▀▀█▀▀ ▀█▀ ▒█░░░ ▀█▀ ▀▀█▀▀ ▀█▀ ▒█▀▀▀ ▒█▀▀▀█ 
▒█░▒█ ░▒█░░ ▒█░ ▒█░░░ ▒█░ ░▒█░░ ▒█░ ▒█▀▀▀ ░▀▀▀▄▄ 
░▀▄▄▀ ░▒█░░ ▄█▄ ▒█▄▄█ ▄█▄ ░▒█░░ ▄█▄ ▒█▄▄▄ ▒█▄▄▄█ 
]]
class "__gsoUtilities"
      function __gsoUtilities:__init()
            self.MinLatency = Game.Latency() * 0.001
            self.MaxLatency = Game.Latency() * 0.001
            self.Min = Game.Latency() * 0.001
            self.LAT = {}
            self.DA = {}
      end
      function __gsoUtilities:DelayedActions()
            local cacheDA = {}
            for i = 1, #self.DA do
                  local t = self.DA[i]
                  if Game.Timer() > t.StartTime + t.Delay then
                        t.Func()
                  else
                        cacheDA[#cacheDA+1] = t
                  end
            end
            self.DA = cacheDA
      end
      function __gsoUtilities:Latencies()
            local lat1 = 0
            local lat2 = 50
            local latency = Game.Latency() * 0.001
            if latency < self.Min then
                  self.Min = latency
            end
            self.LAT[#self.LAT+1] = { endTime = Game.Timer() + 1.5, Latency = latency }
            local cacheLatencies = {}
            for i = 1, #self.LAT do
                  local t = self.LAT[i]
                  if Game.Timer() < t.endTime then
                        cacheLatencies[#cacheLatencies+1] = t
                        if t.Latency > lat1 then
                              lat1 = t.Latency
                              self.MaxLatency = lat1
                        end
                        if t.Latency < lat2 then
                              lat2 = t.Latency
                              self.MinLatency = lat2
                        end
                  end
            end
            self.LAT = cacheLatencies
      end
      function __gsoUtilities:Tick()
            self:DelayedActions()
            self:Latencies()
      end
      function __gsoUtilities:AddAction(func, delay)
            self.DA[#self.DA+1] = { StartTime = Game.Timer(), Func = func, Delay = delay }
      end
      function __gsoUtilities:GetMaxLatency()
            return self.MaxLatency
      end
      function __gsoUtilities:GetMinLatency()
            return self.MinLatency
      end
      function __gsoUtilities:GetUserLatency()
            return self.Min
      end
