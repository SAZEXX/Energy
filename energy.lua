
	-- config

	local showTick = true

	local smoothBars = true
	local smoothTime = 0.1

	local fadeFrame = true
	local fadeInTime = 0.07
	local fadeOutTime = 0.15

	energycolor = { 255/255, 225/255, 26/255}
	cpcolors = {
		[1] = { 208/255, 120/255, 72/255 },
		[2] = { 240/255, 190/255, 89/255 },
		[3] = { 216/255, 231/255, 92/255 },
		[4] = { 139/255, 243/255, 83/255 },
		[5] = { 60/255, 255/255, 73/255 },
	}

--	local font = "Interface\\AddOns\\energy\\homespun.ttf"
--	local texture = "Interface\\AddOns\\energy\\statusbar.tga"

	---------------------------------------------------------------------------------------------

	local lastTick, nextTick, points = 0, 0, 0
	local curEnergy, maxEnergy, inCombat, smoothing
	local stealthed, hasTarget, powerType, class, firstEvent, isDead
	local energy = CreateFrame('Statusbar', nil, PlayerFrameManaBar)
	energy:SetWidth(PlayerFrameManaBar:GetWidth())
    energy:SetAllPoints(PlayerFrameManaBar)
    energy:Hide()
	
	local spark = energy:CreateTexture(nil, 'OVERLAY')
    spark:SetTexture[[Interface\CastingBar\UI-CastingBar-Spark]]
    spark:SetSize(32, 32)
    spark:SetBlendMode('ADD')
    spark:SetAlpha(.4)

	---------------------------------------------------------------------------------------------
  
	local function InitFrames()
		powerType = UnitPowerType("player")
		curEnergy, maxEnergy = UnitPower("player"), UnitPowerMax("player")
		energy:SetMinMaxValues(0, maxEnergy)
		energy:SetValue(curEnergy)
	end

	local function StartFrameFade(frame, show)
		if show and frame.hidden then
			UIFrameFadeIn(frame, fadeInTime, 0, 1)
			frame.hidden = false
		elseif not show and not frame.hidden then
			UIFrameFadeOut(frame, fadeOutTime, 1, 0)
			frame.hidden = true
		end
	end

	local function UpdateEnergy()
		local newEnergy = UnitPower("player")

		if smoothBars then
			if smoothing then
				energy:SetValue(curEnergy)
			else
				smoothing = true
			end
			energy.start = curEnergy
			energy.target = newEnergy
			energy.startTime = GetTime()
		else
			energy:SetValue(newEnergy)
		end

		if showTick then
			if newEnergy == curEnergy + 20 then
				local time = GetTime()
				lastTick = time
				nextTick = time + 2
			end
		end
		curEnergy = newEnergy
	end

	---------------------------------------------------------------------------------------------

	local function OnEvent(self, event, unit)

		if not firstEvent then
			InitFrames()
			firstEvent = true
		end

		if event == "UNIT_POWER_UPDATE" then
			UpdateEnergy()

		elseif event == "UNIT_MAXPOWER" then
			InitFrames()

		elseif event == "PLAYER_REGEN_DISABLED" then
			inCombat = true

		elseif event == "PLAYER_REGEN_ENABLED" then
			inCombat = false

		elseif event == "UPDATE_STEALTH" then
			stealthed = IsStealthed()

		elseif event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
			isDead = UnitIsDeadOrGhost("player")

		elseif event == "UNIT_DISPLAYPOWER" and unit == "player" then
			powerType = UnitPowerType("player")
			if powerType == 3 then
				InitFrames()
			end

		elseif event == "PLAYER_LOGIN" then
			InitFrames()
		end

		-- show/hide
		if class == "DRUID" and powerType ~= 3 then
			StartFrameFade(energy, false)
		elseif fadeFrame then
			if not isDead and (points > 0 or stealthed or inCombat or hasTarget or curEnergy ~= maxEnergy) then
				StartFrameFade(energy, true)
			else
				StartFrameFade(energy, false)
			end
		else
			StartFrameFade(energy, true)
		end
	end

	local function OnUpdate(self, elapsed)

		if showTick then
			local time = GetTime()

			if nextTick == 0 then
				lastTick = time
				nextTick = time + 2
			elseif time > nextTick then
				lastTick = nextTick
				nextTick = nextTick + 2
			end

			if not energy.hidden then
				local pct = (time - lastTick) * 0.5
				spark:SetPoint('CENTER', energy, 'LEFT', (energy:GetWidth() * (pct)), 0)
			end
		end

		if smoothing then
			local cur = energy:GetValue()
			local start = energy.start
			local target = energy.target

			local pct = min(1, (GetTime() - energy.startTime) / smoothTime)
			local new = start + (target - start) * pct

			if new ~= cur then
				energy:SetValue(new)
			end

			if pct == 1 then
				smoothing = false
			end
		end
	end

	---------------------------------------------------------------------------------------------

	class = select(2, UnitClass("player"))

	if class == "ROGUE" or class == "DRUID" then

		if fadeFrame or class == "DRUID" then
			energy:SetAlpha(0)
			energy.hidden = true
		end

		powerType = UnitPowerType("player")
		curEnergy, maxEnergy = UnitPower('player'), UnitPowerMax("player")

		energy:SetScript("OnEvent", OnEvent)
		energy:RegisterEvent("UNIT_POWER_UPDATE")
		energy:RegisterEvent("UNIT_MAXPOWER")
		energy:RegisterEvent("PLAYER_TARGET_CHANGED")
		energy:RegisterEvent("PLAYER_LOGIN")

		if fadeFrame then
			energy:RegisterEvent("PLAYER_DEAD")
			energy:RegisterEvent("PLAYER_ALIVE")
			energy:RegisterEvent("PLAYER_UNGHOST")
			energy:RegisterEvent("UPDATE_STEALTH")
			energy:RegisterEvent("PLAYER_REGEN_ENABLED")
			energy:RegisterEvent("PLAYER_REGEN_DISABLED")
		end

		if class == "DRUID" then
			energy:RegisterEvent("UNIT_DISPLAYPOWER")
		end

		if showTick or smoothBars then
			energy:SetScript("OnUpdate", OnUpdate)
		end
	end

	---------------------------------------------------------------------------------------------
