-- $Id$

local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local L = AceLocale:NewLocale("CoordsTracking", "enUS", true, true);

if L then
	L["TITLE"] = "Coordinates Tracking";
	L["ADDON_NOTES"] = "Tracks on your current coordinates and shows in on the screen and world map.";
	L["Options"] = "Options";
	L["OPT_ShowOnScreen"] = "Show coordinates info on screen";
	L["OPT_ShowZoneName"] = "Show zone name together with coordinates";
	L["OPT_ShowZoneNameTooltip"] = "Show zone name as tooltip on coordinates when mouse hover";
	L["OPT_ShowOnWorldMap"] = "Show coordinates info on world map";
	L["OPT_BTN_Reset"] = "Reset position";
	L["OPT_ACCURACY"] = "Coordinates' accuracy";
	L["OPT_TRANSPARENCY"] = "Coordinates info's transparency";
	L["OPT_SCALE"] = "Coordinates info's scale";
	L["OPT_TOOLTIPTRANSPARENCY"] = "Coordinates info tooltip's transparency";
	L["OPT_TOOLTIPSCALE"] = "Coordinates info tooltip's scale";
	L["COLON"] = ": ";
	L["CURSOR"] = "Cursor";
end