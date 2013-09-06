" Tabularity:  Manipulate columnar and sequential data
" Maintainer:  Alexander Tsepkov (atsepkov@pyjeon.com)
" Date:        8/5/2013
" Version:     1.0
"
" Long Description:
" Inspired by Tabular plugin for vim (and partially by Sublime Text), and
" slightly disappointed that it doesn't do as much as it could with its power,
" I decided to extend it. This plugin requires tabular to be installed to work
" and extends its functionality to auto-align rows for you upon detection of
" a certain delimeter but also perform certain action on multiple rows/words,
" similar to Sublime Text
"
" License:
" Copyright (c) 2013, Alexander Tsepkov
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"     * Redistributions of source code must retain the above copyright notice,
"       this list of conditions and the following disclaimer.
"     * Redistributions in binary form must reproduce the above copyright
"       notice, this list of conditions and the following disclaimer in the
"       documentation and/or other materials provided with the distribution.
"     * The names of the contributors may not be used to endorse or promote
"       products derived from this software without specific prior written
"       permission.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
" OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
" OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
" NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY DIRECT, INDIRECT,
" INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
" LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
" OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
" LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
" NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
" EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


" private functions
function! s:getRange(...)
	" if 'validation' regex was provided, check if the line matches it before
	" attempting any further logic
	let l = getline('.')
	if a:0 > 0
		if l !~# a:1
			return
		endif
	endif

	" first count back and forward based on indent to figure out when to stop
	let s = line('.')
	let f = s
	let myindent = indent(s)
	while indent(s-1) == myindent && (a:0 == 0 || getline(s-1) =~# a:1)
		let s -= 1
	endwhile
	while indent(f+1) == myindent && (a:0 == 0 || getline(f+1) =~# a:1)
		let f += 1
	endwhile
	if s == f
		return
	endif

	return s . ',' . f
endfunction


" This function can be used by various languages to auto-align lines based on
" a certain delimeter. In perl, for example, one could auto-align hashes on =>
" Takes a delimeter to use for aligning and optional regex to test against
" each line in range to remove false positives.
"
" Usage examples:
"	Perl:	inoremap <silent> > ><Esc>:call tabularity#Align('=>')<CR>a
"	Python:	inoremap <silent> : :<Esc>:call tabularity#Align(':', '\[\'"\]\?\[A-Za-z_-\]\[A-Za-z0-9_-\]*\[\'"\]\:')<CR>a
function! tabularity#Align(delim, ...)
	let p = '^.*' . a:delim . '\s.*$'
	if exists(':Tabularize') && getline('.') =~# '^.*' . a:delim && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
		if a:0 > 0
			let range = s:getRange(a:1)
		else
			let range = s:getRange()
		endif
		let column = strlen(substitute(getline('.')[0:col('.')],'[^' . a:delim[0] . ']','','g'))
		let position = strlen(matchstr(getline('.')[0:col('.')],'.*' . a:delim . '\s*\zs.*'))
		let pos = getpos('.')
		execute range . 'Tabularize/' . a:delim . '/l1'
		call setpos('.', pos)
		normal! 0
		call search(repeat('[^' . a:delim[0] . ']*' . a:delim ,column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
	endif
endfunction


" This function applies a certain command to all consecutive lines matching
" the format of current line
function! tabularity#Command(command, ...)
	if a:0 > 0
		let range = s:getRange(a:1)
	else
		let range = s:getRange()
	endif
	let pos = getpos('.')
	let column = col('.')
	execute range . ' normal ' . column . 'lb ' . a:command
	call setpos('.', pos)
endfunction


" Wraps the above function for easy user input
function! tabularity#Do(...)
	let result = input('')
	if a:0 > 0
		let range = tabularity#Command(result, a:1)
	else
		let range = tabularity#Command(result)
	endif
endfunction


" This function takes a sequence of words and converts them to sequence of
" rows, inheriting indentation level of the first word
function! tabularity#Unfold(...)
	if a:0 > 0
		let delim = a:1
	else
		let delim = ' '
	endif
	let pos = getpos('.')
	normal ^
	let m = col('.')
	normal $B
	let c = col('.')
	while c > m
		normal ik$B
		let c = col('.')
	endwhile
	call setpos('.', pos)
endfunction


" This function effectively undoes the unfolding done by the previous one
function! tabularity#Fold(...)
	if a:0 > 0
		let delim = a:1
	else
		let delim = ' '
	endif
	let range = s:getRange()
	execute range . ' normal ^d0i'
"	normal Bi
endfunction
