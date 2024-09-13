" Vim syntax file
" Language: HTTP
" Maintainer: Your Name
" Latest Revision: Date

if exists("b:current_syntax")
  finish
endif

syn match httpMethod "GET\|POST\|PUT\|DELETE\|PATCH\|HEAD\|OPTIONS"
syn match httpHeader "^[A-Za-z0-9-]\+:"
syn match httpVariable "{{[^}]\+}}"
syn region httpBody start="{" end="}" fold transparent
syn match httpComment "^#.*$"
syn match httpSeparator "^###$"
syn match httpVersion "HTTP/1\.1\|HTTP/2\|HTTP/2 (Prior Knowledge)"

hi def link httpMethod Keyword
hi def link httpHeader Identifier
hi def link httpVariable Special
hi def link httpComment Comment
hi def link httpSeparator Structure
hi def link httpVersion Special

let b:current_syntax = "http"

