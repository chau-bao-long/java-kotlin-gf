# java-kotlin-gf
Improve go to file (gf) experience on java/kotlin project

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'chau-bao-long/java-kotlin-gf'
```

## Quick Start
Run GradleSyncSource command first, and gf or gF to see the magic

## Commands

### To go to the file in current buffer, new tab, vertical or horizontal split
```vim
GoToFile ['e'|'tabnew'|'sp'|'vs'] 
```

### To extract source from gradle, which access by gf
```vim
GradleSyncSource
```
