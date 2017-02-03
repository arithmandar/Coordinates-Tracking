-- $Id$

local L = LibStub("AceLocale-3.0"):NewLocale("CoordsTracking", "zhTW", false)

if not L then return end

if L then
--@do-not-package@
	L["TITLE"] = "座標追蹤";
	L["ADDON_NOTES"] = "追蹤並顯示你目前所在位置的座標並顯示在遊戲畫面和世界地圖上";
	L["Options"] = "選項";
	L["OPT_ShowOnScreen"] = "在遊戲畫面上顯示座標資訊";
	L["OPT_ShowZoneName"] = "顯示座標時也顯示區域名稱";
	L["OPT_ShowZoneNameTooltip"] = "滑鼠移至座標資訊上面時顯示區域名稱提示訊息";
	L["OPT_ShowOnWorldMap"] = "在世界地圖上顯示座標資訊";
	L["OPT_BTN_Reset"] = "重置位置";
	L["OPT_ACCURACY"] = "座標資訊精確度";
	L["OPT_TRANSPARENCY"] = "座標資訊的透明度";
	L["OPT_SCALE"] = "座標資訊的大小比例";
	L["OPT_TOOLTIPTRANSPARENCY"] = "座標資訊提示的透明度";
	L["OPT_TOOLTIPSCALE"] = "座標資訊提示的大小比例";
	L["COLON"] = "：";
	L["CURSOR"] = "游標";
--@end-do-not-package@
--@localization(locale="zhTW", format="lua_additive_table")@
end