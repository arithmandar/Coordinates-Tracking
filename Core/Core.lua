-- $Id$
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
local pairs = _G.pairs
local string = _G.string
local select = _G.select
-- Libraries
local GameTooltip = GameTooltip
local format = string.format

local GetCursorPosition = GetCursorPosition
local GetPlayerMapPosition = C_Map.GetPlayerMapPosition
local WorldMapScrollChild = WorldMapFrame.ScrollContainer.Child

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
});
local Media = LibStub("LibSharedMedia-3.0")

local addon = LibStub("AceAddon-3.0"):NewAddon(private.addon_name, "AceEvent-3.0")
addon.constants = private.constants
addon.constants.addon_name = private.addon_name
addon.Name = FOLDER_NAME
addon.LocName = select(2, GetAddOnInfo(addon.Name))
addon.Notes = select(3, GetAddOnInfo(addon.Name))
_G.CoordsTracking = addon
local profile

CRDS_Player = UnitName("player")
CRDS_Server = GetRealmName()

local isInLockdown = false
local CRDS_ORIG_GAMPTOOLTIP_SCALE = GameTooltip:GetScale()
local CRDS_POSTEXT = nil

local function CRDS_GetZoneText()
	local posText;
	if (GetSubZoneText() == "") then
		posText = GetZoneText()
	else
		posText = format("%s - %s", GetZoneText(), GetSubZoneText())
	end
	return posText
end

-- Codes adopted from Mapster
local function CRDS_GetCursorPosition()
	local left, top = WorldMapScrollChild:GetLeft() or 0, WorldMapScrollChild:GetTop() or 0
	local width, height = WorldMapScrollChild:GetWidth(), WorldMapScrollChild:GetHeight()
	local scale = WorldMapScrollChild:GetEffectiveScale()

	local x, y = GetCursorPosition()
	local cx = (x/scale - left) / width
	local cy = (top - y/scale) / height

	if (cx < 0 or cx > 1 or cy < 0 or cy > 1) then
		return
	end

	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local crdsText, posText
	local acc = profile.worldmap_accuracy
	
	crdsText = crdsTextTemplate:format(acc, acc)
	
	-- SetMapToCurrentZone(); -- this should not be called
	--posX, posY = GetPlayerMapPosition("player")
	
	posText = format(crdsText, cx*100, cy*100)
	
	return posText
end

local function CRDS_GetPlayerPositionText(worldMap)
	local posText, crdsText, posX, posY
	local crdsTextTemplate = "%%.%df"..L["COMMA"].."%%.%df"
	local acc = worldMap and profile.worldmap_accuracy or profile.coords_accuracy
	
	--local posXY = C_Map.GetPlayerMapPosition(WorldMapFrame:GetMapID(), "player")
	local posXY = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
	
	crdsText = crdsTextTemplate:format(acc, acc)
	
	-- SetMapToCurrentZone()
	if ( IsInInstance() ) then
		posX = 0
		posY = 0
	elseif (posXY) then
		posX, posY = posXY:GetXY()
	end
	
	posText = format(crdsText, posX and posX*100 or 0, posY and posY*100 or 0)
	
	return posText
end

local function CRDS_GetButtonText()
	local posText = CRDS_GetPlayerPositionText()

	if (posText) then 
		if (profile.show_zonename) then
			if ( IsInInstance() ) then 
				posText = CRDS_GetZoneText()
			else
				posText = format("%s"..L["COLON"]..posText, CRDS_GetZoneText())
			end
		else
			--posText = "|cffffffff"..posText
		end
	else
		posText = L["TITLE"]
	end

	return posText
end

--[[
local function CRDS_UpdateOptions(player_options)
	for k, v in pairs(CRDS_DefaultOptions) do
		if (player_options[k] == nil) then
			player_options[k] = v;
		end
	end
end

local function CRDS_InitOptions()
	if ( CoordsTrackingDB == nil ) then
		CoordsTrackingDB = { };
	end
	if ( CoordsTrackingDB[CRDS_Server] == nil ) then
		CoordsTrackingDB[CRDS_Server] = { };
	end
	if ( CoordsTrackingDB[CRDS_Server][CRDS_Player] == nil ) then
		CoordsTrackingDB[CRDS_Server][CRDS_Player] = { };
	end
	if ( CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"] == nil ) then
		CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"] = CRDS_DefaultOptions;
	end
	
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];
	CRDS_UpdateOptions(options);
end

local function CRDS_Init()
	CRDS_InitOptions();
	local options = CoordsTrackingDB[CRDS_Server][CRDS_Player]["options"];

	if(options.show_coords_onscreen == true) then
		CoordsTrackingFrame:Show();
		CoordsTrackingFrame:SetAlpha(options.alpha);
		CoordsTrackingFrame:SetScale(options.scale);
	else
		CoordsTrackingFrame:Hide();
	end
end

function CRDS_OnLoad(self)
	-- Register the CoordsTracking frame for the following events
        for key, value in pairs( CRDS_Events ) do
            self:RegisterEvent( value );
        end

	self:RegisterForDrag("LeftButton");
end

function CRDS_OnEvent(self, event, ...)
	local arg1 = ...;
	if (event == "ADDON_LOADED" and arg1 == "CoordsTracking") then
		CRDS_Init();
	end
	-- for combact lockdown
	if (event == "PLAYER_REGEN_DISABLED") then
		isInLockdown = true;
	elseif (event == "PLAYER_REGEN_ENABLED") then
		isInLockdown = false;
	end
	
	--LDB.text = CRDS_GetButtonText();
end
]]
function CRDS_OnUpdate()
	local posText = CRDS_GetButtonText();
	if (posText ~= CRDS_POSTEXT) then
		local pvpType = GetZonePVPInfo();
		local color = {};

		if ( pvpType == "sanctuary" ) then
			color = {r=0.41, g=0.8, b=0.94};
		elseif ( pvpType == "arena" ) then
			color = {r=1.0, g=0.1, b=0.1};
		elseif ( pvpType == "friendly" ) then
			color = {r=0.1, g=1.0, b=0.1};
		elseif ( pvpType == "hostile" ) then
			color = {r=1.0, g=0.1, b=0.1};
		elseif ( pvpType == "contested" ) then
			color = {r=1.0, g=0.7, b=0.0};
		else
			color = {r=HIGHLIGHT_FONT_COLOR.r, g=HIGHLIGHT_FONT_COLOR.g, b=HIGHLIGHT_FONT_COLOR.b};
		end

		local colortag = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255);

		if (CoordsTrackingFrame:IsShown()) then
			CoordsTrackingFrame.Text:SetText(posText);
			CoordsTrackingFrame:SetWidth(CoordsTrackingFrame.Text:GetStringWidth());
			CoordsTrackingFrame.Text:SetTextColor(color.r, color.g, color.b);
		end

		LDB.text = colortag..posText..FONT_COLOR_CODE_CLOSE;
		CRDS_POSTEXT = posText;
	end

	if (profile.show_coords_onworldmap) then
		CoordsOnWorldMapFramePlayerText:SetText(UnitName("player")..L["COLON"]..CRDS_GetPlayerPositionText(true));
		local cursorPos = CRDS_GetCursorPosition();
		if (cursorPos) then
			CoordsOnWorldMapFrameCursorText:SetText(L["Cursor"]..L["COLON"]..cursorPos);
		else
			CoordsOnWorldMapFrameCursorText:SetText("");
		end
	end
end

function CRDS_OnShow()
	CRDS_POSTEXT = nil;
end

function CRDS_OnMouseDown(self, buttonName)    
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

function CRDS_OnMouseUp(self, buttonName)
	if(CoordsTrackingFrame:IsVisible()) then
		CoordsTrackingFrame:StopMovingOrSizing()
		local a, b, c, d, e = CoordsTrackingFrame:GetPoint()
		profile.point = { a, b, c, d, e }
	end
end

local function get_zonename_tooltip(frame)
	if (not GameTooltip:IsShown()) then
		local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
		local zoneText = CRDS_GetZoneText()
		if frame then GameTooltip:SetOwner(frame, "ANCHOR_BOTTOM", -10, 0) end
		GameTooltip:SetBackdropColor(0, 0, 0, profile.tooltip_alpha)
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

function CRDS_OnEnter(self)
	if (isInLockdown) then
		return
	end

	if (profile.show_zonenametooltip) then
		if(CoordsTrackingFrame:IsVisible()) then
			get_zonename_tooltip(self)
		end
	end
end

function CRDS_OnLeave(self)
	GameTooltip_Hide();
	GameTooltip:SetScale(CRDS_ORIG_GAMPTOOLTIP_SCALE);
end

local function onscreenFrameStatusRefresh()
	local f = _G["CoordsTrackingFrame"]
	if (f and profile.show_coords_onscreen) then
		f:Show()
		f:SetAlpha(profile.alpha)
		f:SetScale(profile.scale)
		local point, relativeTo, relativePoint, ofsx, ofsy = unpack(profile.point)
		f:ClearAllPoints()
		f:SetParent("UIParent")
		f:SetPoint(point or "TOPLEFT", nil, relativePoint or "TOPLEFT", ofsx or 450, ofsy or -80)
	elseif (f) then
		f:Hide()
	end
end

local function setupLDB()
	-- setup LDB
	LDB.text = CRDS_GetButtonText()
	LDB.OnClick = (function(self, button) addon:OpenOptions() end)
	LDB.OnTooltipShow = (function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		if (profile.show_zonenametooltip) then
			get_zonename_tooltip()
		end
	end)
end

function addon:SetOnScreenFontStyle()
	local f = _G["CoordsTrackingFrame"]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_onscreen)
		f.Text:SetFont(newfont, profile.fontsize_onscreen, profile.fontoutline_onscreen and "OUTLINE" or nil)
	end
end

function addon:SetWorldMapFontStyle()
	local f = _G["CoordsOnWorldMapFrame"]
	if (f) then
		local newfont = Media:Fetch("font", profile.font_worldmap)
		f.playerTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
		f.cursorTxt:SetFont(newfont, profile.fontsize_worldmap, profile.fontoutline_worldmap and "OUTLINE" or nil)
	end
end

local function createCoordsOnWorldMapFrame()
	local f = _G["CoordsOnWorldMapFrame"]
	if not f then f = CreateFrame("Frame", "CoordsOnWorldMapFrame", WorldMapFrame.ScrollContainer) end
	
	--f:SetFrameLevel(WorldMapFrame.UIElementsFrame:GetFrameLevel() + 20)
	f.playerTxt = f:CreateFontString("CoordsOnWorldMapFramePlayerText", "OVERLAY", "NumberFontNormal")
	f.playerTxt:SetPoint("TOPLEFT", WorldMapFrame.ScrollContainer, "BOTTOM", -10, 20)
	f.cursorTxt = f:CreateFontString("CoordsOnWorldMapFrameCursorText", "OVERLAY", "NumberFontNormal")
	f.cursorTxt:SetPoint("TOPLEFT", f.playerTxt, "TOPRIGHT", 20, 0)
end

function addon:OnInitialize()
	self.db = AceDB:New(addon.Name.."DB", addon.constants.defaults, true)
	profile = self.db.profile

	self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
	self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
	self.db.RegisterCallback(self, "OnProfileReset", "Refresh")

	self:SetupOptions()
	createCoordsOnWorldMapFrame()

end

function addon:OnEnable()
	for key, value in pairs( addon.constants.events ) do
		self:RegisterEvent( value )
	end

	setupLDB()
	self:Refresh()
end

function addon:Refresh()
	profile = self.db.profile
	
	onscreenFrameStatusRefresh()
	addon:SetOnScreenFontStyle()
	addon:SetWorldMapFontStyle()
	if (profile.show_coords_onworldmap) then
		CoordsOnWorldMapFrame:Show();
	else
		CoordsOnWorldMapFrame:Hide();
	end
end

function addon:PLAYER_REGEN_DISABLED()
	isInLockdown = true
end

function addon:PLAYER_REGEN_ENABLED()
	isInLockdown = false
end
