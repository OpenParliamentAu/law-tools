cheerio = require 'cheerio'

closest = ($, node, tagName) ->
  curr = node
  while curr?
    curr = $(curr).parent()[0]
    if curr.type is 'root'
      curr = null
    else if curr.name is tagName
      return curr
  return null

#
# * to-markdown - an HTML to Markdown converter
# *
# * Copyright 2011, Dom Christie
# * Licenced under the MIT licence
# *
#
toMarkdown = (string) ->
  replaceEls = (html, elProperties) ->
    pattern = (if elProperties.type is "void" then "<" + elProperties.tag + "\\b([^>]*)\\/?>" else "<" + elProperties.tag + "\\b([^>]*)>([\\s\\S]*?)<\\/" + elProperties.tag + ">")
    regex = new RegExp(pattern, "gi")
    markdown = ""
    if typeof elProperties.replacement is "string"
      markdown = html.replace(regex, elProperties.replacement)
    else
      $ = cheerio.load html
      that = this
      tag = elProperties.tag
      $(tag).each ->
        # Don't replace any elements within a table.
        #console.log closest($, @, 'table')
        unless closest($, @, 'table')?
          outerHtml = $.html(@)
          innerHtml = $(@).html()
          attrs = @[0].attribs

          # Heading level.
          hLevel = tag.match /h(\d)/
          other = hLevel[1] if hLevel?

          replacement = elProperties.replacement.call that, outerHtml, attrs, innerHtml, other
          $(@).replaceWith replacement

      markdown = $.root().html()

      #markdown = html.replace(regex, (str, p1, p2, p3) ->
      #  elProperties.replacement.call this, str, p1, p2, p3
    return markdown

  attrRegExp = (attr) ->
    new RegExp(attr + "\\s*=\\s*[\"']?([^\"']*)[\"']?", "i")

  # Pre code blocks
  # convert tabs to spaces (you know it makes sense)

  # Lists

  # Escape numbers that could trigger an ol

  # Converts lists that have no child lists (of same type) first, then works it's way up
  replaceLists = (html) ->
    html = html.replace(/<(ul|ol)\b[^>]*>([\s\S]*?)<\/\1>/g, (str, listType, innerHTML) ->
      lis = innerHTML.split("</li>")
      lis.splice lis.length - 1, 1
      i = 0
      len = lis.length

      while i < len
        if lis[i]
          prefix = (if (listType is "ol") then (i + 1) + ".  " else "*   ")
          lis[i] = lis[i].replace(/\s*<li[^>]*>([\s\S]*)/i, (str, innerHTML) ->
            innerHTML = innerHTML.replace(/^\s+/, "")
            innerHTML = innerHTML.replace(/\n\n/g, "\n\n    ")

            # indent nested lists
            innerHTML = innerHTML.replace(/\n([ ]*)+(\*|\d+\.) /g, "\n$1    $2 ")
            prefix + innerHTML
          )
        i++
      lis.join "\n"
    )
    "\n\n" + html.replace(/[ \t]+\n|\s+$/g, "")

  # Blockquotes
  replaceBlockquotes = (html) ->
    html = html.replace(/<blockquote\b[^>]*>([\s\S]*?)<\/blockquote>/g, (str, inner) ->
      inner = inner.replace(/^\s+|\s+$/g, "")
      inner = cleanUp(inner)
      inner = inner.replace(/^/g, "> ")
      inner = inner.replace(/^(>([ \t]{2,}>)+)/g, "> >")
      inner
    )
    html
  cleanUp = (string) ->
    string = string.replace(/^[\t\r\n]+|[\t\r\n]+$/g, "") # trim leading/trailing whitespace
    string = string.replace(/\n\s+\n/g, "\n\n")
    string = string.replace(/\n{3,}/g, "\n\n") # limit consecutive linebreaks to 2
    string
  ELEMENTS = [
    patterns: "p"
    replacement: (str, attrs, innerHTML) ->
      (if innerHTML then "\n\n" + innerHTML + "\n" else "")
  ,
    patterns: "br"
    type: "void"
    replacement: "\n"
  ,
    patterns: ["h1", "h2", "h3", "h4", "h5", "h6"]
    #patterns: "h([1-6])"
    #replacement: (str, hLevel, attrs, innerHTML) ->
    replacement: (str, attrs, innerHTML, hLevel) ->
      hPrefix = ""
      i = 0

      while i < hLevel
        hPrefix += "#"
        i++
      "\n\n" + hPrefix + " " + innerHTML + "\n"
  ,
    patterns: "hr"
    type: "void"
    replacement: "\n\n* * *\n"
  ,
    patterns: "a"
    replacement: (str, attrs, innerHTML) ->
      href = if attrs.href then [0, attrs.href] else false #attrs.match(attrRegExp("href"))
      title = [0, attrs.title] #attrs.match(attrRegExp("title"))
      (if href then "[" + innerHTML + "]" + "(" + href[1] + ((if title and title[1] then " \"" + title[1] + "\"" else "")) + ")" else str)
  ,
    patterns: ["b", "strong"]
    replacement: (str, attrs, innerHTML) ->
      (if innerHTML then "**" + innerHTML + "**" else "")
  ,
    patterns: ["i", "em"]
    replacement: (str, attrs, innerHTML) ->
      (if innerHTML then "_" + innerHTML + "_" else "")
  ,
    patterns: "code"
    replacement: (str, attrs, innerHTML) ->
      (if innerHTML then "`" + innerHTML + "`" else "")
  ,
    patterns: "img"
    type: "void"
    replacement: (str, attrs, innerHTML) ->
      src = [0,attrs.src] #attrs.src #attrs.match(attrRegExp("src"))
      alt = [0,attrs.alt] #attrs.alt #attrs.match(attrRegExp("alt"))
      title = [0,attrs.title] #attrs.title #attrs.match(attrRegExp("title"))
      "![" + ((if alt and alt[1] then alt[1] else "")) + "]" + "(" + src[1] + ((if title and title[1] then " \"" + title[1] + "\"" else "")) + ")"
  ]
  i = 0
  len = ELEMENTS.length

  while i < len
    if typeof ELEMENTS[i].patterns is "string"
      string = replaceEls(string,
        tag: ELEMENTS[i].patterns
        replacement: ELEMENTS[i].replacement
        type: ELEMENTS[i].type
      )
    else
      j = 0
      pLen = ELEMENTS[i].patterns.length

      while j < pLen
        string = replaceEls(string,
          tag: ELEMENTS[i].patterns[j]
          replacement: ELEMENTS[i].replacement
          type: ELEMENTS[i].type
        )
        j++
    i++
  string = string.replace(/<pre\b[^>]*>`([\s\S]*)`<\/pre>/g, (str, innerHTML) ->
    innerHTML = innerHTML.replace(/^\t+/g, "  ")
    innerHTML = innerHTML.replace(/\n/g, "\n    ")
    "\n\n    " + innerHTML + "\n"
  )
  string = string.replace(/(\d+)\. /g, "$1\\. ")
  noChildrenRegex = /<(ul|ol)\b[^>]*>(?:(?!<ul|<ol)[\s\S])*?<\/\1>/g
  while string.match(noChildrenRegex)
    string = string.replace(noChildrenRegex, (str) ->
      replaceLists str
    )
  deepest = /<blockquote\b[^>]*>((?:(?!<blockquote)[\s\S])*?)<\/blockquote>/g
  while string.match(deepest)
    string = string.replace(deepest, (str) ->
      replaceBlockquotes str
    )
  cleanUp string

exports.toMarkdown = toMarkdown  if typeof exports is "object"
