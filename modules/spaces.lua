-- User-defined special workspaces. The pill's Workspaces surface rewrites this
-- file, so keep each entry on this shape. id is the special-workspace name, key
-- is a single Super-prefixed letter, apps are window classes that auto-route in.
--
-- The three built-in rows (stash, private, minimized) are seeded display-only:
-- their empty key keeps spaces-apply from re-binding keys that binds.lua already
-- owns (Super+A, Super+I, Super+Shift+H), and their empty apps list keeps the
-- routing in place under windowrules.lua.
return {
	{ id = "stash", name = "Stash", desc = "", key = "", glyph = "layers", apps = {} },
	{ id = "private", name = "Private", desc = "", key = "", glyph = "lock", apps = {} },
	{ id = "minimized", name = "Minimized", desc = "", key = "", glyph = "chevron-down", apps = {} },
}