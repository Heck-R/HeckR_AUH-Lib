
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

; Tells wether the given path points to a file
isFile(path) {
    attributes := fileExist(path)
    return (attributes && !InStr(attributes, "D"))
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
        Throw "A subset cannot contain more elements that the set itself`nSet element number: " . elements.MaxIndex() . "`nSubset element number: " . subSetSize

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
