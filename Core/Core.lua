-- $Id$
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
local pairs, string, select = _G.pairs, _G.string, _G.select
-- Libraries
local format = string.format

local GetCursorPosition, GetSubZoneText, GetZoneText = _G.GetCursorPosition, _G.GetSubZoneText, _G.GetZoneText
local C_Map = _G.C_Map
local GetPlayerMapPosition, GetBestMapForUnit = C_Map.GetPlayerMapPosition, C_Map.GetBestMapForUnit
local WorldMapScrollChild = WorldMapFrame.ScrollContainer.Child
local C_AddOns = _G.C_AddOns
local GetAddOnInfo, GameTooltip = C_AddOns.GetAddOnInfo, _G.GameTooltip
local C_PvP = _G.C_PvP
local GetZonePVPInfo = C_PvP.GetZonePVPInfo

local GetBuildInfo = _G.GetBuildInfo

-- Determine WoW TOC Version
local wowversion  = select(4, GetBuildInfo())
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and wowversion >= 120000)
local isClassicEra = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isAnniversaryTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC or (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and wowversion >= 20000 and wowversion < 30000))
local isProgressionClassic = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isClassicForever = (wowversion >= 10000 and wowversion < 20000)

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local L = LibStub("AceLocale-3.0"):GetLocale(private.addon_name)
local AceDB = LibStub("AceDB-3.0")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject(private.addon_name, {
	type = "data source",
	text = L["TITLE"],
	label = L["TITLE"],
	icon = "Interface\\MINIMAP\\MinimapArrow",
})
local Media = LibStub("LibSharedMedia-3.0")

-- Frame names
local onscreenName = private.addon_name.."Frame"
local worldmapName = "CoordsOnWorldMapFrame"
local MyFrame = _G[onscreenName]
if not MyFrame then MyFrame = CreateFrame("Frame", onscreenName, UIParent, BackdropTemplateMixin and "BackdropTemplate") end

local addon = LibStub("AceAddon-3.0"):NewAddon(MyFrame, private.addon_name, "AceEvent-3.0")
addon.constants = private.constants
addon.constants.addon_name = private.addon_name
addon.Name = FOLDER_NAME
addon.LocName = select(2, GetAddOnInfo(addon.Name))
addon.Notes = select(3, GetAddOnInfo(addon.Name))
_G.CoordsTracking = addon
local profile
local locationText = ""

local isInLockdown = false

local CRDS_ORIG_GAMPTOOLTIP_SCALE = GameTooltip:GetScale()
local CRDS_POSTEXT = nil

local function getLocationText()
	local subZoneText = GetSubZoneText()
	local zoneText = GetZoneText()
	if (subZoneText == "") then
		locationText = zoneText
	else
		locationText = format("%s - %s", zoneText, subZoneText)
	end
	return locationText
end

-- Codes adopted from Mapster
local function getCursorPositionText()
	local left, top = WorldMapScrollChild:GetLeft() or 0, WorldMapScrollChild:GetTop() or 0
	local width, height = WorldMapScrollChild:GetWidth(), WorldMapScrollChild:GetHeight()
	local scale = WorldMapScrollChild:GetEffectiveScale()
	
	local cx, cy, x, y
	
	if (width == 0) or (height == 0) then 
		cx, cy = 0, 0
	else
		x, y = GetCursorPosition()
		cx = (x/scale - left) / width
		cy = (top - y/scale) / height
	end 

	if (cx < 0 or cx > 1 or cy < 0 or cy > 1) then
		return
	end

	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local crdsText, posText
	local acc = profile.worldmap_accuracy
	
	crdsText = crdsTextTemplate:format(acc, acc)
	
	posText = format(crdsText, cx*100, cy*100)
	
	return posText
end

local function getPlayerPositionText(isWorldMap)
	local posText, crdsText, posX, posY
	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local acc = isWorldMap and profile.worldmap_accuracy or profile.coords_accuracy
	
	local uiMapID = GetBestMapForUnit("player")
	local posXY = nil
	if (uiMapID) then 
		posXY = GetPlayerMapPosition(uiMapID, "player") or nil
	end
	
	crdsText = crdsTextTemplate:format(acc, acc)
	
	if ( IsInInstance() or (C_Garrison and C_Garrison.IsOnGarrisonMap())) then
		if (profile.show_indungeon) then
			posText = "0.0, 0.0"
		else
			posText = ""
		end
	elseif (posXY) then
		posX, posY = posXY:GetXY()
		posText = format(crdsText, posX and posX*100 or 0, posY and posY*100 or 0)
	end
	
	return posText
end

local function getButtonText()
	local posText = ""
	local playerPosText = getPlayerPositionText()

	if (profile.show_zonename) then
		if ( IsInInstance() ) then
			if (profile.show_indungeon) then 
				posText = format("%s"..L["COLON"].."%s", locationText or "", playerPosText or "")
			else
				posText = ""
			end
		else
			posText = format("%s"..L["COLON"].."%s", locationText or "", playerPosText or "")
		end
	else
		posText = playerPosText
	end

	return posText
end

local function updateButtonText()
	if (profile.show_coords_onscreen) then
	
		local posText = getButtonText() or ""
		if (posText ~= CRDS_POSTEXT) then
			local pvpType = GetZonePVPInfo()
			local color = {}

			if ( pvpType == "sanctuary" ) then
				color = {r=0.41, g=0.8, b=0.94}
			elseif ( pvpType == "arena" ) then
				color = {r=1.0, g=0.1, b=0.1}
			elseif ( pvpType == "friendly" ) then
				color = {r=0.1, g=1.0, b=0.1}
			elseif ( pvpType == "hostile" ) then
				color = {r=1.0, g=0.1, b=0.1}
			elseif ( pvpType == "contested" ) then
				color = {r=1.0, g=0.7, b=0.0}
			else
				--color = {r=HIGHLIGHT_FONT_COLOR.r, g=HIGHLIGHT_FONT_COLOR.g, b=HIGHLIGHT_FONT_COLOR.b}
				color.r, color.g, color.b = HIGHLIGHT_FONT_COLOR:GetRGB()
			end

			local colortag = format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)

			if (CoordsTrackingFrame:IsShown()) then
				addon.Text:SetText(posText)
				addon:SetWidth(CoordsTrackingFrame.Text:GetStringWidth())
				addon.Text:SetTextColor(color.r, color.g, color.b)
			end

			LDB.text = colortag..posText..FONT_COLOR_CODE_CLOSE
			CRDS_POSTEXT = posText
		end
	end
end

local function updateWorldmapText(isInitialize)
	local isWorldMapOpened = WorldMapFrame:IsShown()
	local WMFrame = addon.WorldMapFrame
	local playerPosText = getPlayerPositionText(true) or ""

	if (profile.show_coords_onworldmap and (isWorldMapOpened or isInitialize)) then
		WMFrame.playerTxt:SetText(UnitName("player")..L["COLON"]..playerPosText)
		local cursorPos = getCursorPositionText()
		if (cursorPos) then
			WMFrame.cursorTxt:SetText(L["Cursor"]..L["COLON"]..cursorPos)
			WMFrame.cursorTxt:Show()
		else
			--WMFrame.cursorTxt:SetText("")
			WMFrame.cursorTxt:Hide()
		end
	end
end


local function get_zonename_tooltip(frame)
	if (not GameTooltip:IsShown()) then
		local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
		local zoneText = locationText
		if frame then GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM", -10, 0) end
		--GameTooltip:SetBackdropColor(0, 0, 0, profile.tooltip_alpha)
		GameTooltip.NineSlice:SetCenterColor(0, 0, 0, profile.tooltip_alpha)
		if ( pvpType == "sanctuary" ) then
			GameTooltip:SetText( zoneText.." "..SANCTUARY_TERRITORY, 0.41, 0.8, 0.94 )
		elseif ( pvpType == "arena" ) then
			GameTooltip:SetText( zoneText.." "..FREE_FOR_ALL_TERRITORY, 1.0, 0.1, 0.1 )	
		elseif ( pvpType == "friendly" ) then
			GameTooltip:SetText( zoneText, 0.1, 1.0, 0.1 )
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 0.1, 1.0, 0.1)
		elseif ( pvpType == "hostile" ) then
			GameTooltip:SetText( zoneText, 1.0, 0.1, 0.1 )
			GameTooltip:AddLine(format(FACTION_CONTROLLED_TERRITORY, factionName), 1.0, 0.1, 0.1)
		elseif ( pvpType == "contested" ) then
			GameTooltip:SetText( zoneText.." "..CONTESTED_TERRITORY, 1.0, 0.7, 0.0 )	
		elseif ( pvpType == "combat" ) then
			GameTooltip:SetText( zoneText.." "..COMBAT_ZONE, 1.0, 0.1, 0.1 )
		else
			GameTooltip:SetText( zoneText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b )
		end
		GameTooltip:SetScale(profile.tooltip_scale)
		GameTooltip:Show()
	else
		GameTooltip:Hide()
	end
end

local function onscreenFrameStatusRefresh()
	local f = _G[private.addon_name.."Frame"]
	if (f and profile.show_coords_onscreen) then
		if (IsInInstance() and (not profile.show_indungeon)) then
			f:Hide()
		else
			f:Show()
			f:SetAlpha(profile.alpha)
			f:SetScale(profile.scale)
			local point, relativePoint, ofsx, ofsy = unpack(profile.latestpoint)
			f:ClearAllPoints()
			f:SetPoint(point or "TOPLEFT", UIParent, relativePoint or "TOPLEFT", ofsx or 450, ofsy or -80)
		end
	elseif (f) then
		f:Hide()
	else
		-- do nothing
	end
end

local function setupCoordsTrackingFrame()
	local function onShow()
		CRDS_POSTEXT = nil
	end

	local function onMouseDown(self, buttonName)    
		-- Prevent activation when in combat
		if (isInLockdown) then
			return
		end
		if(CoordsTrackingFrame:IsVisible()) then
			-- Handle left button clicks
			if (buttonName == "LeftButton") then
				-- Hide tooltip while draging
				GameTooltip:Hide()
				CoordsTrackingFrame:StartMoving()
			elseif (buttonName == "RightButton") then
				addon:OpenOptions()
				GameTooltip_Hide()
			end
		end
	end

	local function onMouseUp(self, buttonName)
		if(CoordsTrackingFrame:IsVisible()) then
			CoordsTrackingFrame:StopMovingOrSizing()
			local point, _, relativePoint, offsetX, offsetY = CoordsTrackingFrame:GetPoint()
			profile.latestpoint = { point, relativePoint, offsetX, offsetY }
		end
	end

	local function onEnter(self)
		if (isInLockdown) then
			return
		end

		if (profile.show_zonenametooltip) then
			if(CoordsTrackingFrame:IsVisible() and (not IsInInstance())) then
				get_zonename_tooltip(self)
			end
		end
	end

	local function onLeave(self)
		GameTooltip_Hide()
		GameTooltip:SetScale(CRDS_ORIG_GAMPTOOLTIP_SCALE)
	end

	local function onUpdate()
		updateButtonText()
	end

	local name = addon.Name
	
	local f = _G[name.."Frame"]
	if not f then f = CreateFrame("Frame", name.."Frame", UIParent, BackdropTemplateMixin and "BackdropTemplate") end
	f:SetWidth(200)
	f:SetHeight(28)
	--f:SetText(name)
	local point, relativePoint, ofsx, ofsy = unpack(profile.latestpoint)
	f:SetPoint(point or "TOPLEFT", UIParent, relativePoint or "TOPLEFT", ofsx or 450, ofsy or -80)
	
	f.Background = f:CreateTexture(name.."Background", "BACKGROUND")
	f.Border = CreateFrame("Frame", name.."Border", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	
	f.Text = f:CreateFontString(name.."Text", "OVERLAY", "NumberFontNormal")
	f.Text:SetPoint("CENTER", 0, 0)
	
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	
	-- SetScript
	f:SetScript("OnEnter", onEnter)
	f:SetScript("OnLeave", onLeave)
	f:SetScript("OnMouseDown", onMouseDown)
	f:SetScript("OnMouseUp", onMouseUp)
	f:SetScript("OnShow", onShow)
	f:SetScript("OnUpdate", onUpdate)
end

local function setupLDB()
	-- setup LDB
	LDB.text = getButtonText()
	LDB.OnClick = (function(self, button) addon:OpenOptions() end)
	LDB.OnTooltipShow = (function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		if (profile.show_zonenametooltip) then
			get_zonename_tooltip()
		end
	end)
end

function addon:SetOnScreenFontStyle()
	local f = _G[private.addon_name.."Frame"]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_onscreen)
		f.Text:SetFont(newfont, profile.fontsize_onscreen, profile.fontoutline_onscreen and "OUTLINE" or nil)
	end
end

function addon:SetOnScreenBackground()
	local f = _G[private.addon_name.."Frame"]
	if (f) then
		f.Background:SetAllPoints()
		f.Background:SetTexture(profile.background or nil)
		f.Background:SetSize(f:GetWidth(), f:GetHeight())
		f.Background:SetPoint("TOPLEFT", 0, 0)
		local t = profile.backgroundColor or nil
		if t then
			f.Background:SetVertexColor(t.r, t.g, t.b, t.a)
		else
			f.Background:SetVertexColor(0, 0, 0, 1)
		end
	end
end

function addon:SetWorldMapFontStyle()
	local f = _G[worldmapName]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_worldmap)
		f.playerTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
		f.cursorTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
	end
end

function addon:SetWorldMapFontColor()
	local f = _G[worldmapName]
	local color = profile.fontcolor_worldmap
	if (f) then
		f.playerTxt:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
		f.cursorTxt:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
	end
end

local function CoordsOnWorldMapFrameRefresh()
	local ofsx_diff1, ofsy_diff1, ofsy_diff2 = 0, 0, 0
	if (isRetail) then
		ofsy_diff2 = -4
	elseif (isProgressionClassic) then
		-- for now no adjustments needed
	elseif (isClassicForever) then
		ofsx_diff1 = 120
		ofsy_diff1 = 6
		ofsy_diff2 = -10
	else
		ofsy_diff1 = 6
		ofsy_diff2 = 20
	end

	local f = _G[worldmapName]
	if not f then return end
	updateWorldmapText(true)
	if (profile.wmPoint) then
		local wp = profile.wmPoint
		local point, relativePoint, ofsx, ofsy = wp.point, wp.relativePoint, wp.ofsx, wp.ofsy
		-- adjust horizontal offset for right-aligned points
		if (point == "TOPRIGHT" or point == "BOTTOMRIGHT") then
			ofsx = -ofsx - ofsx_diff1
		end
		-- offset when point is at the top or bottom
		if (point == "TOPRIGHT" or point == "TOPLEFT") then
			ofsy = - ofsy - ofsy_diff1
		else
			ofsy = ofsy - ofsy_diff2
		end
		
		if (point == "TOPRIGHT" or point == "BOTTOMRIGHT") then
			f.cursorTxt:ClearAllPoints()
			f.cursorTxt:SetPoint(point, WorldMapFrame.ScrollContainer, relativePoint, ofsx, ofsy)
			f.playerTxt:ClearAllPoints()
			f.playerTxt:SetPoint("TOPRIGHT", f.cursorTxt, "TOPLEFT", -20, 0)
		else
			f.playerTxt:ClearAllPoints()
			f.playerTxt:SetPoint(point or "TOPLEFT", WorldMapFrame.ScrollContainer, relativePoint or "TOPLEFT", ofsx or 0, ofsy or 0)
			f.cursorTxt:ClearAllPoints()
			f.cursorTxt:SetPoint("TOPLEFT", f.playerTxt, "TOPRIGHT", 20, 0)
		end
	end
end

local function createCoordsOnWorldMapFrame()
	local f = _G[worldmapName]
	if not f then f = CreateFrame("Frame", worldmapName, WorldMapFrame.ScrollContainer, BackdropTemplateMixin and "BackdropTemplate") end
	
	local function onUpdate()
		updateWorldmapText()
	end

	f.playerTxt = f:CreateFontString(worldmapName.."PlayerText", "OVERLAY", "NumberFontNormal")
	--f.playerTxt:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)

	f.cursorTxt = f:CreateFontString(worldmapName.."CursorText", "OVERLAY", "NumberFontNormal")
	--f.cursorTxt:SetPoint("TOPLEFT", f.playerTxt, "TOPRIGHT", 20, 0)

	f:SetScript("OnUpdate", onUpdate)

	return f
end

function addon:OnInitialize()
	self.db = AceDB:New(addon.Name.."DB", addon.constants.defaults, true)
	profile = self.db.profile
	
	if profile and profile.point then profile.point = nil end

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	self:SetupOptions()
end

function addon:OnEnable()
	setupCoordsTrackingFrame()
	self.WorldMapFrame = createCoordsOnWorldMapFrame()

	-- Register events
	for key, value in pairs( addon.constants.events ) do
		self:RegisterEvent( value )
	end

	setupLDB()
	if (profile.show_zonename and locationText == "") then
		getLocationText()
	end
	self:Refresh()
end

function addon:Refresh()
	profile = self.db.profile
	
	onscreenFrameStatusRefresh()
	CoordsOnWorldMapFrameRefresh()
	addon:SetOnScreenFontStyle()
	addon:SetWorldMapFontStyle()
	if (profile and profile.show_coords_onworldmap) then
		self.WorldMapFrame:Show()
	else
		self.WorldMapFrame:Hide()
	end
	addon:SetOnScreenBackground()
end

function addon:PLAYER_REGEN_DISABLED()
	isInLockdown = true
end

function addon:PLAYER_REGEN_ENABLED()
	isInLockdown = false
end

function addon:ZONE_CHANGED()
	if (profile.show_zonename) then getLocationText() end
end

function addon:ZONE_CHANGED_NEW()
	if (profile.show_zonename) then getLocationText() end
end

function addon:ZONE_CHANGED_NEW_AREA()
	if (profile.show_zonename) then getLocationText() end
end

function addon:ZONE_CHANGED_INDOORS()
	if (profile.show_zonename) then getLocationText() end
end
