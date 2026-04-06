-- Shared utilities for BreakSync

local addonName, BS = ...

function BS.Debug(...)
    if BreakSyncDB and BreakSyncDB.debug then
        print("|cff888888[BreakSync Debug]|r", ...)
    end
end
