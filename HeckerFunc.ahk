
join(sep, params*) {
    for index,param in params
        str .= sep . param
    return SubStr(str, StrLen(sep)+1)
}

pathify(params*) {
	return join("\", params*)
}