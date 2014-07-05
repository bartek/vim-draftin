vim-draftin
------

Work in progress plugin for the excellent writing tool [https://draftin.com](Draft)

Dependencies
----

When creating/uploading a document the first time, a JSON response is received.
To parse this and extract the id,
[vim-scripts/ParseJSON](https://github.com/vim-scripts/ParseJSON) is used. 

If the text/content contains certain characters (e.g. if you write about code), they 
may have to be escaped in JSON.
[vim-scripts/jsoncodecs.vim](https://github.com/vim-scripts/jsoncodecs.vim)
handles this.

Installation
----

I highly recommend [pathogen.vim](https://github.com/tpope/vim-pathogen), which
makes installation very simple:

    cd ~/.vim/bundle
    git clone git://github.com/bartek/vim-draftin.git

Assuming you have pathogen setup, the plugin will automatically be installed.

Configuration
----

You'll need to set your [https://draftin.com](Draft) credentials to be able to
POST new documents. Within .vimrc (or in a file sourced from .vimrc):

    let g:draftin_auth = "username:password"

Usage
----

* `:Draft` will upload the document to Draft, echo'ing back the url. Arguments
  to the command will be used as the name of the document. If there are no
  arguments, the name will be set to the first line of the content, or if that
  is missing too, the file name.
