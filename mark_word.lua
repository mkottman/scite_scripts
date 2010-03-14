-- mark_word.lua - extman-based extension for Scite, that marks all occurences of doubleclicked word
--
-- This extension adds 'mark all occurences' feature to Scite. When a word is doubleclicked, every
-- occurence of the word in current file is highlighted using a transparent rectangle. The highlight
-- is kept until any key is pressed.
--
-- Michal Kottman (c) 2010, MIT License


-- retrieve current word at cursor position
local function currentWord()
	local s = editor:WordStartPosition(editor.CurrentPos, true)
	local e = editor:WordEndPosition(editor.CurrentPos, true)
	local word = editor:textrange(s, e)
	return word
end

-- trim whitespace
local function trim(s)
  return s:match "^%s*(.-)%s*$"
end

local last
local id

-- initialize extension
local function init()
	if id then return end
	-- random user indicator id (>8)
	id = 11
	-- transparent rectangle
	editor.IndicStyle[id] = 7
	-- light blue color - change if you like
	editor.IndicFore[id] = colour_parse'#8080FF'
end

-- entry point for doubleclick
local function doSelectMark()
	init()
	local word = trim(currentWord())
	if word ~= "" then
		-- move cursor to lose default highlighted text
		-- if you want to keep the marking highlight, comment next line
		editor:CharLeft(); editor:CharRight()
		
		last = {}
		for m in editor:match(word) do
			editor.IndicatorCurrent = id
			editor.IndicatorValue = 1
			editor:IndicatorFillRange(m.pos, m.len)
			-- make a copy so that it can be cleared later
			table.insert(last, {pos=m.pos, len=m.len})
		end
	end
end

-- clear all marks
local function clear()
	if not last then return end
	for _,m in ipairs(last) do
		editor.IndicatorCurrent = id
		editor.IndicatorValue = 1
		editor:IndicatorClearRange(m.pos, m.len)
	end
	last = nil
end

-- register callbacks
scite_OnDoubleClick(doSelectMark)
scite_OnKey(clear)