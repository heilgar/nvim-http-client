if exists("b:current_syntax")
  finish
endif

syn match httpResponseTitle "^\(Response\|Dry Run\) Information:"
syn match httpResponseMethod "\v(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)"
syn match httpResponseHeader "^[A-Za-z0-9-]\+:"
syn match httpResponseVariable "{{[^}]\+}}"
syn region httpResponseBody start="{" end="}" fold transparent
syn match httpResponseComment "^#.*$"
syn match httpResponseSeparator "^---------------------$"
syn match httpResponseStatus "Status: \zs.*$"

" New syntax rules for environment information
syn match httpResponseEnvTitle "^Environment Information:"
syn match httpResponseEnvFile "Current env file: \zs.*$"
syn match httpResponseEnvKey '"\zs[^"]\+\ze":'
syn match httpResponseEnvValue ':\s*\zs.*$'

" XML syntax
syn include @XMLSyntax syntax/xml.vim
syn region xmlRegion start="<\w" end="</\w\+>" contains=@XMLSyntax

" Define highlight groups for XML
hi def link xmlTag Identifier
hi def link xmlTagName Statement
hi def link xmlAttrib Identifier
hi def link xmlString String
hi def link xmlComment Comment


hi def link httpResponseTitle Structure
hi def link httpResponseMethod Keyword
hi def link httpResponseHeader Identifier
hi def link httpResponseVariable Special
hi def link httpResponseBody Normal
hi def link httpResponseComment Comment
hi def link httpResponseSeparator Structure
hi def link httpResponseStatus Special

" New highlight groups for environment information
hi def link httpResponseEnvTitle Structure
hi def link httpResponseEnvFile Special
hi def link httpResponseEnvKey Identifier
hi def link httpResponseEnvValue String

let b:current_syntax = "http_response"

