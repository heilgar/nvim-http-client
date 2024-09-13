if exists("b:current_syntax")
  finish
endif

" XML syntax elements
syn match xmlTag "<[^>]*>" contains=xmlTagName,xmlAttrib
syn match xmlTagName "<\w\+>" contained
syn match xmlAttrib "\w\+=" contained
syn match xmlString "\"[^\"]*\"" contained
syn match xmlComment "<!--.*-->" contains=xmlCommentStart,xmlCommentEnd
syn match xmlCommentStart "<!--" contained
syn match xmlCommentEnd "-->" contained

" XML namespace declarations
syn match xmlNamespace "xmlns\?=" contained

" XML entity references
syn match xmlEntity "&[^;]*;" contained

" Highlighting
hi def link xmlTag Statement
hi def link xmlTagName Function
hi def link xmlAttrib Identifier
hi def link xmlString String
hi def link xmlComment Comment
hi def link xmlCommentStart Comment
hi def link xmlCommentEnd Comment
hi def link xmlNamespace PreProc
hi def link xmlEntity Special

let b:current_syntax = "xml"

