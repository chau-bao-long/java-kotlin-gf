function! gf#openFile(...)
  exe "silent! Rooter"

  let command = get(a:, 1, 'e')
  let projectPath = getcwd()

  if s:jumpToFileInSamePackage(command)
    return
  endif

  if s:jumpToExactMatchPath(command, projectPath)
    return
  else
    " try again to looking for import line corresponding to current word
    execute "silent! normal! /import .*" . expand('<cword>') . "$\<cr>"

    if s:jumpToExactMatchPath(command, projectPath)
      return
    endif
  endif

  if s:jumpToMethod(command, projectPath)
    return
  endif

  if s:jumpToFileByFuzzySearch(command, g:libPath)
    return
  endif

  exe "silent! AnyJump"
endfunction

function s:jumpToExactMatchPath(command, projectPath)
  let words = split(getline('.'), '\W\+') " [import, org, spring, http, HttpStatus]
  let relativeSourcePath  = join(words[1:], '/') " words[1:] to remove the import word: org, spring, http, HttpStatus => result: org/spring/http/HttpStatus

  let paths = [
        \ g:libPath . "/" . relativeSourcePath . '.java',
        \ g:libPath . "/" . relativeSourcePath . '.kt',
        \ ]

  for srcPath in g:srcPath
    call add(paths, a:projectPath . srcPath . relativeSourcePath . '.java')
    call add(paths, a:projectPath . srcPath . relativeSourcePath . '.kt')
  endfor

  for path in paths
    if filereadable(expand(l:path))
      execute a:command . ' ' . path
      return 1
    endif 
  endfor

  return 0
endfunction

fu s:jumpToMethod(command, projectPath)
  let words = split(getline('.'), '\W\+') " [import, org, spring, http, HttpStatus, methodName]
  let isMethod = s:isLowerCase(words[-1])
  let isMethodInFile = !s:isLowerCase(words[-2])

  if !isMethod || !isMethodInFile
    return 0
  endif

  let relativeSourcePath  = join(words[1:-2], '/') " words[1:-2] to remove the import word: org, spring, http, HttpStatus, methodName => result: org/spring/http/HttpStatus

  let paths = [
        \ g:libPath . "/" . relativeSourcePath . '.java',
        \ g:libPath . "/" . relativeSourcePath . '.kt',
        \ ]

  for srcPath in g:srcPath
    call add(paths, a:projectPath . srcPath . relativeSourcePath . '.java')
    call add(paths, a:projectPath . srcPath . relativeSourcePath . '.kt')
  endfor

  for path in paths
    if filereadable(expand(l:path))
      exe a:command . ' ' . path
      exe "silent! normal! /" . words[-1] . "(.*).*[=|{]\<cr>"
      return 1
    endif 
  endfor

  return 1
endfu

function s:jumpToFileInSamePackage(command)
  let javaPath = expand("%:p:h") . '/' . expand('<cword>') . '.java'
  let kotlinPath = expand("%:p:h") . '/' . expand('<cword>') . '.kt'
  let javaTestPath = substitute(expand("%:p:h"), "main", "test", "") . '/' . expand('<cword>') . '.java'
  let javaMainPath = substitute(expand("%:p:h"), "test", "main", "") . '/' . expand('<cword>') . '.java'
  let kotlinTestPath = substitute(expand("%:p:h"), "main", "test", "") . '/' . expand('<cword>') . '.kt'
  let kotlinMainPath = substitute(expand("%:p:h"), "test", "main", "") . '/' . expand('<cword>') . '.kt'

  for path in [javaPath, kotlinPath, javaTestPath, javaMainPath, kotlinTestPath, kotlinMainPath]
    if filereadable(expand(l:path))
      execute a:command . ' ' . path
      return 1
    endif
  endfor

  return 0
endfunction

function s:jumpToFileByFuzzySearch(command, path)
  let queryStringExactName = "find " . a:path . " -type f -name '" . expand('<cword>'). ".java' -o -name '" . expand('<cword>'). ".kt'"
  let resultsFromFind = system(expand(l:queryStringExactName))
  let results = split(resultsFromFind, "\n")

  if len(results) == 0
    let queryStringFuzzyTheEnd = "find " . a:path . " -type f -name '" . expand('<cword>'). "*'"
    let resultsFromFind = system(expand(l:queryStringFuzzyTheEnd))
    let results = split(resultsFromFind, "\n")
    if len(results) == 0
      return 0
    elseif len(results) == 1
      execute ":tabedit " results[0]
      execute a:command . ' ' . results[0]
    else
      " open a fuzzy finder helping user choose the file with type of 'CurrentWord*' which has more than 2 results found
      call fzf#run(fzf#wrap({'source': expand(l:queryStringFuzzyTheEnd)}))
    endif
  elseif len(results) == 1
    execute a:command . ' ' . results[0]
  else
    " open a fuzzy finder helping user choose the file with type of 'CurrentWord*' which has more than 2 results found
    call fzf#run(fzf#wrap({'source': expand(l:queryStringExactName)}))
  endif
  
  return 1
endfunction

fu s:isLowerCase(word)
  return char2nr(a:word[0]) != char2nr(toupper(a:word[0]))
endfu
