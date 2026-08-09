function RawInline (el)
  if el.format == "html" and el.text:match("<br%s*/?>") then
    return pandoc.LineBreak()
  end
end
