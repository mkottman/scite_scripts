-- xml_close_tag.lua - extman-based extension for Scite, that auto-closes XML tags.
--
-- When the user presses ">" in a XML-based file of supported extension, automatically
-- encloses the tag to the left of cursor, and positions cursor inside it. Also, quotes
-- any attributes after "=".
--
-- Inspired by http://lua-users.org/wiki/SciteXmlAutocompletion.
--
-- Michal Kottman (c) 2010, MIT License

-- supported extensions
local supported = {
    html = true,
    xhtml = true,
    xml = true,
    -- add more if necessary
}

-- Returns the tag by going back from the current cursor position until the
-- "<" character is found, in which case returns the whole tag (including
-- attributes), or the beginning of document, then it returns nil.
local function get_tag(pos)
    local endPos = pos - 1
    repeat
        pos = pos - 1
    until pos == 0 or char_at(pos) == "<"
    if pos == 0 then return end
    local startPos = pos + 1
    return editor:textrange(startPos, endPos)
end

-- Keeps only the tag name, strips any attributes.
local function tag_only(tag)
    local i, n = 1, #tag
    while i<=n and tag:sub(i,i) ~= " " do
        i = i+1
    end
    return tag:sub(1,i-1)
end

-- If the current file is an XML file, and the ">" character is pressed, then
-- encloses the tag to the left of cursor, and positions the cursor inside it.
local function try_xml(c)
    local ext = extension_of(scite_CurrentFile())
    if supported[ext] then
        if c == ">" then
            local pos = editor.CurrentPos
            local ch = char_at(pos-1)
            if ch ~= ">" then return end
            local tag = get_tag(pos)
            -- ignore closing/empty tags
            if tag and not tag:match('/') then
                editor:ReplaceSel('</'..tag_only(tag)..'>')
                editor:SetSel(pos, pos)
            end
        elseif c == "=" then
            local pos = editor.CurrentPos + 1
            editor:ReplaceSel('""')
            editor:SetSel(pos, pos)
        end
    end
end

scite_OnChar(try_xml)
