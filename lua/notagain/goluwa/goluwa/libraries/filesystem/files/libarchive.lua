local archive = desire("archive")

if not archive then return end

local vfs = (...) or _G.vfs
local ffi = require("ffi")

local function iterate_archive(a)
	local entry = archive.EntryNew()
	local tbl = {}

	while archive.ReadNextHeader2(a, entry) == archive.e.OK do
		table.insert(tbl, ffi.string(archive.EntryPathname(entry)))
	end

	archive.EntryFree(entry)

	return tbl
end

local CONTEXT = {}

CONTEXT.Name = "libarchive"
CONTEXT.Position = math.huge

local function open_archive(path_info)

	local archive_path, relative

	if path_info.full_path:find("tar.gz", nil, true) then
		archive_path, relative = path_info.full_path:match("(.+%.tar%.gz)/(.*)")
	else
		archive_path, relative = path_info.full_path:match("(.+%..-)/(.*)")
	end

	if not archive_path and not relative then
		return false, "not a valid archive path"
	end

	if archive_path:endswith("/") then
		archive_path = archive_path:sub(0, -2)
	end

	if archive_path:endswith(".gma") then
		return false, "gma TODO"
	end

	local str = vfs.Read("os:" .. archive_path)
	if not str then return false, "archive is empty" end

	local a = archive.ReadNew()

	archive.ReadSupportCompressionAll(a)
	archive.ReadSupportFilterAll(a)
	archive.ReadSupportFormatAll(a)

	if archive.ReadOpenMemory(a, str, #str) ~= archive.e.OK then
		local err = archive.ErrorString(a)

		if err ~= nil then
			local err = ffi.string(err)
			archive.ReadFree(a)
			return false, err
		end

		archive.ReadFree(a)
		return false, "archive.ReadOpenMemory failed"
	end

	return a, relative, str
end

function CONTEXT:IsFile(path_info)
	local a, relative, ref = open_archive(path_info)
	if not a then return a, relative end

	local found = false
	for _, path in ipairs(iterate_archive(a)) do
		if path == relative then
			found = true
			break
		end
	end

	archive.ReadFree(a)
	ref = nil

	return found
end

function CONTEXT:IsFolder(path_info)
	local a, relative, ref = open_archive(path_info)
	if not a then return a, relative end

	local found = false

	for _, path in ipairs(iterate_archive(a)) do
		if path:startswith(relative) then
			found = true
			break
		end
	end

	archive.ReadFree(a)
	ref = nil

	return found
end

function CONTEXT:GetFiles(path_info)
	local a, relative, ref = open_archive(path_info)
	if not a then return a, relative end

	local out = {}

	local dir = relative:match("(.*/).*")

	local files = {}
	local done = {}

	for _, path in ipairs(iterate_archive(a)) do
		for i = #path, 1, -1 do
			local char = path:sub(i, i)
			if char == "/" then
				local dir = path:sub(0, i)

				if not done[dir] then
					done[dir] = true
					if dir ~= "" then
						table.insert(files, dir)
					end
				end
			end
		end
		table.insert(files, path)
	end

	archive.ReadFree(a)
	ref = nil

	-- really ugly logic: TODO
	-- this kind of logic messes up my head

	for _, path in ipairs(files) do
		if not dir then
			local path2 = path:match("^([^/]-)/$") or path:match("^([^/]-)$")
			if path2 then
				table.insert(out, path2)
			end
		else
			local dir2, name = path:match("^(.+/)(.+)")

			if dir == dir2 and name then
				if name:endswith("/") then
					name = name:sub(0, -2)
				end
				table.insert(out, name)
			end
		end
	end

	return out
end

function CONTEXT:Open(path_info, mode, ...)
	if self:GetMode() == "read" then
		local a, relative, ref = open_archive(path_info)
		if not a then return false, relative end

		while true do
			local entry = archive.EntryNew()
			if archive.ReadNextHeader2(a, entry) == archive.e.OK then
				local path = ffi.string(archive.EntryPathname(entry))
				if path == relative then
					self.archive = a
					self.entry = entry
					self.ref = ref

					if archive.SeekData(self.archive, 0, 1) < 0 then
						self.content = self:ReadBytes(math.huge)
						if not self.content then
							return false, "unable to read content"
						end
						self.size = #self.content
						self.position = 0
					end

					return true
				end
			else
				archive.EntryFree(entry)
				break
			end
			archive.EntryFree(entry)
		end

		archive.ReadFree(a)

		return false, "file not found in archive"
	elseif self:GetMode() == "write" then
		return false, "write mode not implemented"
	end
	return false, "read mode " .. self:GetMode() .. " not supported"
end

function CONTEXT:ReadByte()
	if self.content then
		local char = self.content:sub(self.position+1, self.position+1)
		self.position = math.clamp(self.position + 1, 0, self.size)
		return char:byte()
	else
		local char = self:ReadBytes(1)
		if char then
			return char:byte()
		end
	end
end

function CONTEXT:ReadBytes(bytes)
	if bytes == math.huge then bytes = self:GetSize() end

	if self.content then
		local str = {}
		for i = 1, bytes do
			local byte = self:ReadByte()
			if not byte then break end
			str[i] = string.char(byte)
		end

		local out = table.concat(str, "")

		if out ~= "" then
			return out
		end
	else
		local data = ffi.new("uint8_t[?]", bytes)
		local size = archive.ReadData(self.archive, data, bytes)

		if size > 0 then
			return ffi.string(data, size)
		elseif size < 0 then
			if size ~= -30 then -- eof error
				local err = archive.ErrorString(self.archive)
				if err ~= nil then
					wlog(ffi.string(err))
				end
			end
		end
	end
end

function CONTEXT:SetPosition(pos)
	if self.content then
		self.position = math.clamp(pos, 0, self.size)
	else
		if archive.SeekData(self.archive, math.clamp(pos, 0, self:GetSize()), 0) ~= archive.e.OK then
			local err = archive.ErrorString(self.archive)
			if err ~= nil then
				wlog(ffi.string(err))
			end
		end
	end
end

function CONTEXT:GetPosition()
	if self.content then
		return self.position
	else
		local pos = archive.SeekData(self.archive, 0, 1)
		if pos < 0 then
			local err = archive.ErrorString(self.archive)
			if err ~= nil then
				wlog(ffi.string(err))
			end
			return pos
		end
		return pos
	end
end

function CONTEXT:OnRemove()
	if self.archive ~= nil then
		archive.ReadFree(self.archive)
	end

	if self.entry ~= nil then
		archive.EntryFree(self.entry)
	end
end

function CONTEXT:GetSize()
	return tonumber(archive.EntrySize(self.entry))
end

function CONTEXT:GetLastModified()
	return tonumber(archive.EntryAtime(self.entry))
end

vfs.RegisterFileSystem(CONTEXT)
if RELOAD then
	for _, path in pairs(vfs.Find("/media/caps/ssd_840_120gb/goluwa/data/users/caps/temp_bsp.zip/materials/maps/", nil, nil, nil, nil, true)) do
		print(path.name, "!")
		--local file = vfs.Open(path.full_path)
		--print(file:GetSize())
	end
end