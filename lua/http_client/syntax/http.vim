" Syntax definitions for HTTP files

syntax match HttpMethod "\v^(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD)"
syntax match HttpUrl "\vhttps?://[^\s]+"
syntax match HttpHeader "\v^[\w-]+: .+"
syntax match HttpJson "\v{\_.{-}}"
syntax match HttpXml "\v<\w+>(.|\n)*?</\w+>"

" Highlight groups
highlight link HttpMethod Keyword
highlight link HttpUrl String
highlight link HttpHeader Type
highlight link HttpJson PreProc
highlight link HttpXml PreProc

