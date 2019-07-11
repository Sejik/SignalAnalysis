let SessionLoad = 1
if &cp | set nocp | endif
map  
vmap 	 >gv
map  :call VIMRCWordToggle()	"함수 호출에 대한 keymap
map  
nmap qa :qa			"전체 exit
nmap q :q					"파일 exit
nmap w :w!
nmap s :w
let s:cpo_save=&cpo
set cpo&vim
map hm <Plug>HexManager					"hex manager 호출!
map tf :tabnew:e .			"새 탭을 열면서 현재 폴더리스트
nmap d :Cscope d =expand("<cword>") =expand("%")
nmap i :Cscope i ^=expand("<cfile>")$
nmap f :Cscope f =expand("<cfile>")
nmap e :Cscope e =expand("<cword>")
nmap t :Cscope t =expand("<cword>")
nmap c :Cscope c =expand("<cword>")
nmap g :Cscope g =expand("<cword>")
nmap s :Cscope s =expand("<cword>")
map ,hf <Plug>HexFind
map ,hs <Plug>HexStatus
map ,ht <Plug>HexToggle
map ,hp <Plug>HexPrev
map ,hn <Plug>HexNext
map ,hg <Plug>HexGoto
map ,hi <Plug>HexInsert
map ,hd <Plug>HexDelete
nmap ,cwr <Plug>CVSWatchRemove
nmap ,cwf <Plug>CVSWatchOff
nmap ,cwn <Plug>CVSWatchOn
nmap ,cwa <Plug>CVSWatchAdd
nmap ,cwv <Plug>CVSWatchers
nmap ,cv <Plug>CVSVimDiff
nmap ,cu <Plug>CVSUpdate
nmap ,ct <Plug>CVSUnedit
nmap ,cs <Plug>CVSStatus
nmap ,cr <Plug>CVSReview
nmap ,cq <Plug>CVSRevert
nmap ,cl <Plug>CVSLog
nmap ,cg <Plug>CVSGotoOriginal
nmap ,ci <Plug>CVSEditors
nmap ,ce <Plug>CVSEdit
nmap ,cd <Plug>CVSDiff
nmap ,cc <Plug>CVSCommit
nmap ,cG <Plug>CVSClearAndGotoOriginal
nmap ,cn <Plug>CVSAnnotate
nmap ,ca <Plug>CVSAdd
map ,p :Project
map Q gq
vmap [% [%m'gv``
vmap ]% ]%m'gv``
vmap a% [%v]%
nmap gx <Plug>NetrwBrowseX
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
nnoremap <silent> <Plug>CVSWatchRemove :CVSWatchRemove
nnoremap <silent> <Plug>CVSWatchOff :CVSWatchOff
nnoremap <silent> <Plug>CVSWatchOn :CVSWatchOn
nnoremap <silent> <Plug>CVSWatchAdd :CVSWatchAdd
nnoremap <silent> <Plug>CVSWatchers :CVSWatchers
nnoremap <silent> <Plug>CVSVimDiff :CVSVimDiff
nnoremap <silent> <Plug>CVSUpdate :CVSUpdate
nnoremap <silent> <Plug>CVSUnedit :CVSUnedit
nnoremap <silent> <Plug>CVSStatus :CVSStatus
nnoremap <silent> <Plug>CVSReview :CVSReview
nnoremap <silent> <Plug>CVSRevert :CVSRevert
nnoremap <silent> <Plug>CVSLog :CVSLog
nnoremap <silent> <Plug>CVSClearAndGotoOriginal :CVSGotoOriginal!
nnoremap <silent> <Plug>CVSGotoOriginal :CVSGotoOriginal
nnoremap <silent> <Plug>CVSEditors :CVSEditors
nnoremap <silent> <Plug>CVSEdit :CVSEdit
nnoremap <silent> <Plug>CVSDiff :CVSDiff
nnoremap <silent> <Plug>CVSCommit :CVSCommit
nnoremap <silent> <Plug>CVSAnnotate :CVSAnnotate
nnoremap <silent> <Plug>CVSAdd :CVSAdd
nmap <Nul><Nul>d :vert split:Cscope d =expand("<cword>") =expand("%")
nmap <Nul><Nul>i :vert split:Cscope i ^=expand("<cfile>")$
nmap <Nul><Nul>f :vert split:Cscope f =expand("<cfile>")
nmap <Nul><Nul>e :vert split:Cscope e =expand("<cword>")
nmap <Nul><Nul>t :vert split:Cscope t =expand("<cword>")
nmap <Nul><Nul>c :vert split:Cscope c =expand("<cword>")
nmap <Nul><Nul>g :vert split:Cscope g =expand("<cword>")
nmap <Nul><Nul>s :vert split:Cscope s =expand("<cword>")
nmap <Nul>d :split:Cscope d =expand("<cword>") =expand("%")
nmap <Nul>i :split:Cscope i ^=expand("<cfile>")$
nmap <Nul>f :split:Cscope f =expand("<cfile>")
nmap <Nul>e :split:Cscope e =expand("<cword>")
nmap <Nul>t :split:Cscope t =expand("<cword>")
nmap <Nul>c :split:Cscope c =expand("<cword>")
nmap <Nul>g :split:Cscope g =expand("<cword>")
nmap <Nul>s :split:Cscope s =expand("<cword>")
map <F5> \pp
vmap <S-Tab> <gv
vnoremap <S-F12> :TrimSpaces
nnoremap <S-F12> m`:TrimSpaces``
nnoremap <C-F12> :ShowSpaces 1
map <F4> :51vs./	"20% 수직화면 분할하여 그곳에 현 디렉토리를 불러온다
cmap  CI !cvs commit %
inoremap  u
imap s :wli
imap normw :w!li
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set autowrite
set background=
set backspace=indent,eol,start
set backup
set cscopepathcomp=3
set cscopeprg=/usr/bin/cscope
set cscopequickfix=s-,c-,d-,i-,t-,e-
set cscopetag
set cscopeverbose
set diffopt=filler,iwhite
set fileencodings=latin1,ucs-bom,utf-8,korea
set formatoptions=tcql
set guicursor=n-v-c:block,o:hor50,i-ci:hor15,r-cr:hor30,sm:block,a:blinkon0
set helplang=ko
set hidden
set hlsearch
set incsearch
set laststatus=2
set lazyredraw
set listchars=tab:,_,trail:-,nbsp:%,extends:>,precedes:<
set matchpairs=(:),{:},[:],<:>
set matchtime=3
set omnifunc=python#Complete
set ruler
set scrolloff=3
set shiftwidth=4
set showbreak=>\ \ \\
set showcmd
set showmatch
set smartcase
set smartindent
set smarttab
set nostartofline
set statusline=(%n,%Y)%<%f[%{SetMyStsLineVar()}]\ %h%m%r%=[%b:0x%B,%o:0x%O]\ %-14.(#(%L)%l,%c%V%)\ %P
set suffixes=.bak,~,.o,.h,.info,.swp,.obj,.asv
set tabstop=4
set tags=tags\ ~/nxtool/nxlib/tags\ ~/nxtool/svcgen/tags\ ~/nxtool/sqlw/tags
set textwidth=78
set title
set updatetime=10
set viminfo='20,\"50
set visualbell
set wildmenu
set nowrapscan
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd /home/minlab/MATLAB/GaborPatch
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +205 gabor_main.m
badd +1 0
badd +1 gabor_base.m
args gabor_main.m
edit gabor_base.m
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe 'vert 1resize ' . ((&columns * 81 + 81) / 163)
exe 'vert 2resize ' . ((&columns * 81 + 81) / 163)
argglobal
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal noexpandtab
if &filetype != 'matlab'
setlocal filetype=matlab
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
set foldmarker=-[,-]
setlocal foldmarker=-[,-]
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=0
setlocal include=
setlocal includeexpr=
setlocal indentexpr=GetMatlabIndent(v:lnum)
setlocal indentkeys=!,o,O=end,=case,=else,=elseif,=otherwise,=catch
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
set linebreak
setlocal linebreak
setlocal nolisp
set list
setlocal list
setlocal makeprg=
setlocal matchpairs=(:),{:},[:],<:>
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=python#Complete
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.m
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'matlab'
setlocal syntax=matlab
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=78
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 18 - ((3 * winheight(0) + 27) / 54)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
18
normal! 0
wincmd w
argglobal
edit gabor_main.m
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:-
setlocal commentstring=/*%s*/
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal noexpandtab
if &filetype != 'matlab'
setlocal filetype=matlab
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
set foldmarker=-[,-]
setlocal foldmarker=-[,-]
set foldmethod=marker
setlocal foldmethod=marker
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=0
setlocal include=
setlocal includeexpr=
setlocal indentexpr=GetMatlabIndent(v:lnum)
setlocal indentkeys=!,o,O=end,=case,=else,=elseif,=otherwise,=catch
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
set linebreak
setlocal linebreak
setlocal nolisp
set list
setlocal list
setlocal makeprg=
setlocal matchpairs=(:),{:},[:],<:>
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=python#Complete
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=4
setlocal noshortname
setlocal smartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.m
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'matlab'
setlocal syntax=matlab
endif
setlocal tabstop=4
setlocal tags=
setlocal textwidth=78
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
291
normal! zo
let s:l = 58 - ((47 * winheight(0) + 27) / 54)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
58
normal! 0
wincmd w
2wincmd w
exe 'vert 1resize ' . ((&columns * 81 + 81) / 163)
exe 'vert 2resize ' . ((&columns * 81 + 81) / 163)
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
