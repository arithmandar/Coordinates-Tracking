---@meta _
-- ----------------------------------------------------------------------------
-- LuaLS type definitions for Coordinates Tracking.
--
-- This file is for the Lua Language Server (e.g. the "WoW API" VS Code
-- extension) only. It is NOT listed in the .toc, so the game client never
-- loads it, and it is excluded from packaged builds via .pkgmeta.
--
-- Nothing in here exists at runtime. Do not reference these "locals" from
-- addon code; they only exist so LuaLS can attach methods/fields to classes.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Globals that are not (or not always) covered by the WoW API annotations.
-- ----------------------------------------------------------------------------

---Project ID of the WoW Classic "Forever" client. Only defined on that client.
---@type integer?
WOW_PROJECT_CAMELOT = nil

---Legacy (pre-Dragonflight) Interface Options API. Only present on some Classic clients.
---@type (fun(panel: Frame|string))?
InterfaceOptionsFrame_OpenToCategory = nil

---Legacy (pre-Dragonflight) Interface Options frame. Only present on some Classic clients.
---@type Frame?
InterfaceOptionsFrame = nil

---Dropdown value lists provided by AceGUI-3.0-SharedMediaWidgets, keyed by media type.
---@type table<string, table<string, string>>
AceGUIWidgetLSMlists = {}

-- ----------------------------------------------------------------------------
-- Blizzard frames/fields not covered by the WoW API annotations.
-- ----------------------------------------------------------------------------

---A NineSlicePanelTemplate frame (Blizzard NineSlicePanelMixin).
---@class CoordinatesTrackingNineSlicePanel : Frame
local CoordinatesTrackingNineSlicePanel = {}

---@param r number
---@param g number
---@param b number
---@param a number?
function CoordinatesTrackingNineSlicePanel:SetCenterColor(r, g, b, a) end

---@return number r
---@return number g
---@return number b
---@return number a
function CoordinatesTrackingNineSlicePanel:GetCenterColor() end

---GameTooltip inherits SharedTooltipArtTemplate on Retail and Classic, which draws
---its background with a NineSlice child instead of BackdropTemplate.
---@class GameTooltip
---@field NineSlice CoordinatesTrackingNineSlicePanel?

-- ----------------------------------------------------------------------------
-- Client detection (Core/Constants.lua)
-- ----------------------------------------------------------------------------

---@class CoordinatesTrackingClient
---@field projectID integer? Value of WOW_PROJECT_ID.
---@field isRetail boolean Mainline / Retail.
---@field isClassicEra boolean Classic Era (incl. Hardcore / Season of Discovery).
---@field isTBCClassic boolean Burning Crusade Classic.
---@field isCataclysmClassic boolean Cataclysm Classic.
---@field isMistsClassic boolean Mists of Pandaria Classic.
---@field isForever boolean WoW Classic "Forever" (WOW_PROJECT_CAMELOT).
---@field isProgressionClassic boolean Cataclysm or Mists Classic.
---@field isAnyClassic boolean Any Classic flavor except Forever.
---@field isKnownProject boolean True when WOW_PROJECT_ID matches one of the above.

-- ----------------------------------------------------------------------------
-- SavedVariables (CoordsTrackingDB)
-- ----------------------------------------------------------------------------

---On-screen frame anchor, stored as `{ point, relativePoint, offsetX, offsetY }`.
---The relative frame is always UIParent.
---@alias CoordinatesTrackingAnchor [FramePoint, FramePoint, number, number]

---@class CoordinatesTrackingWorldMapAnchor
---@field point FramePoint
---@field relativePoint FramePoint
---@field ofsx number Horizontal offset; mirrored for right-aligned points.
---@field ofsy number Vertical offset; mirrored for top-aligned points.

---@class CoordinatesTrackingProfile
---@field show_coords_onscreen boolean
---@field show_zonename boolean
---@field show_zonenametooltip boolean
---@field show_coords_onworldmap boolean
---@field show_indungeon boolean
---@field coords_accuracy integer Decimal places for the on-screen coordinates.
---@field worldmap_accuracy integer Decimal places for the World Map coordinates.
---@field latestpoint CoordinatesTrackingAnchor
---@field wmPoint CoordinatesTrackingWorldMapAnchor
---@field alpha number
---@field scale number
---@field tooltip_alpha number
---@field tooltip_scale number
---@field font_onscreen string LibSharedMedia font name.
---@field fontsize_onscreen number
---@field fontoutline_onscreen boolean
---@field font_worldmap string LibSharedMedia font name.
---@field fontsize_worldmap number
---@field fontoutline_worldmap boolean
---@field fontcolor_worldmap ColorRGBData
---@field backgroundColor ColorRGBAData
---@field background string? Texture path resolved from LibSharedMedia ("" for none).
---@field point nil Obsolete; cleared in OnInitialize.

---@class CoordinatesTrackingDefaults : AceDB.Schema
---@field profile CoordinatesTrackingProfile

---@class CoordinatesTrackingDB : AceDBObject-3.0
---@field profile CoordinatesTrackingProfile

-- ----------------------------------------------------------------------------
-- Addon namespace (the second vararg of every addon file)
-- ----------------------------------------------------------------------------

---@class CoordinatesTrackingConstants
---@field addon_name string
---@field defaults CoordinatesTrackingDefaults
---@field events WowEvent[] Events registered in OnEnable.

---@class CoordinatesTrackingPrivate
---@field addon_name string
---@field constants CoordinatesTrackingConstants
---@field Client CoordinatesTrackingClient

-- ----------------------------------------------------------------------------
-- Frames
-- ----------------------------------------------------------------------------

---The draggable on-screen coordinates frame ("CoordsTrackingFrame").
---The addon object itself is this frame (see NewAddon in Core.lua).
---@class CoordinatesTrackingOnScreenFrame : Frame, BackdropTemplate
---@field Text FontString
---@field Background Texture
---@field Border Frame|BackdropTemplate

---The World Map overlay frame ("CoordsOnWorldMapFrame").
---@class CoordinatesTrackingWorldMapFrame : Frame, BackdropTemplate
---@field playerTxt FontString
---@field cursorTxt FontString

-- ----------------------------------------------------------------------------
-- Addon object
-- ----------------------------------------------------------------------------

---Options table, or a function returning one (AceConfig accepts either).
---@alias CoordinatesTrackingOptionsTable table|fun(): table

---@class CoordinatesTrackingAddon : AceAddon, AceEvent-3.0, CoordinatesTrackingOnScreenFrame
---@field db CoordinatesTrackingDB
---@field constants CoordinatesTrackingConstants
---@field WorldMapFrame CoordinatesTrackingWorldMapFrame
---@field optionsFrames table<string, any> Settings category IDs, keyed by "General", "Profiles", ...
---@field optionsFrameRefs table<string, Frame> Settings panel frames, keyed like optionsFrames.
---@field Name string Addon folder name.
---@field LocName string Localized title from the .toc.
---@field Notes string Localized notes from the .toc.
---@field Version string
---@field UpdateDate string
---@field Author string
local CoordinatesTrackingAddon = {}

-- Core/Core.lua -------------------------------------------------------------

---AceAddon callback: creates the database and registers the options.
function CoordinatesTrackingAddon:OnInitialize() end

---AceAddon callback: creates the frames, registers events and refreshes the UI.
function CoordinatesTrackingAddon:OnEnable() end

---Re-applies the whole profile to both frames. Also used as the AceDB profile callback.
function CoordinatesTrackingAddon:Refresh() end

function CoordinatesTrackingAddon:SetOnScreenFontStyle() end
function CoordinatesTrackingAddon:SetOnScreenBackground() end
function CoordinatesTrackingAddon:SetWorldMapFontStyle() end
function CoordinatesTrackingAddon:SetWorldMapFontColor() end

function CoordinatesTrackingAddon:PLAYER_ENTERING_WORLD() end
function CoordinatesTrackingAddon:PLAYER_REGEN_DISABLED() end
function CoordinatesTrackingAddon:PLAYER_REGEN_ENABLED() end
function CoordinatesTrackingAddon:ZONE_CHANGED() end
function CoordinatesTrackingAddon:ZONE_CHANGED_NEW_AREA() end
function CoordinatesTrackingAddon:ZONE_CHANGED_INDOORS() end

-- Core/Config.lua -----------------------------------------------------------

---Opens the addon's page in the game settings.
function CoordinatesTrackingAddon:OpenOptions() end

---Registers the main options table and the Profiles sub-category.
function CoordinatesTrackingAddon:SetupOptions() end

---Adds a sub-category to the addon's settings page.
---@param name string Key of the sub-table in the main options table.
---@param optionTbl CoordinatesTrackingOptionsTable
---@param displayName string Name shown in the settings tree.
function CoordinatesTrackingAddon:RegisterModuleOptions(name, optionTbl, displayName) end
