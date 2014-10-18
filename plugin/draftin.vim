if exists("g:draftin_loaded")
    finish
endif
let g:draftin_loaded = 1
let g:draftin_enabled = 1

let s:draftin_doc_create_endpoint = "https://draftin.com/api/v1/documents.json"
let s:draftin_doc_update_endpoint = "https://draftin.com/api/v1/documents/"

command -nargs=? Draft call <SID>Draft(<f-args>)
command -nargs=1 DraftRename call <SID>DraftRename(<f-args>)

function! s:CheckDraftRunnable()
    if !exists("g:draftin_vim_auth")
        echo "Ensure draftin_auth is set in .vimrc as username:password or better,"
        echo "put it in a different file that is source by your vimrc"
        return 0
    endif

    if !g:draftin_enabled
        echo "vim-draftin has been disabled, look for ''g:draftin_enabled'' in your"
        echo "vim config files."
        return 0
    endif

    return s:CheckDependencies()
endfunction

function! s:CheckDependencies()
    if !exists("g:loaded_jsoncodecs")
        echo "vim-draftin depends on jsoncodecs.vim for escaping"
        echo "https://github.com/vim-scripts/jsoncodecs.vim"
        return 0
    endif

    if !exists("g:loaded_parsejson") 
        echo "vim-draftin depends on ParseJSON for reply parsing"
        echo "https://github.com/vim-scripts/ParseJSON"
        return 0
    endif

    if !executable("curl")
        echo "vim-draftin depends on curl to send messages to draftin.com, but"
        echo "it appear to not be installed."
        return 0
    endif

    return 1
endfunction

function! s:MetadataFilename()
    return expand('%:h') . "/." . expand('%:t') . ".meta"
endfunction

function! s:DocUpdateEndpoint()
    return s:draftin_doc_update_endpoint . b:draftin_id . ".json"
endfunction

function! s:DocGetEndpoint()
    return s:draftin_doc_update_endpoint . b:draftin_id . ".json"
endfunction

function! s:UpdateDocMetadata()
    let l:rawres = s:GetFromDraft(s:DocGetEndpoint())
    let l:res = ParseJSON(l:rawres)
    call s:WriteDocMetadata(l:res)
endfunction

function! s:ReadDocMetadata()
    let l:mdfilename = s:MetadataFilename() 
    if (filereadable(l:mdfilename))
        execute "source"  fnameescape(l:mdfilename)
    endif
endfunction

function! s:WriteDocMetadata(metadata)
    let l:mdfilename = s:MetadataFilename() 
    let l:mdlines = []
    let l:relevantKeys = ['id', 'name']
    for key in relevantKeys 
        call add(l:mdlines, "let b:draftin_" . key . " = '" . a:metadata[key] . "'")
    endfor
    call writefile(l:mdlines, l:mdfilename)
    " Read it back so the stored variables can be used
    call s:ReadDocMetadata()
endfunction

function! s:GetFromDraft(endpoint)
    " -s silence everything except the raw reply
    let l:curlCmd = "curl -s -u ". g:draftin_vim_auth . " " . a:endpoint
    return system(l:curlCmd)
endfunction

function! s:SendMessage(method, jsondata, endpoint)
    " -s silence everything except the raw reply
    let l:curlCmd = "curl -s -u ". g:draftin_vim_auth . " -X " . a:method
    let l:curlCmd .= " -H 'Content-Type: application/json'"
    let l:json = '{' " "content": "'. l:content.'", "name": "'.l:name.'"}'
    for key in keys(a:jsondata)
        let l:json .= '"' . key . '" : "' . a:jsondata[key] . '" ,'
    endfor
    let l:json = l:json[:-2] . '}'
    let l:curlCmd .= " -d '" . l:json . "' "
    let l:curlCmd .= a:endpoint

    return system(l:curlCmd)
endfunction

" Rename the Draft document. Requires that the buffer is already recognized as
" a Draft document.
function! s:DraftRename(name)
    if !exists("b:draftin_id")
        echo "Buffer not recognized as a Draft document."
        return
    endif

    if !s:CheckDraftRunnable()
        return
    endif

    call s:SendMessage('PUT', { 'name' : a:name }, s:DocUpdateEndpoint())
    call s:UpdateDocMetadata()

    echo "Document renamed to " . b:draftin_name . ", see https://draftin.com/documents/" . b:draftin_id
endfunction

" Upload the current buffer to draftin.com
function! s:Draft(...)
    if !s:CheckDraftRunnable()
        return
    endif

    if !exists("b:autodraftin")
        call s:SetupDraftinBuffer()
    endif

    if !b:autodraftin
        let b:notautodraftin = 1
        let b:modified = &l:modified
        " Make sure the file is saved
        update
    endif

    let l:name = ""
    if len(a:000) == 1
        let l:name = a:1
    else
        let l:name = getline(1)
        " Use filename if there's no first line.
        if strlen(l:name) < 1
            let l:name = shellescape(expand('%:t')) 
        endif
    endif

    call s:ReadDocMetadata()
    let l:creating = 1
    if exists("b:draftin_id")
        if !b:modified
            echo "Buffer not modified, not sending update to draftin.com"
            return
        endif

        let l:creating = 0
    endif

    " Escaping the content is rather messy, since 
    " 1) some characters must be escaped to be correct JSON
    " 2) the shell used for the system call to curl have different
    "    requirements
    " The current solution is to first do the JSON escaping and then get rid
    " of the quotes it adds since that interferes with the next step.
    " The pure, JSON escaped content is then shellescaped, and then the quotes
    " it add removed since that interferes with JSON formatting again. 
    " The last step is to put together the complete, properly escaped JSON
    " with content.
    let l:content = b:json_dump_string(getline(1, line("$")))[1:-2]
    let l:content = shellescape(l:content)[1:-2]
    let l:jsondata = { 'content' : l:content, 'name' : l:name }

    let l:endpoint = s:draftin_doc_create_endpoint
    let l:curl_method = "POST"
    if !l:creating
        let l:endpoint = s:DocUpdateEndpoint() 
        let l:curl_method = "PUT"
    endif

    let l:rawres = s:SendMessage(curl_method, l:jsondata, l:endpoint)
    if l:creating
        let l:res = ParseJSON(l:rawres)
        call s:WriteDocMetadata(l:res)
        " Read it back so the stored variables can be used
        call s:ReadDocMetadata()
    endif

    if l:creating
        echo "Document " . l:name . " created and uploaded at https://draftin.com/documents/" . b:draftin_id
    else
        echo "Document " . l:name . " updated, see https://draftin.com/documents/" . b:draftin_id
    endif

    let b:modified = 0
endfunction

function! s:AutoDraft()
    if b:notautodraftin
        let b:notautodraftin = 0
        return
    endif
    let b:autodraftin = 1
    call s:Draft()
    let b:autodraftin = 0
endfunction

function! s:AddDraftinSaveHandlers()
    autocmd BufWritePre <buffer> let b:modified = &l:modified 
    autocmd BufWritePost <buffer> call s:AutoDraft()
endfunction

function! s:CheckSetupDraftinBuffer()
    call s:ReadDocMetadata()
    if exists("b:draftin_id")
        call s:SetupDraftinBuffer()
    endif
endfunction

function! s:SetupDraftinBuffer()
    call s:AddDraftinSaveHandlers()    
    let b:autodraftin = 0
    let b:notautodraftin = 0
    let b:modified = 0
endfunction

augroup draftin
    autocmd!

    autocmd  BufEnter  *  :call s:CheckSetupDraftinBuffer()
augroup END
