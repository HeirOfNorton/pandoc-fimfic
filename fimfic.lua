-- fimfic.lua
-- Author: Jason Seeley (HeirOfNorton)
--
-- Description:
--   This script is meant to be used as a custom writer for Pandoc.
--   The output is BBCODE format that is compatible with www.fimfiction.net
--
-- Usage example: pandoc [pandoc options] -t fimfic.lua input_file -o output_file
--
-- See README for more information and options for customization.



-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- This script has options that can be customized with the
-- input file's metadata, but the metadata is only available
-- to the script in the "Doc" function, after most of the
-- markup has already been converted. Most of the file is
-- given temporary markup using the unlikely character
-- sequence "{{! ... !}}" so that it can be easily replaced
-- with the correct markup in the "Doc" function once the
-- options are available.


-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).

function Str(s)
  return s
end

function Space()
  return " "
end

function LineBreak()
  return "\n"
end

function Emph(s)
  return "[i]" .. s .. "[/i]"
end

function Strong(s)
  return "[b]" .. s .. "[/b]"
end

-- Subscripts and Superscripts not supported by FimFiction
-- just pass text through, for now
function Subscript(s)
  return s
end

function Superscript(s)
  return s
end

function SmallCaps(s)
  return '[smcaps]' .. s .. '[/smcaps]'
end

function Strikeout(s)
  return '[s]' .. s .. '[/s]'
end

function Link(s, src, tit)
  return "[url=" .. src .. "]" .. s .. "[/url]"
end

function Image(s, src, tit)
  return "[img]" .. src .. "[/img]"
end

-- Verbatim text or "code" are not supported by FimFiction.
-- Just pass the text through unchanged.
function Code(s, attr)
  return s
end

-- FimFiction has no support for "math mode"
-- Just pass text through
function InlineMath(s)
  return s
end

function DisplayMath(s)
  return s
end

-- FimFiction does not have proper support for footnotes,
-- so we will fake it by inserting the text and markers
-- ourselves.
function Note(s)
  local num = #notes + 1
  table.insert(notes, s)
  -- return the footnote reference, linked to the note.
  return '(' .. num .. ')'
end

-- These are Unicode open and close quote characters.
-- Used with pandoc's -s option
function SingleQuoted(s)
  return "‘" .. s .. "’"
end

function DoubleQuoted(s)
  return "“" .. s .. "”"
end

-- FimFiction allows text to have size and color set,
-- which is not possible in MarkDown. As a workaround,
-- this will detect Spans that have relevent style
-- attributes set
function Span(s, attr)
  local text = s
  if attr["style"] then
      -- color
      _, _, color = attr["style"]:find("color%s*:%s*(.-)%s*;")
      if color then
          text = "[color=" .. color .. "]" .. text .. "[/color]"
      end
      
      --size
      local _, _, textsize = attr["style"]:find("size%s*:%s*(.-)%s*;")
      if textsize then
          text = "[size=" .. textsize .. "]" .. text .. "[/size]"
      end
  end
  return text
end

-- FimFiction has no support for Citations.
-- Just pass the text through
function Cite(s)
  return s
end

function Plain(s)
  return s
end

-- Add a placeholder before paragraphs, to support indenting
-- or not, and a placeholder at the end, to detect and
-- remove extra space between paragraphs when the user
-- chooses single-spacing.
function Para(s)
  return "{{!para!}}" .. s .. "{{!paraend!}}"
end

-- FimFiction has no concept of a Header.
-- Everything is a paragraph. There are options
-- that allow the user to customize how Headers are
-- output in the final document.
-- Attribute on Headers are currently ignored.
function Header(lev, s, attr)
  return "{{!h" .. lev .. "!" .. s .. "!}}"
end

function BlockQuote(s)
  return "[quote]" .. s .. "[/quote]"
end

function HorizontalRule()
  return "[hr]"
end

-- FimFiction does not have code blocks
function CodeBlock(s, attr)
  return s
end

-- FimFiction does not have proper list tags
-- For now, fake it with asterisks and numbers
-- (Later, I may allow customization)
function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "* " .. item )
  end
  return table.concat(buffer, "\n")
end

function OrderedList(items)
  local buffer = {}
  for num, item in pairs(items) do
    table.insert(buffer, num .. ". " .. item)
  end
  return table.concat(buffer, "\n")
end

function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"[b]" .. k .. ":[/b] " ..
                        table.concat(v,", "))
    end
  end
  return table.concat(buffer, "\n")
end

-- FimFiction does not have tables. For now I am
-- just doing tab-separated tables, until I can find
-- or adapt a better table-rendering function

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  if caption ~= "" then
    add("[center][b]" .. caption .. "[/b][/center]\n")
  end
  local header_row = {}
  local empty_header = true
  for i, h in pairs(headers) do
    table.insert(header_row, "[b]" .. h .. "[/b]")
    empty_header = empty_header and h == ""
  end
  if not empty_header then
    add(table.concat(header_row, "\t"))
  end
  for _, row in pairs(rows) do
    add(table.concat(row, "\t"))
  end
  return table.concat(buffer,'\n')
end

-- FimFiction has no concept of Divs or the possible
-- attribute they could have.
function Div(s, attr)
  return s
end

-- Finally, putting it all together.
function Doc(text, metadata, variables)
  local body = text

  -- Add Title block, if it exists
  if metadata["fimfic-title-block"] then
      local titleblock = metadata["fimfic-title-block"]
      local title = ""
      if type(titleblock) == "table" then
          title = table.concat(titleblock, "\n")
      elseif type(titleblock) == "string" then
          title = titleblock
      end

      title = title:gsub("%$(.-)%$", function(n)
          if metadata[n] then return metadata[n] end
      end)
      body = title .. "\n\n" .. body
  end
  
  -- Append footnotes to the end of the body text, before
  -- replacing options and placeholders.
  if #notes > 0 then
    local buff = {}
    for key, note in ipairs(notes) do
        table.insert(buff, key .. '. ' .. note)
    end
    body = body .. "[hr]\n\n" .. table.concat(buff, '\n\n')
  end

  -- Replace temporary markup with correct markup now
  -- that the metadata is available.

  -- for double or single spacing
  -- (double-spaced by default)
  if metadata["fimfic-single-space"] then
      body = body:gsub("{{!paraend!}}%s*\n\n%s*{{!para!}}", "\n{{!para!}}")
  end

  -- Remove no longer needed paraend markers

  body = body:gsub("{{!paraend!}}", "")

  -- Indented paragraphs
  -- (Not indented by default)
  if metadata["fimfic-auto-indent"] then
      body = body:gsub("{{!para!}}", "\t")
  else
      body = body:gsub("{{!para!}}", "")
  end

  -- Headers
  -- With hopefully sensible defaults
  if metadata["fimfic-header-1"] then
      body = body:gsub("{{!h1!(.-)!}}", metadata["fimfic-header-1"][1] .. "%1" .. metadata["fimfic-header-1"][2])
  else
      body = body:gsub("{{!h1!(.-)!}}", "[center][size=xlarge]%1[/size][/center]")
  end
  if metadata["fimfic-header-2"] then
      body = body:gsub("{{!h2!(.-)!}}", metadata["fimfic-header-2"][1] .. "%1" .. metadata["fimfic-header-2"][2])
  else
      body = body:gsub("{{!h2!(.-)!}}", "[center][size=large]%1[/size][/center]")
  end
  if metadata["fimfic-header-3"] then
      body = body:gsub("{{!h3!(.-)!}}", metadata["fimfic-header-3"][1] .. "%1" .. metadata["fimfic-header-3"][2])
  else
      body = body:gsub("{{!h3!(.-)!}}", "[center][b]%1[/b][/center]")
  end
  if metadata["fimfic-header-4"] then
      body = body:gsub("{{!h4!(.-)!}}", metadata["fimfic-header-4"][1] .. "%1" .. metadata["fimfic-header-4"][2])
  else
      body = body:gsub("{{!h4!(.-)!}}", "[b]%1[/b")
  end
  if metadata["fimfic-header-5"] then
      body = body:gsub("{{!h5!(.-)!}}", metadata["fimfic-header-5"][1] .. "%1" .. metadata["fimfic-header-5"][2])
  else
      body = body:gsub("{{!h5!(.-)!}}", "[i]%1[/i]")
  end
  if metadata["fimfic-header-6"] then
      body = body:gsub("{{!h6!(.-)!}}", metadata["fimfic-header-6"][1] .. "%1" .. metadata["fimfic-header-6"][2])
  else
      body = body:gsub("{{!h6!(.-)!}}", "%1")
  end

  -- Section breaks
  -- By default is a [hr] tag (horizontal rule)
  if metadata["fimfic-section-break"] then
      body = body:gsub("%[hr]", metadata["fimfic-section-break"])
  end

  return body
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'",key))
    return function() return "" end
  end
setmetatable(_G, meta)

