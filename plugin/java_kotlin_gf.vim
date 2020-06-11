let s:srcPath = [
      \ "/app/src/main/kotlin/",
      \ "/app/src/test/kotlin/",
      \ "/src/main/kotlin/",
      \ "/src/test/kotlin/",
      \ ]
let g:srcPath = s:srcPath + g:srcPath
let g:libPath = $HOME . "/.gradle/src"
let s:bin_dir = expand('<sfile>:h:h').'/bin/'

command! -nargs=? -bar GoToFile call gf#openFile(<f-args>)
command! GradleSyncSource execute "terminal " . s:bin_dir . 'sync_gradle_src.sh'  

autocmd Filetype kotlin,java,groovy nmap gf :GoToFile<cr>
autocmd Filetype kotlin,java,groovy nmap gF :GoToFile tabedit<cr>
