vim-tabularity
==============

Inspired by Tabular plugin for vim (and partially by Sublime Text), and slightly disappointed that it doesn't do as much as it could with its power, I decided to extend it (turns out, however, I only needed Tabular plugin for a small fraction of the functionality). Tabularity helps you manipulate multiple rows of data at once, and stacks well with other plugins, like vim-surround and Tabular.

What makes Tabularity special is its ability to detect relevant rows (below and above the cursor) that follow similar structure and apply a given command to all of them. This allows Tabularity to automate things Tabular wouldn't due to fear of false positives. This also allows Tabularity to invoke any other set of vim commands on each relevant line.

Usable Functions
================

	tabularity#Align()      Works like `Tabular /[string]` but is better at detecting relevant bounds
	tabularity#Command()    Perform a sequence of normal-mode commands passed to it as a string
	tabularity#Do()         Like the above function, but waits for the user to put in the command after being called
	tabularity#Unfold()     Convert a sequence of words to a sequence of rows
	tabularity#Fold()       Convert a sequence of rows to a single-line sequence of words
	tabularity#Complete()   Complete all rows by using other rows that start the same way in this file

Common Use Cases
================

Tabular plugin lets you effortlessly align multiple rows by specifying a pivoting character sequence to use. Unfortunately, it will erroneously align parent element in this Perl hash when using `=>` for alignment:

	foo = > {
		bar => 1,
		bazz => 2,
	}

Tabularity will not make the same mistake. You can use Tabularity's Align function to specify a delimiter to align on, and also an optional regex to use for detecting range bounds. For example, to auto-align all rows on `=>` in Perl automatically, you can add the following mapping to your `ftplugin/perl.vim`:

	inoremap => =><Esc>:call tabularity#Align('=>')<CR>a

But that's just the tip of the iceberg. Imagine you're cleaning up some Perl code, and wish to convert the following array of N items (where N is a really large number) to standard array format, as seen in other languages:

	qw(
		foo
		bar
		...
		baz
	)

Even with vim-surround, this is going to be a tedious task. You'll have no problem changing one of them, but applying it to all lines will take a while (even with `.` to repeat the last command). With Tabularity, however, you simply place the cursor on one of the intermediate rows, call `tabularity#Do()` function, and enter the command you'd typically pass to vim-surround to update one word and add a comma at the end: `ysiw"A,`. This will result in:

	qw(
		"foo",
		"bar",
		...
		"baz",
	)

Now all you need to do is modify the surrounding brackets. Likewise, if you wanted to convert the following into a Perl array format:

	[
		"foo",
		"bar",
		...
		"baz",
	]

You would simply need to run `:call tabularity#Do()` and enter `ds"A<Del>`. Tabularity will perform the command based on cursor position, so if you have the following sequence:

	magenta ball
	red box
	yellow cone

And your cursor was at the end of the word `magenta`, using Tabularity to quote the first word would result in:

	"magenta" ball
	red "box"
	"yellow" cone

To avoid this, you can either move the cursor to a different position before executing the command or use Tabular to align the words beforehand (`Tab / ` should do the trick). If you prefix your command with a `:`, Tabularity will execute it as if you used `:` in vim on each line it decides is relevant.

Another userful functionality of Tabularity is folding/unfolding words into rows. For example, imagine you have the following string:

	The quick brown fox jumped over the lazy dog

Running `tabularity#Unfold()` on it, will produce the following result:

	The 
	quick 
	brown 
	fox 
	jumped 
	over 
	the 
	lazy 
	dog

This unfolding will also make use of your indentation/language settings. Which means that if you're working in Perl and the original line looked like this:

	#	The quick brown fox jumped over the lazy dog

The result will be:


	#	The 
	#	quick 
	#	brown 
	#	fox 
	#	jumped 
	#	over 
	#	the 
	#	lazy 
	#	dog

`tabularity#Fold()` will perform the reverse operation.

Speaking of comments, if you ever had to write docstrings for functions, you know how much of a pain it can be to make sure they are consistent and up-to-date. Adding a new function with a docstring to an already-existing behemoth module can be annoying. You know what arguments it needs, but the descriptions for them will need to be copy-pasted from other docstrings. `tabularity#Complete()` will handle that for you automatically, it will search the file for other lines beginning the same way, and complete each line using the first-found match.
