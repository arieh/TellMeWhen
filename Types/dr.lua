﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>
-- Major updates by
-- Oozebull of Twisting Nether
-- Banjankri of Blackrock
-- Cybeloras of Mal'Ganis
-- --------------------

local TMW = TMW
if not TMW then return end
local L = TMW.L

local db, UPD_INTV, ClockGCD, pr, ab, rc, mc
local strlower, bitband =
	  strlower, bit.band
local UnitGUID, UnitExists, GetSpellTexture =
	  UnitGUID, UnitExists, GetSpellTexture
local print = TMW.print
local huge = math.huge
local strlowerCache = TMW.strlowerCache
local SpellTextures = TMW.SpellTextures

local clientVersion = select(4, GetBuildInfo())

local DRData = LibStub("DRData-1.0", true)
if not DRData then return end
local DRSpells = DRData.spells
local DRReset = DRData.RESET_TIME
local PvEDRs = {}
for spellID, category in pairs(DRSpells) do
	if DRData.pveDR[category] then
		PvEDRs[spellID] = 1
	end
end

local RelevantSettings = {
	Name = true,
	ShowTimer = true,
	ShowTimerText = true,
	ShowWhen = true,
	Unit = true,
	Alpha = true,
	UnAlpha = true,
	ShowCBar = true,
	InvertBars = true,
	CBarOffs = true,
	StackMin = true,
	StackMax = true,
	StackMinEnabled = true,
	StackMaxEnabled = true,
	DurationMin = true,
	DurationMax = true,
	DurationMinEnabled = true,
	DurationMaxEnabled = true,
	ConditionAlpha = true,
	FakeHidden = true,
}

local Type = TMW:RegisterIconType("dr", RelevantSettings)
LibStub("AceEvent-3.0"):Embed(Type)
Type.name = L["ICONMENU_DR"]
Type.desc = L["ICONMENU_DR_DESC"]
Type.WhenChecks = {
	text = L["ICONMENU_SHOWWHEN"],
	{ value = "alpha", 			text = L["ICONMENU_DRPRESENT"], 		colorCode = "|cFFFF0000" },
	{ value = "unalpha",  		text = L["ICONMENU_DRABSENT"], 			colorCode = "|cFF00FF00" },
	{ value = "always", 		text = L["ICONMENU_ALWAYS"] },
}


function Type:Update()
	db = TMW.db
	UPD_INTV = db.profile.Interval
	ClockGCD = db.profile.ClockGCD
	pr = db.profile.PRESENTColor
	ab = db.profile.ABSENTColor
	rc = db.profile.OORColor
	mc = db.profile.OOMColor
end

local SpellTextures = TMW.SpellTextures

local function func(icon, g, i)
	local dr = icon[g]
	if not dr then
		dr = {
			amt = 50,
			start = TMW.time, 
			duration = 18,
			tex = SpellTextures[i]
		}
		icon[g] = dr
	else
		local amt = dr.amt
		if amt ~= 0 then
			dr.amt = amt > 25 and amt/2 or 0
			dr.duration = 18
			dr.start = TMW.time
			dr.tex = SpellTextures[i]
		end
	end
end

local CL_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local CL_PET = COMBATLOG_OBJECT_CONTROL_PLAYER

local DR_OnEvent
local function DR_OnEvent(icon, _, _, p, ...)
	if p == "SPELL_AURA_REMOVED" or p == "SPELL_AURA_REFRESH" then
		local g, f, i, n, t, _
		if clientVersion >= 40200 then
			_, _, _, _, _, g, _, f, _, i, n, _, t = ...
		elseif clientVersion >= 40100 then
			_, _, _, _, g, _, f, i, n, _, t = ...
		else
			_, _, _, g, _, f, i, n, _, t = ...
		end
		if t == "DEBUFF" then
			local ND = icon.NameDictionary
			if ND[i] or ND[strlowerCache[n]] then
				if PvEDRs[i] or bitband(f, CL_PLAYER) == CL_PLAYER or bitband(f, CL_PET) == CL_PET then
					local dr = icon[g]
					if not dr then
						dr = {
							amt = 50,
							start = TMW.time, 
							duration = 18,
							tex = SpellTextures[i]
						}
						icon[g] = dr
					else
						local amt = dr.amt
						if amt ~= 0 then
							dr.amt = amt > 25 and amt/2 or 0
							dr.duration = 18
							dr.start = TMW.time
							dr.tex = SpellTextures[i]
						end
					end
				end
			end
		end
	end
end


local function DR_OnUpdate(icon, time)
	if icon.UpdateTimer <= time - UPD_INTV then
		icon.UpdateTimer = time
		local CndtCheck = icon.CndtCheck if CndtCheck and CndtCheck() then return end
		local Alpha, UnAlpha, Units = icon.Alpha, icon.UnAlpha, icon.Units
		
		for u = 1, #Units do
			local unit = Units[u]
			local dr = UnitExists(unit) and icon[UnitGUID(unit)]
			if dr then
				if dr.start + dr.duration <= time then
					dr.amt = 100
					icon:SetInfo(Alpha, 1, dr.tex, 0, 0)
					if Alpha > 0 then
						return
					end
				else
					local amt = dr.amt
					icon:SetInfo(UnAlpha, (not icon.ShowTimer and Alpha ~= 0) and .5 or 1, dr.tex, dr.start, dr.duration, nil, nil, nil, amt, amt .. "%")
					if UnAlpha > 0 then
						return
					end
				end
			else
				icon:SetInfo(Alpha, 1, icon.FirstTexture, 0, 0)
				if Alpha > 0 then
					return
				end
			end
		end
		icon:SetAlpha(0)
	end
end			

local warnedMismatch = {}
function Type:Setup(icon, groupID, iconID)
	icon.ShowPBar = false
	icon.NameFirst = TMW:GetSpellNames(icon, icon.Name, 1)
	icon.NameDictionary = TMW:GetSpellNames(icon, icon.Name, nil, nil, 1)
	icon.Units = TMW:GetUnits(icon, icon.Unit)
	icon.FirstTexture = SpellTextures[icon.NameFirst]

	if not db.profile.Locked and not warnedMismatch[icon] then
		-- Do the Right Thing and tell people if their DRs mismatch
		local firstCategory, dobreak
		for spellID in pairs(icon.NameDictionary) do
			for category, str in pairs(TMW.BE.dr) do
				if strfind(";"..str..";", ";"..spellID..";") then
					if not firstCategory then
						firstCategory = category
					end
					if firstCategory ~= category then
						TMW:Printf(L["WARN_DRMISMATCH"], groupID, iconID)
						warnedMismatch[icon] = 1
						dobreak=1
						break
					end
				end
			end
			if dobreak then
				break
			end
		end
	end
	
	if icon.Name == "" then
		icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	elseif GetSpellTexture(icon.NameFirst) then
		icon:SetTexture(GetSpellTexture(icon.NameFirst))
	elseif TMW:DoSetTexture(icon) then
		icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
	end

	icon:SetScript("OnEvent", DR_OnEvent)
	icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	icon:SetScript("OnUpdate", DR_OnUpdate)
	icon:OnUpdate(TMW.time)
end