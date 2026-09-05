function! WordCount()
  let l:text = join(getline(1,'$'), "\n")
  let l:script = findfile('scripts/wordcount.py', &runtimepath)
  return system('python3 ' . shellescape(l:script), l:text)
endfunction

function! airline#extensions#wordcount#formatters#hans#to_string(wordcount)
  return '' . a:wordcount . ':' . WordCount() . ' words '
endfunction

let g:airline#extensions#wordline#formatter = 'hans'
