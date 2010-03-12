-- gitdiff.lua - extman-based extension for Scite, that marks modified lines in a git-tracked file
--
-- Lines, that are modified in a file in working directory, are highlighted in the margin using pink
-- color. Only added/modified lines are marked, if you find a way to mark deleted lines, please
-- tell me :)
--
-- Michal Kottman (c) 2010, MIT License

local dir
local diffmark

-- "quiet" debugger - outputs to localhost:5555 if anyone is listening
pcall(require, 'socket')
if socket then
	local _,s = pcall(socket.connect, 'localhost', 5555)
	function dbg(...)
		if not s then return end
		local n = select('#', ...)
		local t = {...}
		for i=1,n do
			t[i] = tostring(t[i])
		end
		s:send(table.concat(t, '\t')..'\n')
	end
else
	function dbg() end
end

-- initialize marker
function init_diff()
	if diffmark then return end
	diffmark = MarkerType(22,SC_MARK_FULLRECT,nil,'#FFAAAA')
end

-- spawn a process in current directory
function git_command(cmd)
	dbg('git '.. cmd)
	return scite_Popen("cd '"..dir.."' && git "..cmd.." 2>&1")
end

-- check if current file is tracked by git
function check_git()
	local p = git_command "status"
	local line = p:read('*l')
	p:close()
	local res = line and not line:match("Not a git repository")
	return res
end

-- callback that marks changed lines
function diff_markers()
	init_diff()
	local file = scite_CurrentFile()
	dir = path_of(file)
	if check_git() then
		dbg('Working on', file, 'in', dir)
		local diff = git_command("diff "..file)
		local line = diff:read()
		while line do
			while not line:match"^@@" do line = diff:read() end
			dbg(line)
			
			-- retrieve starting line number from unified diff
			local old, new = line:match('@@ %-(.-) %+(.-) @@')
			local ln = tonumber(new:match('(%d+),%d+'))
			if not ln then dbg('NOT MATCHED!', line, new) end
			
			-- loop through hunk lines to find which lines are added
			line = diff:read()
			local c = line:sub(1,1)
			dbg(ln, c, line)
			while line and (c == " " or c == "+" or c == "-") do
				-- only mark added lines
				if c == "+" then
					diffmark:create(ln)
				else
					editor:MarkerDelete(ln, 22)
				end
				-- removed lines cannot be displayed
				if c == " " or c == "+" then
					ln = ln + 1
				end
				line = diff:read()
				if line then c = line:sub(1,1) end
				dbg(ln, c, line)
			end
		end
		diff:close()
	end
end

-- register callbacks
scite_OnSave(diff_markers)
scite_OnOpen(diff_markers)
scite_OnSwitchFile(diff_markers)


