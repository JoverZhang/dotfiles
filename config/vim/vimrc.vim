" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif


" vim-plug
call plug#begin()

" airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme='simple'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#wordcount#filetypes =
    \ ['asciidoc', 'help', 'mail', 'markdown', 'fmtmd', 'rmd',
    \ 'nroff', 'org', 'plaintex', 'rst', 'tex', 'text']
let g:airline#extensions#wordcount#formatter = 'hans'

" vim-easy-align
Plug 'junegunn/vim-easy-align'

" git
Plug 'airblade/vim-gitgutter'

" markdown
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
let g:vim_markdown_folding_disabled = 1
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && pnpm install' }

call plug#end()


" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup          " do not keep a backup file, use versions instead
else
  set backup            " keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile        " keep an undo file (undo changes after closing)
  endif
endif

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 80 characters.
  autocmd FileType text setlocal textwidth=80
augroup END

" Add optional packages.
"
" The matchit plugin makes the % command work better, but it is not backwards
" compatible.
" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
if has('syntax') && has('eval')
  packadd! matchit
endif


" Configurations
set number
set autoindent expandtab tabstop=2 shiftwidth=2
set clipboard=unnamedplus
set sms " smoothscroll

" markdown
autocmd bufreadpre *.md set conceallevel=2

" format fmtmd (clear newline and copy for translate software)
autocmd BufNewFile,BufRead *.fmtmd set filetype=fmtmd
autocmd FileType fmtmd nmap <C-f> :%s/\n/ / \| nohlsearch \| yank<CR>

" keybindings
let mapleader = " "
" direction
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
map <silent> <Up> gk
imap <silent> <Up> <C-o>gk
map <silent> <Down> gj
imap <silent> <Down> <C-o>gj
map <silent> <home> g<home>
map <silent> <End> g<End>
nnoremap <expr> j (v:count == 0 ? 'gj' : 'j')
nnoremap <expr> k (v:count == 0 ? 'gk' : 'k')
" quick keys
nmap <C-s> :w<CR>
imap <C-s> <esc>:w<CR>
nmap <leader>qq :qall<CR>
" buffer
nnoremap H :bprevious<CR>
nnoremap L :bnext<CR>
nnoremap <leader>bd :bdelete<CR>
" tab
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>th :tabprevious<CR>
nnoremap <leader>tl :tabnext<CR>
" Explore
nmap <leader>e :Explore<CR>


setlocal linebreak
setlocal nolist
setlocal display+=lastline

