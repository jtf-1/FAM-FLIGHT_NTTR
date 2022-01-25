-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Mission script dynamic loader
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local base = _G
local __filepath = 'E:/GitHub/FAM-FLIGHT_NTTR/scripts/dynamic/'

__Loader = {}

__Loader.Include = function( IncludeFile )
	if not __Loader.Includes[IncludeFile] then
		__Loader.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( __filepath .. IncludeFile ) )
		if f == nil then
			error ("Mission Loader: could not load mission file " .. IncludeFile )
		else
			env.info( "Mission Loader: " .. IncludeFile .. " dynamically loaded." )
			return f()
		end
	end
end

__Loader.Includes = {}

__Loader.Include( 'mission_files.lua' ) -- "E:\GitHub\FUN-MAP_NTTR\scripts\dynamic\mission_files.lua"

--- End mission script dynamic loader