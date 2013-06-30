#
#Copyright (c) 2009 James Padolsey.  All rights reserved.
#
#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions
#are met:
#
#   1. Redistributions of source code must retain the above copyright
#	  notice, this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright
#	  notice, this list of conditions and the following disclaimer in the
#	  documentation and/or other materials provided with the distribution.
#
#THIS SOFTWARE IS PROVIDED BY James Padolsey ``AS IS'' AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#ARE DISCLAIMED. IN NO EVENT SHALL James Padolsey OR CONTRIBUTORS BE LIABLE
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#SUCH DAMAGE.
#
#The views and conclusions contained in the software and documentation are
#those of the authors and should not be interpreted as representing official
#policies, either expressed or implied, of James Padolsey.
#
# AUTHOR James Padolsey (http://james.padolsey.com)
# VERSION 1.03.0
# UPDATED 29-10-2011
# CONTRIBUTORS
#	David Waller
#    Benjamin Drucker
#
#

# These "util" functions are not part of the core
#	   functionality but are  all necessary - mostly DOM helpers 
util =
    el: (type, attrs) ->
      
      # Create new element 
      el = document.createElement(type)
      attr = undefined
      
      #Copy to single object 
      attrs = util.merge({}, attrs)
      
      # Add attributes to el 
      if attrs and attrs.style
        styles = attrs.style
        util.applyCSS el, attrs.style
        delete attrs.style
      for attr of attrs
        el[attr] = attrs[attr]  if attrs.hasOwnProperty(attr)
      el

    applyCSS: (el, styles) ->
      
      # Applies CSS to a single element 
      for prop of styles
        if styles.hasOwnProperty(prop)
          try
            
            # Yes, IE6 SUCKS! 
            el.style[prop] = styles[prop]

    txt: (t) ->
      
      # Create text node 
      document.createTextNode t

    row: (cells, type, cellType) ->
      
      # Creates new <tr> 
      cellType = cellType or "td"
      
      # colSpan is calculated by length of null items in array 
      colSpan = util.count(cells, null) + 1
      tr = util.el("tr")
      td = undefined
      attrs =
        style: util.getStyles(cellType, type)
        colSpan: colSpan
        onmouseover: ->
          tds = @parentNode.childNodes
          util.forEach tds, (cell) ->
            return  if cell.nodeName.toLowerCase() isnt "td"
            util.applyCSS cell, util.getStyles("td_hover", type)


        onmouseout: ->
          tds = @parentNode.childNodes
          util.forEach tds, (cell) ->
            return  if cell.nodeName.toLowerCase() isnt "td"
            util.applyCSS cell, util.getStyles("td", type)


      util.forEach cells, (cell) ->
        return  if cell is null
        
        # Default cell type is <td> 
        td = util.el(cellType, attrs)
        if cell.nodeType
          
          # IsDomElement 
          td.appendChild cell
        else
          
          # IsString 
          td.innerHTML = util.shorten(cell.toString())
        tr.appendChild td

      tr

    hRow: (cells, type) ->
      
      # Return new <th> 
      util.row cells, type, "th"

    table: (headings, type) ->
      headings = headings or []
      
      # Creates new table: 
      attrs =
        thead:
          style: util.getStyles("thead", type)

        tbody:
          style: util.getStyles("tbody", type)

        table:
          style: util.getStyles("table", type)

      tbl = util.el("table", attrs.table)
      thead = util.el("thead", attrs.thead)
      tbody = util.el("tbody", attrs.tbody)
      if headings.length
        tbl.appendChild thead
        thead.appendChild util.hRow(headings, type)
      tbl.appendChild tbody
      
      # Facade for dealing with table/tbody
      #				   Actual table node is this.node: 
      node: tbl
      tbody: tbody
      thead: thead
      appendChild: (node) ->
        @tbody.appendChild node

      addRow: (cells, _type, cellType) ->
        @appendChild util.row.call(util, cells, (_type or type), cellType)
        this

    shorten: (str) ->
      max = prettyPrintThis.maxStringLength
      str = str.replace(/^\s\s*|\s\s*$|\n/g, "")
      (if str.length > max then (str.substring(0, max - 1) + "...") else str)

    htmlentities: (str) ->
      str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace />/g, "&gt;"

    merge: (target, source) ->
      
      # Merges two (or more) objects,
      #			   giving the last one precedence 
      target = {}  if typeof target isnt "object"
      for property of source
        if source.hasOwnProperty(property)
          sourceProperty = source[property]
          if typeof sourceProperty is "object"
            target[property] = util.merge(target[property], sourceProperty)
            continue
          target[property] = sourceProperty
      a = 2
      l = arguments_.length

      while a < l
        util.merge target, arguments_[a]
        a++
      target

    count: (arr, item) ->
      count = 0
      i = 0
      l = arr.length

      while i < l
        count++  if arr[i] is item
        i++
      count

    thead: (tbl) ->
      tbl.getElementsByTagName("thead")[0]

    forEach: (arr, max, fn) ->
      fn = max  unless fn
      
      # Helper: iteration 
      len = arr.length
      index = -1
      break  if fn(arr[index], index, arr) is false  while ++index < len
      true

    type: (v) ->
      try
        
        # Returns type, e.g. "string", "number", "array" etc.
        #				   Note, this is only used for precise typing. 
        return "null"  if v is null
        return "undefined"  if v is `undefined`
        oType = Object::toString.call(v).match(/\s(.+?)\]/)[1].toLowerCase()
        if v.nodeType
          return "domelement"  if v.nodeType is 1
          return "domnode"
        return oType  if /^(string|number|array|regexp|function|date|boolean)$/.test(oType)
        return (if v.jquery and typeof v.jquery is "string" then "jquery" else "object")  if typeof v is "object"
        return "object"  if v is window or v is document
        return "default"
      catch e
        return "default"

    within: (ref) ->
      
      # Check existence of a val within an object
      #			   RETURNS KEY 
      is: (o) ->
        for i of ref
          return i  if ref[i] is o
        ""

    common:
      circRef: (obj, key, settings) ->
        util.expander "[POINTS BACK TO <strong>" + (key) + "</strong>]", "Click to show this item anyway", ->
          @parentNode.appendChild prettyPrintThis(obj,
            maxDepth: 1
          )


      depthReached: (obj, settings) ->
        util.expander "[DEPTH REACHED]", "Click to show this item anyway", ->
          try
            @parentNode.appendChild prettyPrintThis(obj,
              maxDepth: 1
            )
          catch e
            @parentNode.appendChild util.table(["ERROR OCCURED DURING OBJECT RETRIEVAL"], "error").addRow([e.message]).node


    getStyles: (el, type) ->
      type = prettyPrintThis.settings.styles[type] or {}
      util.merge {}, prettyPrintThis.settings.styles["default"][el], type[el]

    expander: (text, title, clickFn) ->
      util.el "a",
        innerHTML: util.shorten(text) + " <b style=\"visibility:hidden;\">[+]</b>"
        title: title
        onmouseover: ->
          @getElementsByTagName("b")[0].style.visibility = "visible"

        onmouseout: ->
          @getElementsByTagName("b")[0].style.visibility = "hidden"

        onclick: ->
          @style.display = "none"
          clickFn.call this
          false

        style:
          cursor: "pointer"


    stringify: (obj) ->
      
      # Bit of an ugly duckling!
      #			   - This fn returns an ATTEMPT at converting an object/array/anyType
      #				 into a string, kinda like a JSON-deParser
      #			   - This is used for when |settings.expanded === false| 
      type = util.type(obj)
      str = undefined
      first = true
      if type is "array"
        str = "["
        util.forEach obj, (item, i) ->
          str += ((if i is 0 then "" else ", ")) + util.stringify(item)

        return str + "]"
      if typeof obj is "object"
        str = "{"
        for i of obj
          if obj.hasOwnProperty(i)
            str += ((if first then "" else ", ")) + i + ":" + util.stringify(obj[i])
            first = false
        return str + "}"
      return "/" + obj.source + "/"  if type is "regexp"
      return "\"" + obj.replace(/"/g, "\\\"") + "\""  if type is "string" # "
      obj.toString()

    headerGradient: (->
      canvas = document.createElement("canvas")
      return ""  unless canvas.getContext
      cx = canvas.getContext("2d")
      canvas.height = 30
      canvas.width = 1
      linearGrad = cx.createLinearGradient(0, 0, 0, 30)
      linearGrad.addColorStop 0, "rgba(0,0,0,0)"
      linearGrad.addColorStop 1, "rgba(0,0,0,0.25)"
      cx.fillStyle = linearGrad
      cx.fillRect 0, 0, 1, 30
      dataURL = canvas.toDataURL and canvas.toDataURL()
      "url(" + (dataURL or "") + ")"
    )()

  
# Main..
prettyPrintThis = (obj, options) ->
    
    #
    #		 *	  obj :: Object to be printed					
    #		 *  options :: Options (merged with config)
    #		 
    options = options or {}
    settings = util.merge({}, prettyPrintThis.config, options)
    container = util.el("div")
    config = prettyPrintThis.config
    currentDepth = 0
    stack = {}
    hasRunOnce = false
    
    # Expose per-call settings.
    #		   Note: "config" is overwritten (where necessary) by options/"settings"
    #		   So, if you need to access/change *DEFAULT* settings then go via ".config" 
    prettyPrintThis.settings = settings
    typeDealer =
      string: (item) ->
        util.txt "\"" + util.shorten(item.replace(/"/g, "\\\"")) + "\"" # "

      number: (item) ->
        util.txt item

      regexp: (item) ->
        miniTable = util.table(["RegExp", null], "regexp")
        flags = util.table()
        span = util.expander("/" + item.source + "/", "Click to show more", ->
          @parentNode.appendChild miniTable.node
        )
        flags.addRow(["g", item.global]).addRow(["i", item.ignoreCase]).addRow ["m", item.multiline]
        miniTable.addRow(["source", "/" + item.source + "/"]).addRow(["flags", flags.node]).addRow ["lastIndex", item.lastIndex]
        (if settings.expanded then miniTable.node else span)

      domelement: (element, depth) ->
        miniTable = util.table(["DOMElement", null], "domelement")
        props = ["id", "className", "innerHTML", "src", "href"]
        elname = element.nodeName or ""
        miniTable.addRow ["tag", "&lt;" + elname.toLowerCase() + "&gt;"]
        util.forEach props, (prop) ->
          miniTable.addRow [prop, util.htmlentities(element[prop])]  if element[prop]

        (if settings.expanded then miniTable.node else util.expander("DOMElement (" + elname.toLowerCase() + ")", "Click to show more", ->
          @parentNode.appendChild miniTable.node
        ))

      domnode: (node) ->
        
        # Deals with all DOMNodes that aren't elements (nodeType !== 1) 
        miniTable = util.table(["DOMNode", null], "domelement")
        data = util.htmlentities((node.data or "UNDEFINED").replace(/\n/g, "\\n"))
        miniTable.addRow(["nodeType", node.nodeType + " (" + node.nodeName + ")"]).addRow ["data", data]
        (if settings.expanded then miniTable.node else util.expander("DOMNode", "Click to show more", ->
          @parentNode.appendChild miniTable.node
        ))

      jquery: (obj, depth, key) ->
        typeDealer["array"] obj, depth, key, true

      object: (obj, depth, key) ->
        
        # Checking depth + circular refs 
        
        # Note, check for circular refs before depth; just makes more sense 
        stackKey = util.within(stack).is(obj)
        return util.common.circRef(obj, stackKey, settings)  if stackKey
        stack[key or "TOP"] = obj
        return util.common.depthReached(obj, settings)  if depth is settings.maxDepth
        table = util.table(["Object", null], "object")
        isEmpty = true
        keys = []
        for i of obj
          keys.push i  if obj.hasOwnProperty(i)
        keys.sort()  if settings.sortKeys
        len = keys.length
        j = 0

        while j < len
          i = keys[j]
          if not obj.hasOwnProperty or obj.hasOwnProperty(i)
            item = obj[i]
            type = util.type(item)
            isEmpty = false
            try
              table.addRow [i, typeDealer[type](item, depth + 1, i)], type
            catch e
              
              # Security errors are thrown on certain Window/DOM properties 
              console.log e.message  if window.console and window.console.log
          j++
        if isEmpty
          table.addRow ["<small>[empty]</small>"]
        else
          table.thead.appendChild util.hRow(["key", "value"], "colHeader")
        ret = (if (settings.expanded or hasRunOnce) then table.node else util.expander(util.stringify(obj), "Click to show more", ->
          @parentNode.appendChild table.node
        ))
        hasRunOnce = true
        ret

      array: (arr, depth, key, jquery) ->
        
        # Checking depth + circular refs 
        
        # Note, check for circular refs before depth; just makes more sense 
        stackKey = util.within(stack).is(arr)
        return util.common.circRef(arr, stackKey)  if stackKey
        stack[key or "TOP"] = arr
        return util.common.depthReached(arr)  if depth is settings.maxDepth
        
        # Accepts a table and modifies it 
        me = (if jquery then "jQuery" else "Array")
        table = util.table([me + "(" + arr.length + ")", null], (if jquery then "jquery" else me.toLowerCase()))
        isEmpty = true
        count = 0
        table.addRow ["selector", arr.selector]  if jquery
        util.forEach arr, (item, i) ->
          if settings.maxArray >= 0 and ++count > settings.maxArray
            table.addRow [i + ".." + (arr.length - 1), typeDealer[util.type(item)]("...", depth + 1, i)]
            return false
          isEmpty = false
          table.addRow [i, typeDealer[util.type(item)](item, depth + 1, i)]

        unless jquery
          if isEmpty
            table.addRow ["<small>[empty]</small>"]
          else
            table.thead.appendChild util.hRow(["index", "value"], "colHeader")
        (if settings.expanded then table.node else util.expander(util.stringify(arr), "Click to show more", ->
          @parentNode.appendChild table.node
        ))

      function: (fn, depth, key) ->
        
        # Checking JUST circular refs 
        stackKey = util.within(stack).is(fn)
        return util.common.circRef(fn, stackKey)  if stackKey
        stack[key or "TOP"] = fn
        miniTable = util.table(["Function", null], "function")
        argsTable = util.table(["Arguments"])
        args = fn.toString().match(/\((.+?)\)/)
        body = fn.toString().match(/\(.*?\)\s+?\{?([\S\s]+)/)[1].replace(/\}?$/, "")
        miniTable.addRow(["arguments", (if args then args[1].replace(/[^\w_,\s]/g, "") else "<small>[none/native]</small>")]).addRow ["body", body]
        (if settings.expanded then miniTable.node else util.expander("function(){...}", "Click to see more about this function.", ->
          @parentNode.appendChild miniTable.node
        ))

      date: (date) ->
        miniTable = util.table(["Date", null], "date")
        sDate = date.toString().split(/\s/)
        
        # TODO: Make this work well in IE! 
        miniTable.addRow(["Time", sDate[4]]).addRow ["Date", sDate.slice(0, 4).join("-")]
        (if settings.expanded then miniTable.node else util.expander("Date (timestamp): " + (+date), "Click to see a little more info about this date", ->
          @parentNode.appendChild miniTable.node
        ))

      boolean: (bool) ->
        util.txt bool.toString().toUpperCase()

      undefined: ->
        util.txt "UNDEFINED"

      null: ->
        util.txt "NULL"

      default: ->
        
        # When a type cannot be found 
        util.txt "prettyPrint: TypeNotFound Error"

    container.appendChild typeDealer[(if (settings.forceObject) then "object" else util.type(obj))](obj, currentDepth)
    container

  
  # Configuration 
  
  # All items can be overridden by passing an
  #	   "options" object when calling prettyPrint 
  prettyPrintThis.config =
    
    # Try setting this to false to save space 
    expanded: true
    sortKeys: false # if true, will sort object keys
    forceObject: false
    maxDepth: 3
    maxStringLength: 40
    maxArray: -1 # default is unlimited
    styles:
      array:
        th:
          backgroundColor: "#6DBD2A"
          color: "white"

      function:
        th:
          backgroundColor: "#D82525"

      regexp:
        th:
          backgroundColor: "#E2F3FB"
          color: "#000"

      object:
        th:
          backgroundColor: "#1F96CF"

      jquery:
        th:
          backgroundColor: "#FBF315"

      error:
        th:
          backgroundColor: "red"
          color: "yellow"

      domelement:
        th:
          backgroundColor: "#F3801E"

      date:
        th:
          backgroundColor: "#A725D8"

      colHeader:
        th:
          backgroundColor: "#EEE"
          color: "#000"
          textTransform: "uppercase"

      default:
        table:
          borderCollapse: "collapse"
          width: "100%"

        td:
          padding: "5px"
          fontSize: "12px"
          backgroundColor: "#FFF"
          color: "#222"
          border: "1px solid #000"
          verticalAlign: "top"
          fontFamily: "\"Consolas\",\"Lucida Console\",Courier,mono"
          whiteSpace: "nowrap"

        td_hover: {}
        
        # Styles defined here will apply to all tr:hover > td,
        #						- Be aware that "inheritable" properties (e.g. fontWeight) WILL BE INHERITED 
        th:
          padding: "5px"
          fontSize: "12px"
          backgroundColor: "#222"
          color: "#EEE"
          textAlign: "left"
          border: "1px solid #000"
          verticalAlign: "top"
          fontFamily: "\"Consolas\",\"Lucida Console\",Courier,mono"
          backgroundImage: util.headerGradient
          backgroundRepeat: "repeat-x"

this.prettyPrint = prettyPrintThis
