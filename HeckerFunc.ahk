
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

; Creates a normal tooltip, which automatically disappeares after the set timeout
tmpToolTip(content := "", timeout := 1000, x := "", y := "", toolTipId := "") {
	global tmpToolTipId
	tmpToolTipId := toolTipId
	
	ToolTip, %content%, %x%, %y%, %tmpToolTipId%
	SetTimer TmpToolTipOff, -%timeout%
	return

	TmpToolTipOff:
	ToolTip,,,, %tmpToolTipId%
	return
}

; Returns all of the clipboard format IDs that apply to the current clipboard content
getClipFormatIDs() {
    openReturnCode := DllCall("OpenClipboard", "Ptr", 0)
    if(openReturnCode == 0){
        throw "The clipboard could not be opened`nMost likely another process is locking it`n`nError: '" . DllCall("GetLastError") . "'"
    }

    clipFormatIDArray := []
    clipFormatID := 0
    Loop {
        clipFormatID := DllCall("EnumClipboardFormats", "Uint", clipFormatID)
        if (clipFormatID == 0)
            break
        clipFormatIDArray.Push(clipFormatID)
    }

    closeReturnCode := DllCall("CloseClipboard")
    if(closeReturnCode == 0){
        throw "The clipboard could not be closed`n`nError: '" . DllCall("GetLastError") . "'"
    }

    return clipFormatIDArray
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
            objectAssign(targetObj[key], sourceObj[key])
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

; Mathematically correct modulo (>0)
mathMod(number, base) {
    standardMod := Mod(number, base)
    return standardMod < 0 ? standardMod + base : standardMod
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

; Mandatory #if clause for using conditional hotkeys in mitmInput()
#If mitmInput_enabled
#If

; Creates hotkeys for every possible key using virtual keycodes (mouse, joystick, etc. included)
; With this, a function can be inserted before each and every keystroke (mitm ~ Man In The Middle)
; 
; There are 2 functionallities based on the first parameter's value:
; 1)
; PARAMETER callback (default: -1) - In case 0, 1 or -1, it enables / disables the the #if directive which contains all the hotkeys related to this function (if created)
;   * 0: Enable hotkeys
;   * 1: Disable hotkeys
;   * -1: Switch between enabled / disabled state of hotkeys
; 2)
; PARAMETER callback (default: -1) - A label / function name / function object that is provided to the created Hotkeys. It will be called on each keypress (see https://www.autohotkey.com/docs/commands/Hotkey.htm > Label)
; PARAMETER blockKeys (default: false) - Whether to block the keys
;   * false: Do not block keys
;   * true: Block all keys (this can be dangerous, since it can possibly block every possible input. You can use the "excludeFromBlock" parameter for safety)
;   * string (comma separated): Only block the keys with listed virtual key values (eg.: "1, 2" [left and right click])
; PARAMETER excludeFromBlock (default: "1, 2") - Comma separated string, containing the virtual key values NOT to block (overwrites the "blockKeys" parameter)
mitmInput(callback := -1, blockKeys := false, excludeFromBlock := "1, 2") {
	global mitmInput_enabled ;Switch for the recorder hotkeys

	; Enable / Disable hotkeys if first param is a bool
	if (callback == true || callback == false) {
		mitmInput_enabled := callback
		return
	}
    if (callback == -1) {
		mitmInput_enabled := !mitmInput_enabled
		return
    }

	; Split key arrays
	excludeFromBlockArray := StrSplit(excludeFromBlock, ",", " ")
	realBlockKeys := isObject(blockKeys) ? StrSplit(blockKeys, ",", " ") : blockKeys


	; Prepare looping through hexa 0-255
	firstHexList := ["", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
	secondHexList := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]

	Hotkey If, mitmInput_enabled

	loop 16 {
		firstChar := firstHexList[A_Index]
		loop 16 {
			secondChar := secondHexList[A_Index]
			virtualNum=%firstChar%%secondChar%
			
			; There is no vk0
			if (virtualNum == "0"){
				continue
			}
			
			noBlockPrefix := ""
			if ( (realBlockKeys == false) || hasValue(excludeFromBlockArray, virtualNum)) {
				noBlockPrefix := "~"
			}
			else if (realBlockKeys == true) {
				noBlockPrefix := ""
			}
			else if (isObject(realBlockKeys)) {
				noBlockPrefix := hasValue(realBlockKeys, virtualNum) ? "" : "~"
			} else {
				Throw "Argument 'blockKeys' must be a bool, or a comma separated string, but it is neither"
			}

			Hotkey, %noBlockPrefix%vk%virtualNum%, %callback%
		}
	}

	Hotkey If
}

; Reads any one key's virtual key value (mouse, joystick, etc. included)
; 
; PARAMETER blockKey (default: true) - Whether to block the key when reading
; PARAMETER timeout (miliseconds; default: 0) - After how much time should the reading automatically disable if no key is pressed. No timeout if <= 0
readSingleKey(blockKey := true, timeout := 0) {
	global readSingleKey_prepared ;Indicates whether the prepare already executed or not
	global readSingleKey_lastKeyBlocked ;Indicates whether the key blocking was enabled last time (must re-prepare if different than current blockKey)
	global readSingleKey_readKeyName ;Variable to store the recorded key's name

	; Set variables
	useTimeout := timeout > 0

	; Prepare
	if ( (!readSingleKey_prepared) || blockKey != readSingleKey_lastKeyBlocked) {
		readSingleKey_prepared := true

		mitmInput("singleKeyRecorder", blockKey, "")
	}
	readSingleKey_lastKeyBlocked := blockKey

	; Enable key reading
	readSingleKey_readKeyName := ""
	mitmInput(true)

	readWindowText := "Please press the key you wish to record"
	readWindowText .= (blockKey ? "`n(The keypress will not have any effect due to the recording)" : "")
	readWindowText .= (useTimeout ? "`n(You have " . timeout / 1000 . " seconds)" : "")
	Tooltip, %readWindowText%, 0, 0
	
	; Wait for key to be read or timeout
	startTime := A_TickCount
	while ( (readSingleKey_readKeyName == "") && ((!useTimeout) || (A_TickCount < startTime + timeout)) ) {
		Sleep 50
	}

	; Disable key reading
	Tooltip
	mitmInput(false)
	
	; Return key name without no-keyblock modifier
	return LTrim(readSingleKey_readKeyName, "~")

	;-------------------

	singleKeyRecorder:
		readSingleKey_readKeyName := A_ThisHotkey
	return
}

; Map a funtion to a hotkey that is defined in an config ini file
; 
; PARAMETER configFile - String path to the config ini file
; PARAMETER configSectionName - Ini section where the hotkey is set
; PARAMETER hotkeyFunctionMapping - Contains the ini key name for the hotkey, and the name of the function to be used. Can be one of the following formats:
;   - "iniAndFunctionName": In case this is a string, the ini key name and the function name has to be identical.
;   - ["iniKey", "functionName"]: An array can be defined, in which case the ini key name and the function name can be different.
;   - ["iniKey", "functionName", "releaseFunctionName"]: If a non empty third string is also passed in the array, the release of the hotkey will trigger the function with the provided name.
; PARAMETER paramsToBind (default: <no parameters>) - Array of parameters to bind to the hotkey function(s)
; PARAMETER threadNum (default: 1) - Number of max parallel execution of the same hotkey
mapConfigHotkeyToFunction(configFile, configSectionName, hotkeyFunctionMapping, paramsToBind := "", threadNum := 1) {
    ; Handle hotkeyFunctionMapping being either a string or an array
    iniKey := hotkeyFunctionMapping
    functionName := hotkeyFunctionMapping
    if (isObject(hotkeyFunctionMapping)) {
        iniKey := hotkeyFunctionMapping[1]
        functionName := hotkeyFunctionMapping[2]
    }

    ; Key combination for the hotkey
    IniRead, toBeHotkey, %configFile% , %configSectionName%, %iniKey%, %A_Space%

    ; If a key combination is defined, create the hotkey
    if (toBeHotkey != "") {
        ; Create function reference bor binding
        hotkeyFunction := Func(functionName)
        
        ; Bind parameters
        allParamsToBind := []
        if (paramsToBind != "")
            for paramIndex, paramValue in paramsToBind {
                allParamsToBind.Push(paramValue)
            }
        
        ; Bind key combination if parameters are still needed
        if (hotkeyFunction.MinParams > allParamsToBind.MaxIndex())
            allParamsToBind.Push(toBeHotkey)
        
        ; Create hotkey
        hotkeyFunction := hotkeyFunction.Bind(allParamsToBind*)
        Hotkey %toBeHotkey%, %hotkeyFunction%, T%threadNum%
        
        ; Create release hotkey
        if (hotkeyFunctionMapping[3] != "") {
            releaseFunction := Func(hotkeyFunctionMapping[3])
            releaseFunction := releaseFunction.Bind(allParamsToBind*)
            Hotkey %toBeHotkey% up, %releaseFunction%, T%threadNum%
        }
    }
}
