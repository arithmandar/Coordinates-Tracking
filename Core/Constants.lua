-- $Id: Constants.lua 24 2017-05-24 14:29:40Z arith $
-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
-- Functions
local _G = getfenv(0)
-- Libraries

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local FOLDER_NAME, private = ...
private.addon_name = "CoordsTracking"

local LibStub = _G.LibStub

local constants = {}
private.constants = constants

constants.defaults = {
	profile = {
		show_coords_onscreen = true,
		show_zonename = true,
		show_zonenametooltip = true,
		show_coords_onworldmap = true,
		show_indungeon = false,
		coords_accuracy = 1,
		worldmap_accuracy = 2,
		point = { "TOPLEFT", "UIParent", "TOPLEFT", 450, -80 },
		wmPoint = {
			point = "BOTTOMRIGHT",
			relativePoint = "BOTTOMRIGHT",
			ofsx = 40,
			ofsy = 0,
		},
		alpha = 1,
		scale = 1,
		tooltip_alpha = 0.9,
		tooltip_scale = 1,
		font_onscreen = (GetLocale() == "ruRU") and "Arial Narrow" or "Friz Quadrata TT",
		fontsize_onscreen = 14,
		fontoutline_onscreen = true,
		font_worldmap = (GetLocale() == "ruRU") and "Arial Narrow" or "Friz Quadrata TT",
		fontsize_worldmap = 14,
		fontoutline_worldmap = true,
		fontcolor_worldmap = { r = 1, g = 1, b = 1 },
		backgroundColor = { r = 0, g = 0, b = 0, a = 1},
		background = "",
	},
}

constants.events = {
	"PLAYER_REGEN_ENABLED",
	"PLAYER_REGEN_DISABLED",
	"ZONE_CHANGED",
	"ZONE_CHANGED_NEW_AREA",
	"ZONE_CHANGED_INDOORS",
}
