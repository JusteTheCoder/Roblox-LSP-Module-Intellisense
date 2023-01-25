local fs = require("bee.filesystem")
local guide = require("core.guide")
local rbximports = require("core.module-import")
local fileuri = require("file-uri")

local SHARED_CONTEXT = 0
local CLIENT_CONTEXT = 1
local SERVER_CONTEXT = 2

local patterns = {
    '()local%s+[%w_]+%s=%srequire%("+([%w_]+)"%)',
    "()local%s+[%w_]+%s=%srequire%('+([%w_]+)'%)"
}

local function inferSourceContext(uri)
	-- Infer context from the script type
	if uri:match("%.server%.lua[u]?$") then
		return SERVER_CONTEXT
	elseif uri:match("%.client%.lua[u]?$") then
		return CLIENT_CONTEXT
	end

	-- Infer context from server/shared/client folder
	if string.find(string.lower(uri), "/client/", 1, true) then
		return CLIENT_CONTEXT
	elseif string.find(string.lower(uri), "/shared/", 1, true) then
		return SHARED_CONTEXT
	elseif string.find(string.lower(uri), "/server/", 1, true) then
		return SERVER_CONTEXT
	end

	return SHARED_CONTEXT
end

local function findLibrary(libraryName, context)
	local candidates = rbximports.findMatchingScripts(libraryName)
	local candidateContexts = {}

	-- Try returning the correct context first
	for _, candidate in ipairs(candidates) do
        local candidateUri = guide.getUri(candidate.object)
		local candidateContext = inferSourceContext(candidateUri)
		candidateContexts[candidate] = candidateContext

		if candidateContext == context then
			return candidateUri
		end
	end

	-- If in a shared context, try returning a client context
	-- If in a client or server context, try returning a shared context
	for _, candidate in ipairs(candidates) do
		local candidateContext = candidateContexts[candidate]
		if candidateContext == (context == SHARED_CONTEXT and CLIENT_CONTEXT or SHARED_CONTEXT) then
			return guide.getUri(candidate.object)
		end
	end

	-- Try returning any context
	if #candidates > 0 then
        local candidate = candidates[1]
		return candidate and guide.getUri(candidate.object)
	end
end

function OnSetText(uri, text)
	local diffs = {}
	for _, pattern in ipairs(patterns) do
		for start, path in text:gmatch(pattern) do
			if start == nil or path == nil then
				break
			end
			local library = findLibrary(path, inferSourceContext(uri))
			if library then
				local currentPath = fs.current_path()
				local libraryPath = fs.path(fileuri.decode(library))

				if libraryPath == nil or currentPath == nil then
					break
				end

				local relativePath = fs.relative(libraryPath, currentPath)
				local moduleLocation = tostring(relativePath):gsub("/", "."):gsub("%.lua$", "")

				table.insert(diffs, {
					start = start - 1,
					finish = start - 1,
					text = ("---@module %s\n"):format(moduleLocation)
				})
			end
		end
	end

	return diffs
end
