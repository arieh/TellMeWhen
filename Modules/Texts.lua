-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

local DogTag = LibStub("LibDogTag-3.0", true)
local LMB = LibStub("Masque", true) or (LibMasque and LibMasque("Button"))
local LSM = LibStub("LibSharedMedia-3.0")

if not DogTag then return end

local pairs, wipe = pairs, wipe


TMW.MasqueSkinnableTexts = {
	[""] = L["TEXTLAYOUTS_SKINAS_NONE"],
	Count = L["TEXTLAYOUTS_SKINAS_COUNT"],
	HotKey = L["TEXTLAYOUTS_SKINAS_HOTKEY"],
}	
	
local Texts = TMW:NewClass("IconModule_Texts", "IconModule")
function Texts:OnNewInstance(icon)
	self.kwargs = {}
	self.fontStrings = {}
	
	-- we need to make sure that all strings that are Masque skinnable are always created
	-- so that skinning isnt really weird and awkward.
	-- If Masque isn't installed, then don't bother - we will create them normally on demand.
	if LMB then
		for key in pairs(TMW.MasqueSkinnableTexts) do
			if key ~= "" then
				local fontString = self:CreateFontString(key)
				self:SetSkinnableComponent(key, fontString)
			end
		end
	end
end

function Texts:OnEnable()
	local icon = self.icon
	local attributes = icon.attributes
	self:DOGTAGUNIT(icon, attributes.dogTagUnit)
end
function Texts:OnDisable()
	for i = 1, #self do
		local fontString = self[i]
		
		DogTag:RemoveFontString(fontString)			
		fontString:Hide()
	end
end

function Texts:CreateFontString(id)
	local icon = self.icon
	local fontString = icon:CreateFontString(nil, "ARTWORK", "NumberFontNormalSmall")
	self.fontStrings[id] = fontString
	return fontString
end

function Texts:SetupForIcon(sourceIcon)
	local icon = self.icon

	--[[
	TODO: the way that this works for meta icons is really weird if the meta is a different view than the source.
	Consider forcing meta icons to only inherit from their own view (but that would suck),
	or add a warning when they are of different views (which would be good),
	or allow users to configure icons for multiple views without actually changing the view
		(something like "Configure as..." in the icon editor)
	]]
	
	
	local Texts = sourceIcon:GetSettingsPerView().Texts
	local _, layoutSettings = sourceIcon:GetTextLayout() 
	self.layoutSettings = layoutSettings
	self.Texts = Texts
	
	wipe(self.kwargs)
	self.kwargs.icon = sourceIcon.ID
	self.kwargs.group = sourceIcon.group.ID
	self.kwargs.unit = sourceIcon.attributes.dogTagUnit
	self.kwargs.color = TMW.db.profile.ColorNames
	
	for _, fontString in pairs(self.fontStrings) do
		fontString.TMW_QueueForRemoval = true
	end
		
	if layoutSettings then				
		for fontStringID, fontStringSettings in TMW:InNLengthTable(layoutSettings) do
			local SkinAs = fontStringSettings.SkinAs
			fontStringID = self:GetFontStringID(fontStringID, fontStringSettings)
			
			local fontString = self.fontStrings[fontStringID] or self:CreateFontString(fontStringID)
			fontString:Show()
			fontString.settings = fontStringSettings
			
			fontString:SetWidth(fontStringSettings.ConstrainWidth and icon:GetWidth() or 0)
	
			if not LMB or SkinAs == "" then
				-- Position
				fontString:ClearAllPoints()
				local func = fontString.__MSQ_SetPoint or fontString.SetPoint
				func(fontString, fontStringSettings.point, icon, fontStringSettings.relativePoint, fontStringSettings.x, fontStringSettings.y)

				fontString:SetJustifyH(fontStringSettings.point:match("LEFT") or fontStringSettings.point:match("RIGHT") or "CENTER")
				
				-- Font
				fontString:SetFont(LSM:Fetch("font", fontStringSettings.Name), fontStringSettings.Size, fontStringSettings.Outline)
			end
		end
	end
	
	self:OnKwargsUpdated()
	
	for _, fontString in pairs(self.fontStrings) do
		if fontString.TMW_QueueForRemoval then
			fontString.TMW_QueueForRemoval = nil
			DogTag:RemoveFontString(fontString)
			fontString:Hide()
		end
	end
end

function Texts:GetFontStringID(fontStringID, fontStringSettings)
	local SkinAs = fontStringSettings.SkinAs
	if SkinAs ~= "" then
		fontStringID = SkinAs
	end
	return fontStringID
end

function Texts:OnKwargsUpdated()
	if self.layoutSettings and self.Texts then
		for fontStringID, fontStringSettings in TMW:InNLengthTable(self.layoutSettings) do
			local fontString = self.fontStrings[self:GetFontStringID(fontStringID, fontStringSettings)]
			local text = self.Texts[fontStringID] or ""
			
			if fontString and text ~= "" then
				local styleString = ""
				if fontStringSettings.Outline == "OUTLINE" or fontStringSettings.Outline == "THICKOUTLINE" or fontStringSettings.Outline == "MONOCHROME" then
					styleString = styleString .. ("[%s]"):format(fontStringSettings.Outline)
				end
				
				fontString.TMW_QueueForRemoval = nil
				DogTag:AddFontString(fontString, self.icon, styleString .. (self.Texts[fontStringID] or ""), "Unit;TMW", self.kwargs)
			end
		end
	end
end

function Texts:DOGTAGUNIT(icon, dogTagUnit)
	self.kwargs.unit = dogTagUnit
	self:OnKwargsUpdated()
end
Texts:SetDataListner("DOGTAGUNIT")