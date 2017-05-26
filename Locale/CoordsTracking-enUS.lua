-- $Id$

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("CoordsTracking", "enUS", true, true)

if L then
--@do-not-package@
-- General
L["TITLE"] = "Coordinates Tracking"
L["ADDON_NOTES"] = "Tracks on your current coordinates and shows in on the screen and world map."
L["COLON"] = ": "
L["COMMA"] = ", "
L["Cursor"] = "Cursor"
-- Options Header
L["Display Settings"] = "Display Settings"
L["Font Settings"] = "Font Settings"
L["Scale and Transparency"] = "Scale and Transparency"
-- Options
L["Options"] = "Options"
L["Show coordinates info on screen"] = "Show coordinates info on screen"
L["Show zone name together with coordinates"] = "Show zone name together with coordinates"
L["Show zone name as tooltip on coordinates when mouse hover"] = "Show zone name as tooltip on coordinates when mouse hover"
L["Show coordinates info on world map"] = "Show coordinates info on world map"
L["Reset position"] = "Reset position"
L["Setup font style for on-screen frame"] = "Setup font style for on-screen frame"
L["Setup font style for coordinates on WorldMap frame"] = "Setup font style for coordinates on WorldMap frame"
L["Select font"] = "Select font"
L["Configure font size"] = "Configure font size"
L["Show outline"] = "Show outline"
L["Accuracy"] = "Accuracy"
L["Coordinates' accuracy"] = "Coordinates' accuracy"
L["Coordinates' accuracy on WorldMap Frame"] = "Coordinates' accuracy on WorldMap Frame"
L["On-screen frame"] = "On-screen frame"
L["Coordinates info's transparency"] = "Coordinates info's transparency"
L["Coordinates info's scale"] = "Coordinates info's scale"
L["Tooltip"] = "Tooltip"
L["Coordinates info tooltip's transparency"] = "Coordinates info tooltip's transparency"
L["Coordinates info tooltip's scale"] = "Coordinates info tooltip's scale"
L["Profile Options"] = "Profile Options"
--@end-do-not-package@
--@localization(locale="enUS", format="lua_additive_table")@
end