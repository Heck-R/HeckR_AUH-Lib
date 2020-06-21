
; Join any number of strings with some separator (eg.: join(":", "string1", "string2") will return "string1:string2")
join(sep, params*) {
    for index,param in params
        str .= sep . param
    return SubStr(str, StrLen(sep)+1)
}

; Joins the given strings with backslashes
pathify(params*) {
	return join("\", params*)
}

; Tells whether the given path points to a file
isFile(path) {
    attributes := fileExist(path)
    return (attributes && !InStr(attributes, "D"))
}

; Tells whether an object contains a specified value (or values)
hasValue(containingObject, valueToSearchFor) {
    valueToSearchForObject := valueToSearchFor
    
    if (!isObject(valueToSearchForObject))
        valueToSearchForObject := [valueToSearchForObject]
    
    for containedKey, containedValue in containingObject
        for searchedKey, searchedValue in valueToSearchForObject
            if (containedValue == searchedValue)
                return true

    return false
}

; Copies the source's content to the target (deep copy).
objectAssign(targetObj, sourceObj) {
    if (!isObject(sourceObj))
        throw "The source should be an object, but it is not"
    if (!isObject(targetObj))
        throw "The target should be an object, but it is not"
    
    for key, value in sourceObj {
        if (isObject(sourceObj[key])) {
            if (!isObject(targetObj[key]))
                targetObj[key] := {}
            objectAssign(sourceObj[key], targetObj[key])
        } else {
            targetObj[key] := sourceObj[key]
        }
    }
}

; Creates the string representation of an object.
objectToString(obj, indentSize := 4, indentLevel := 0) {
    baseIndentSize := indentLevel * indentSize

    ; Primitive value
    if (!isObject(obj))
        return """" . obj . """" . "`n"


    ; Object
    fullIndentSize := baseIndentSize + indentSize

    ; Opening brace
    resultString := "{`n"
    ; Key-value pairs
    for key, value in obj {
        resultString .= Format( "{:" . fullIndentSize .  "}", "" ) . """" . key . """" . ": "
        resultString .= objectToString(value, indentSize, indentLevel + 1)
    }
    ; Closing brace
    resultString .= Format( "{:" . baseIndentSize .  "}", "" ) . "}`n"

    return resultString
}

; Split the given string with the provided delimiter character unless it is escaped by the provided escape character
splitEscapedString(string, delimChar := "`n", escChar := "``") {
    lastSeparator := 0
    splittedStrings := []

    escaping := false
    loop, Parse, string
    {
        ; Skip character if it is being escaped
        if (escaping == true){
            escaping := false
            continue
        }
        ; Note that the next character will be escaped
        if (A_LoopField == escChar) {
            escaping := true
            continue
        }

        ; Split if a delimiter is found
        if (A_LoopField == delimChar) {
            splittedStrings.push(subStr(string, lastSeparator +1, A_Index - lastSeparator -1))
            lastSeparator := A_Index
        }
    }

    if (lastSeparator != strLen(string))
        splittedStrings.push(subStr(string, lastSeparator +1, strLen(string) - lastSeparator))

    return splittedStrings
}

; Trim not escaped whitespaces from both side
trimEscapedString(string, escChar := "``") {
    trimmedString := LTrim(string)

    if (trimmedString == "")
        return ""
    
    ; Searching for first non whitespace
    checkCharPos := strLen(trimmedString)
    while ( checkCharPos > 0 && regExMatch( subStr(trimmedString, checkCharPos, 1) , "\s") > 0 )
        checkCharPos--
    firstWhitespace := checkCharPos + 1

    ; Counting escapes
    escCharNum := 0
    while (subStr(trimmedString, checkCharPos - escCharNum, 1) == escChar){
        checkCharPos--
        escCharNum++
    }

    ; Trimming the end with consideration for escaped whitespaces
    escapeModifier := mod(escCharNum, 2) == 0 ? -1 : 0
    firstActualNonWhitespace := firstWhitespace + escapeModifier
    trimmedString := subStr(trimmedString, 1, firstActualNonWhitespace)

    return trimmedString
}

; Remove escape characters and replace the escaped character with their special version if there is any
unescapeString(string, escChar := "``") {
    unescapedString := string
    unescapedString := StrReplace(unescapedString, "``n", "`n")
    unescapedString := StrReplace(unescapedString, "``r", "`r")
    unescapedString := StrReplace(unescapedString, "``s", " ")
    unescapedString := StrReplace(unescapedString, "``t", "`t")
    unescapedString := RegExReplace(unescapedString, "``(.)", "$1")
    return unescapedString
}

; Creates the combinations of an array of elements
; 
; Example: getCombinations([1,2]) should return [[], [1], [2], [1,2]]
; 
; PARAMETER elements - An array containing the set of elements which shall be combined
; PARAMETER subSetSize (default: -1) - Size of the subset of the combinations. If smaller than 0, all possible length of combinations will be created
; PARAMETER joinConbinationsWith (default: false) - If a string is provided instead of the default false, the individual combinations will be concatenated into strings instead of being arrays, and this parameter's value will be the separator in the string
getCombinations(elements, subSetSize = -1, joinConbinationsWith = false) {

    if(subSetSize > elements.MaxIndex())
        throw "A subset cannot contain more elements that the set itself`nSet element number: " . elements.MaxIndex() . "`nSubset element number: " . subSetSize

    ; No elements or zero set, no work
    if(elements.MaxIndex() == "" || subSetSize == 0)
        return [""]

    combinations := []

    if(subSetSize < 0) {
        ; Recursively create all combinations
        loop % elements.MaxIndex() + 1
            combinations.push(getCombinations(elements, A_Index-1, joinConbinationsWith)*)
    } else {
        ; Create the subSetSize long combinations

        ; Create subSetSize amout of cursors (pointing at 1,2,3,...)
        cursors := []
        loop %subSetSize%
            cursors.push(A_Index)
        
        ; Add and search new combinations until we can
        atNewCombination := true
        while(atNewCombination) {
            ; Add current combination
            currentCombination := []
            loop %subSetSize%
                currentCombination.push(elements[cursors[A_Index]])
            if(joinConbinationsWith != false)
                combinations.push( join(joinConbinationsWith, currentCombination*) )
            else
                combinations.push(currentCombination)


            ; Create next combination by changing cursors
            
            ; Find out the number of cursors stacked up at the very end
            cursorStackSize := 0
            while( cursorStackSize < cursors.MaxIndex() && ((cursors[cursors.MaxIndex() - cursorStackSize]) == (elements.MaxIndex() - cursorStackSize)) )
                cursorStackSize++
            
            ; Change the cursors based on their current positions, to represent the next conbination if there is one
            if(cursorStackSize == 0) {
                ; Can and will step 1 with last cursor
                cursors[cursors.MaxIndex()]++
            } else if(cursorStackSize == cursors.MaxIndex()) {
                ; Already at the last combination
                atNewCombination := false
            } else {
                ; Cannot step any more with last cursor
                lastMoveableCursorIndex := cursors.MaxIndex() - cursorStackSize
                cursors[lastMoveableCursorIndex]++
                loop %cursorStackSize%
                    cursors[lastMoveableCursorIndex + A_Index] := cursors[lastMoveableCursorIndex] + A_Index
            }
        }
    }

    return combinations
}
