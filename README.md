# java-kotlin-gf
Improve go to file (gf) experience on java/kotlin project

## Installation

### Dependencies
This plugin work best when combine with these plugins:
- Fzf
```vim
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
```
- AnyJump
```vim
Plug 'pechorin/any-jump.vim'
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'chau-bao-long/java-kotlin-gf'
```

## Quick Start
```vimscript
nmap gf :GoToFile<cr>
nmap gT :GoToFile tabedit<cr>
```
Run GradleSyncSource command first, and gf or gT to see the magic

## Commands

### To go to the file in current buffer, new tab, vertical or horizontal split
```vim
GoToFile ['e'|'tabnew'|'sp'|'vs'] 
```

### To extract source from gradle, which access by gf
```vim
GradleSyncSource
```
## Configuration
- Add more src path and test path to allow gf to detect file 
```vim
let g:srcPath = [
      \ "/app/src/main/kotlin/",
      \ "/app/src/test/kotlin/",
      \ "/src/main/kotlin/",
      \ "/src/test/kotlin/",
      \ ]
```

- Change where to keep extracted source lib
```vim
let g:libPath = "~/.gradle/src"
```
