Sub Main
	For Each hf In HistoryFiles
		hf.Open
	Next

	MsgBox "All history files are open"

	For Each hf In HistoryFiles
		hf.Close
	Next
End Sub
