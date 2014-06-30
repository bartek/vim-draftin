if exists("g:draftin_loaded")
    finish
endif
let g:draftin_loaded = 1
let g:draftin_enabled = 1

let s:draftin_doc_create_endpoint = "https://draftin.com/api/v1/documents.json"
let s:draftin_doc_update_endpoint = "https://draftin.com/api/v1/documents/"

command Draft call <SID>Draft()

function! s:MetadataFilename()
    return expand('%:h') . "/." . expand('%:t') . ".meta"
endfunction

function! s:ReadDocMetadata()
    let l:mdfilename = s:MetadataFilename() 
    echo "Looking for file " . l:mdfilename
    if (filereadable(l:mdfilename))
        execute 'source' l:mdfilename
    endif
endfunction

function! s:WriteDocMetadata(metadata)
    let l:mdfilename = s:MetadataFilename() 
    echo "Looking for file to write " . l:mdfilename
    let l:mdlines = []
    let l:relevantKeys = ['id']
    for key in relevantKeys 
        echo "Writing metadata field " . key
        call add(l:mdlines, "let g:draftin_" . key . " = '" . a:metadata[key] . "'")
    endfor
    call writefile(l:mdlines, l:mdfilename)
endfunction

" Upload the current buffer to draftin.com
function! s:Draft()
    if !exists("g:draftin_vim_auth")
        echo "Ensure draftin_auth is set in .vimrc as username:password or better,"
        echo "put it in a different file that is source by your vimrc"
        return
    endif

    if g:draftin_enabled != 1
        return
    endif

    let l:curl_method = "POST"

    let l:name = getline(1)
    " Use filename if there's no first line.
    if strlen(l:name) < 1
        let l:name = shellescape(expand('%:t')) 
    endif

    call s:ReadDocMetadata()
    let l:creating = 1
    if exists("g:draftin_id")
        let l:creating = 0
        let l:curl_method = "PUT"
    endif

    let l:content = join(getline(1, line("$")), "\\n")
    let l:json = '{"content": "'.l:content.'", "name": "'.l:name.'"}'

    let l:curlCmd = "curl -s -u ". g:draftin_vim_auth . " -X " . curl_method
    let l:curlCmd .= " -H 'Content-Type: application/json'"
    let l:curlCmd .= " -d '".l:json."' "
    if (l:creating)
        let l:curlCmd .= s:draftin_doc_create_endpoint
    else
        let l:curlCmd .= s:draftin_doc_update_endpoint . g:draftin_id . ".json"
    endif

    echo "Executing " . l:curlCmd

    let l:rawres = system(l:curlCmd)
    if (l:creating)
        echo l:rawres
        let l:res = ParseJSON(l:rawres)
        call s:WriteDocMetadata(l:res)
    endif

    if (l:creating)
        echo "Document " . l:name . " created and uploaded"
    else
        echo "Document " . l:name . " updated"
    endif

endfunction
