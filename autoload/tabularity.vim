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
function! s:detectCommonPrefix(cur, prev, next)
	" if one of the strings is completely identical to cur, it will be
	" skipped,if both are, the return value is entire length of the string
	" NOTE: this is essentially n^2 algorithm now due to the substring check
	" inside the while loop, this could be optimized to n if we modify it to
	" only check the last character
	if a:next == a:cur && a:prev == a:cur
		return len(a:cur)-1
	endif
	let l = 0
	if a:prev != a:cur
		let ok = 1
	endif

	" try previous first
	while ok
		if a:prev[0:l] == a:cur[0:l]
			let l += 1
		else
			let ok = 0
		endif
	endwhile

	" see if next one goes further
	if a:next != a:cur
		let ok = 1
	endif
	let n = 0
	while ok
		if a:next[0:l] == a:cur[0:l]
			let n = 1
			let l += 1
		else
			let ok = 0
		endif
	endwhile

	" now undo any same characters from prefix if they're in the middle of a
	" word that hasn't finished
	if n
		let cmp = a:next
	else
		let cmp = a:prev
	endif
	while (cmp[l-1] =~ '[a-z0-9_]' && cmp[l] =~ '[a-z0-9_]') || (a:cur[l-1] =~ '[a-z0-9_]' && a:cur[l] =~ '[a-z0-9_]')
		let l -= 1
	endw
	return l-1
endfunction

function! s:getRange(...)
	" if 'validation' regex was provided, check if the line matches it before
	" attempting any further logic
	" if no validation regex was provided, the common non-mid-word prefix
	" between previous or next line will be used in its place.
	let s = line('.')
	let l = getline('.')
	if a:0 > 0
		if l !~# a:1
			return
		endif
		let pattern = a:1
	else
		let n = s:detectCommonPrefix(l, getline(s-1), getline(s+1))
		if n == -1
			" auto fail
			let pattern = '^$'
		else
			let pattern = '^' . substitute(l[0:n], '[&|*.^$]', '\\\0', 'g') . '.*'
		endif
	endif

	" first count back and forward based on indent to figure out when to stop
	let f = s
	let myindent = indent(s)
	while indent(s-1) == myindent && getline(s-1) =~# pattern
		let s -= 1
	endwhile
	while indent(f+1) == myindent && getline(f+1) =~# pattern
		let f += 1
	endwhile
	if s == f
		return
	endif

	return [s, f]
endfunction

function! s:getChar()
	let c = getchar()
	if c =~ '^\d\+$'
		let c = nr2char(c)
	endif
	return c
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
		execute range[0] . ',' . range[1] . 'Tabularize/' . a:delim . '/l1'
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
	if a:command[0] == ':'
		execute range[0] . ',' . range[1] . a:command[1:]
	else
		execute range[0] . ',' . range[1] . ' normal ' . column . 'lb ' . a:command
	endif
	call setpos('.', pos)
endfunction


" Wraps the above function for easy user input
function! tabularity#Do(...)
	let seq = ''
	let c = s:getChar()
	while c != "\<CR>"
		let seq .= c
		let c = s:getChar()
	endwhile
	if a:0 > 0
		call tabularity#Command(seq, a:1)
	else
		call tabularity#Command(seq)
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
	let s = line('.')
	let l = getline('.')
	if a:0 > 0
		let range = s:getRange(a:1)
	else
		let range = s:getRange()
	endif
	let n = s:detectCommonPrefix(l, getline(s-1), getline(s+1))
	while range[1] > range[0]
		execute range[1]
		let l = getline(range[1])
		let p = substitute(l[0:n], '[&|*.^$]', '\\\0', 'g')
		execute 'silent! s/^' . p . '/ /'
		normal ^d0i
		let range[1] -= 1
	endwhile
endfunction


" This function finishes the line using other lines that start the same way in
" this file, in case of multiple matches, picks first-found match
function! tabularity#Complete(...)
	if a:0 > 0
		let range = s:getRange(a:1)
	else
		let range = s:getRange()
	endif
	let pos = getpos('.')
	let flags = 'nb'
	while range[0] <= range[1]
		let n = search('^' . getline(range[0]))
		let l = substitute(getline(n), '[&|*.^$]', '\\\0', 'g')
		execute 'silent! ' . range[0] .'s/^.*$/' . l . '/'
		let range[0] += 1
		normal j
	endwhile
	call setpos('.', pos)
endfunction
