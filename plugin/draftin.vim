if exists("g:draftin_loaded")
    finish
endif
let g:draftin_loaded = 1
let g:draftin_enabled = 1

let s:draftin_endpoint = "https://draftin.com/api/v1/documents.json"

command Draft call <SID>Draft()

" Upload the current buffer to draftin.com
function! s:Draft()
    if !exists("g:draftin_auth")
        echo "Ensure draftin_auth is set in .vimrc as username:password"
        return
    endif

    if g:draftin_enabled != 1
        return
    endif

    let l:name = getline(1)
    " Use filename if there's no first line.
    if strlen(l:name) < 1
        let l:name = shellescape(expand('%:t'))
    endif

    let l:content = join(getline(1, line("$")), "\\n")

    let l:json = '{"content": "'.l:content.'", "name": "'.l:name.'"}'

    let l:curlPost = "curl -u ". g:draftin_auth
    let l:curlPost .= " -X POST -H 'Content-Type: application/json'"
    let l:curlPost .= " -d '".l:json."' "
    let l:curlPost .= s:draftin_endpoint

    let l:res = system(l:curlPost)
    echo "Document uploaded"

endfunction
