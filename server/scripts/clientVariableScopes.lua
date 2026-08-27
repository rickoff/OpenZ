-- Place clientside variables in different categories to decide how they are synchronized,
-- saved and loaded
--
-- Note: Currently, only global variables are handled, not local or member variables
--
-- Descriptions:
-- * "ignored" is where you place variables that clients should not send packets about,
--   either because they are already handled in other packets or because they would cause
--   unnecessary packet spam
-- * "personal" is where you place variables that are always exclusive to specific players
--   and that should not be shared regardless of other server options
-- * "quest" is where you place variables that should be synchronized and shared across
--   players based on the value of config.shareJournal
-- * "kills" is where you place variables that should be handled the same as kill counts
--   and should be cleared whenever the regular kill counts are
-- * "factionRanks" is where you place variables that should be synchronized and shared across
--   players based on the value of config.shareFactionRanks
-- * "factionExpulsion" is where you place variables that should be synchronized and shared across
--   players based on the value of config.shareFactionExpulsion
-- * "worldwide" is where you place variables that are always shared across all players
--   because they affect the physical world in a way that should be visible to everyone,
--   i.e. they affect structures, mechanism states, water levels, and so on
local clientVariableScopes = {
    globals = {}
}

if tableHelper.containsCaseInsensitiveString(clientDataFiles, "OPENZ.omwaddon") then

    local addedVariableScopes = {
        globals = {
            ignored = {	
                "gamehour", "timescale", "month", "day", "year", "chargenstate", "pchascrimegold", "crimegolddiscount", "crimegoldturnin", "pchasgolddiscount",
                "pchasturnin"
            },
            personal = {
				"hunger", "thirsty", "tired", "mounthorse", "mountcar", "mountairplane", "rescuenpc"			
            },
            quest = {},
            kills = {},
            factionRanks = {},
            factionExpulsion = {},
            worldwide = {},
            unknown = {}
        }
    }

    tableHelper.merge(clientVariableScopes, addedVariableScopes, true)
end

return clientVariableScopes