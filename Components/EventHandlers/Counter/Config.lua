﻿-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local floor, min, max, strsub, strfind = 
	  floor, min, max, strsub, strfind
local pairs, ipairs, sort, tremove, CopyTable = 
	  pairs, ipairs, sort, tremove, CopyTable
	  
local CI = TMW.CI

-- GLOBALS: CreateFrame, NONE, NORMAL_FONT_COLOR



local EVENTS = TMW.EVENTS
local Counter = EVENTS:GetEventHandler("Counter")

Counter.handlerName = L["EVENTHANDLER_COUNTER_TAB"]
Counter.handlerDesc = L["EVENTHANDLER_COUNTER_TAB_DESC"]
Counter.testable = false

local operations = {
	{ text = L["OPERATION_SET"], 		value = "=", },
	{ text = L["OPERATION_PLUS"], 		value = "+", },
	{ text = L["OPERATION_MINUS"], 		value = "-", },
	--{ text = L["OPERATION_MULTIPLY"], 	value = "*", },
	--{ text = L["OPERATION_DIVIDE"], 	value = "/", },
}


---------- Events ----------
function Counter:LoadSettingsForEventID(eventID)
	local eventSettings = EVENTS:GetEventSettings(eventID)

	TMW:SetUIDropdownText(self.ConfigContainer.Operation, eventSettings.CounterOperation, operations)
	

	self.ConfigContainer.Counter:SetText(eventSettings.Counter)
	self.ConfigContainer.Amt:SetText(eventSettings.CounterAmt)
end

function Counter:SetupEventDisplay(eventID)
	if not eventID then return end

	local eventSettings = EVENTS:GetEventSettings(eventID)


	local Counter = eventSettings.Counter
	local CounterOperation = eventSettings.CounterOperation
	local CounterAmt = eventSettings.CounterAmt

	local str = Counter .. " "
	if Counter == "" then
		str = "|cff808080<No Counter>"
	else
		str = str .. CounterOperation .. " " .. CounterAmt
	end
	
	EVENTS.EventHandlerFrames[eventID].DataText:SetText("|cffcccccc" .. L["EVENTHANDLER_COUNTER_TAB"] .. ":|r " .. str)
end


function Counter:OperationMenu_DropDown()
	for k, v in pairs(operations) do
		local info = UIDropDownMenu_CreateInfo()
		info.func = Counter.OperationMenu_DropDown_OnClick
		info.text = v.text
		info.value = v.value
		info.tooltipOnButton = true
		info.arg1 = self
		UIDropDownMenu_AddButton(info)
	end
end

function Counter:OperationMenu_DropDown_OnClick(frame)
	TMW:SetUIDropdownText(frame, self.value, operations)
	
	local eventSettings = EVENTS:GetEventSettings()
	eventSettings.CounterOperation = self.value
end


local SUG = TMW.SUG
local Module = SUG:NewModule("counterName", SUG:GetModule("default"))
Module.noMin = true
Module.noTexture = true

function Module:Table_GetSorter()
	return nil
end
function Module:Entry_AddToList_1(f, name)
	f.Name:SetText(name)

	f.tooltiptitle = name

	f.insert = name
end
function Module:Table_GetNormalSuggestions(suggestions, tbl, ...)
	local lastName = SUG.lastName


	for eventSettings in EVENTS:InIconEventSettings() do
		if eventSettings.Counter ~= "" and strfind(eventSettings.Counter, lastName) then
			suggestions[#suggestions + 1] = eventSettings.Counter
		end
	end
end
