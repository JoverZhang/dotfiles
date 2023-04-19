function! WordCount()
  let l:text = join(getline(1,'$'), "\n")
  return system('python3 $HOME/.vim/scripts/wordcount.py', l:text)
endfunction

function! airline#extensions#wordcount#formatters#hans#to_string(wordcount)
  return '' . a:wordcount . ':' . WordCount() . ' words '
endfunction

let g:airline#extensions#wordline#formatter = 'hans'
