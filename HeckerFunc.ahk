
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

; Gets the absolute cursor position on a multiple screen setup (relative to the main display's top left)
; This is basically a wrapper for the GetCursorPos win32 api instead of the dll call
; See https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getcursorpos
; 
; RETURNS An associative array with x and y keys
getCursorPos() {
    ; POINT structure = 8 bytes 
    VarSetCapacity(POINT, 8, 0)
    DllCall("GetCursorPos", uint, &POINT)

    return {x: NumGet(POINT, 0), y: NumGet(POINT, 4)}
}

; Moves the cursor to an absolute position on a multiple screen setup (relative to the main display's top left)
; This is basically a wrapper for the SetCursorPos win32 api instead of the dll call
; See https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getcursorpos
setCursorPos(x, y) {
    DllCall("SetCursorPos", "int", x, "int", y)
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
; NOTES
; - The created hotkeys do not become enabled when they are first created with this function. It has to be called again for that
; - Overwrites Hotkey If on autoDirective := true
; 
; There are 2 functionallities based on the first parameter's value:
; 1)
; PARAMETER callback (default: -1) - In case 0, 1 or -1, it enables / disables the the #if directive which contains all the hotkeys related to this function (if created)
;   * 0: Enable hotkeys
;   * 1: Disable hotkeys
;   * -1: Switch between enabled / disabled state of hotkeys
;   NOTE: For this, the autoDirective parameter must be true
; 2)
; PARAMETER callback (default: -1) - A label / function name / function object that is provided to the created Hotkeys. It will be called on each keypress (see https://www.autohotkey.com/docs/commands/Hotkey.htm > Label)
; PARAMETER autoDirective (default: true) - Whether or not to use an implicit #if directive, in order for the created hotkeys to be toggleable through the "callback" parameter
;   In case false is set, the hotkeys will get the #if directive last defined by a "Hotkey If" (see https://www.autohotkey.com/docs/commands/Hotkey.htm)
;   NOTE: In case of true, the "Hotkey If" will be called with empty parameters, and reset the #if directive for any subsequent Hotkey creation, unless it is defined (again)
; PARAMETER keyFilter (default: "!up") - The keys for which hotkeys will be created can be filtered via this parameter.
;   The keys are virtual keys formatted as "vk<hex>", and an optional " up" at the end, for the release of the keys (in case triggerOnKeyUp is true). E.g.: "vk41 up" ~ releasing the "a" button
;   There are a few possible types of values that can be passed
;   * false: No filtering, hotkeys will be created for each and every key
;   * <regex string>: Hotkeys will be created for all keys that match this regex
;   * !<regex string>: The same regex mentioned above, but the first character is a "!"
;       In this case the regex will become a blacklist filter => hotkeys will be created for every key that DOES NOT match the regex
;   NOTE: Most keys tend to "spam" trigger the hotkey when being held down. (e.g.: holding down the "a" button types multiple letters while being held down)
;         To avoid that, the virtual key can be extracted, and waited for in the callback. E.g.:
;             RegExMatch(A_ThisHotkey, "vk\w{1,2}" , hotkeyMatch)
;             KeyWait % hotkeyMatch
; PARAMETER hotkeyModifiers (default: "~*") - Hotkey modifiers to be added to all of the created hotkeys (see https://www.autohotkey.com/docs/Hotkeys.htm#Symbols)
;   E.g.: One of the default modifiers "~" make sure, that the keys are not blocked
;   CAUTION: Removing the ~ can potentially prevent any and every input, rendering the machine unusable while the created hotkeys are active
; PARAMETER hotkeyOptions (default: "") - A "Hotkey" commands "options" parameter to be passed to all of the created hotkeys (see https://www.autohotkey.com/docs/commands/Hotkey.htm > Options)
; PARAMETER modifierOptionExceptions (default: false) - Exception keys can be defined with different "hotkeyModifiers" and "hotkeyOptions" than the remaining ones
;   The value must essentially be an array of objects, where every object can have 3 properties:
;       * filter (mandatory): A similar filter to the "keyFilter" parameter, with the exception, that this must be a <regex string>
;       * hotkeyModifiers: Same as the "hotkeyModifiers" parameter but this one overwrites the general one for the filtered keys
;       * hotkeyOptions: Same as the "hotkeyOptions" parameter but this one overwrites the general one for the filtered keys
;   NOTE: The order matters ~ in case of multiple filters matching a key, the first match will be the dominant one
mitmInput(callback := -1, autoDirective := true, keyFilter := "!up", hotkeyModifiers := "~*", hotkeyOptions := "", modifierOptionExceptions := false) {
	global mitmInput_enabled ;Switch for the recorder hotkeys

	; Enable / Disable hotkeys if first param is a bool
	if (callback == true || callback == false) {
		mitmInput_enabled := callback
		return
	}
    ; Switch hotkeys on default value
    if (callback == -1) {
		mitmInput_enabled := !mitmInput_enabled
		return
    }

	; Prepare looping through hexa 0-255
	firstHexList := ["", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
	secondHexList := ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    pressReleaseModifierList := ["", " up"]
    
    ; Prepate for filter negation
    negateKeyFilter := false
    keyFilterRegex := keyFilter
    if (keyFilter != false && SubStr(keyFilter, 1, 1) == "!") {
        negateKeyFilter := true
        keyFilterRegex := SubStr(keyFilter, 2)
    }

    ; Directive
    if (autoDirective)
	    Hotkey If, mitmInput_enabled

    for firstHexIndex, firstHexChar in firstHexList {
        for secondHexIndex, secondHexChar in secondHexList {
            for pressReleaseModifierIndex, pressReleaseModifier in pressReleaseModifierList {
                ; Determine virtual key
                virtualNum=%firstHexChar%%secondHexChar%
                virtualKey=vk%virtualNum%
                hotkeyBase=%virtualKey%%pressReleaseModifier%
                
                ; There is no vk0
                if (virtualNum == "0")
                    continue
                
                ; Filter
                if (keyFilter != false){
                    if (negateKeyFilter ^ (RegExMatch(hotkeyBase, keyFilterRegex) == 0))
                        continue
                }
                
                ; Exceptional modifiers
                actualHotkeyModifiers := hotkeyModifiers
                actualHotkeyOptions := hotkeyOptions
                if (modifierOptionExceptions != false){
                    ; Check all the exceptions
                    for modifierOptionExceptionIndex, modifierOptionException in modifierOptionExceptions {
                        ; Check exception filter
                        if (RegExMatch(hotkeyBase, modifierOptionException.filter) > 0) {
                            if (modifierOptionException.HasKey("hotkeyModifiers"))
                                actualHotkeyModifiers := modifierOptionException.hotkeyModifiers
                            if (modifierOptionException.HasKey("hotkeyOptions"))
                                actualHotkeyOptions := modifierOptionException.hotkeyOptions
                            break
                        }
                    }
                }
                ;msgbox %actualHotkeyModifiers%%hotkeyBase%
                ; Register hotkey
                Hotkey, %actualHotkeyModifiers%%hotkeyBase%, %callback%, %actualHotkeyOptions%
            }
		}
	}

    if (autoDirective)
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

		mitmInput("singleKeyRecorder", true, "!up", "")
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
	return readSingleKey_readKeyName

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

; Get a value from a confih / ini file
; The benefit compared to IniRead is
; 
; NOTES
; - An empty value in the config is treated as if not defined at all
; 
; PARAMETER filePath - Path of the config / ini file
; PARAMETER sectionName - name of the section containing the key to read
; PARAMETER keyName - the name of the key to read
; PARAMETER defaultValue [any|"ThrowException"] (default: "ThrowException") - The value to use when the config key cannot be found
;   - any: Return the value
;   - "ThrowException": An exception is thrown
; PARAMETER validatorRegex [regex string] (default: "") - Validates the value. The validation is successful if the pattern can be found anywhere in the value
; PARAMETER invalidAction ["ThrowException"|"UseDefaultValue"] (default: "ThrowException") - The action to take in case the value is not valid
;   - "ThrowException": An exception is thrown
;   - "UseDefaultValue": Return the default value
; RETURN [string|any]
;   - string: The config value if the key is found, and the value is valid
;   - any: The provided default othervise (unless throwing an exception is set)
getConfigValue(filePath, sectionName, keyName, defaultValue := "ThrowException", validatorRegex := "", invalidAction := "ThrowException") {
    IniRead, configValue, %filePath%, %sectionName%, %keyName%, %A_Space%
	
    ; Key not found
    if (configValue == ""){
        if (defaultValue == "ThrowException")
            throw "The key could not be found`nFile: '" . filePath . "'`nSection: '" . sectionName . "'`nKey: '" . keyName . "'"
        else
            return defaultValue
    }
    
    ; Validate
    if (RegExMatch(configValue, validatorRegex) == 0) {
        if (invalidAction == "ThrowException" || (invalidAction == "UseDefaultValue" && defaultValue == "ThrowException"))
            throw "The value does not match the provided pattern`nValue: '" . configValue . "'`nPattern: '" . validatorRegex . "'"
        else if (invalidAction == "UseDefaultValue")
            return defaultValue
        else
            throw "The parameter 'invalidAction' does not match the required pattern`nValue: '" . invalidAction . "'`nPattern: 'ThrowException|UseDefaultValue'"
    }

    return configValue
}
