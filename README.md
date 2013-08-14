vim-draftin
------

Work in progress plugin for the excellent writing tool [https://draftin.com](Draft)

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
POST new documents. Within .vimrc:

    let g:draftin_auth = "username:password"

Usage
----

* `:Draft` will upload the document to Draft, echo'ing back the url.

TODO
---

* :Draft command should update a document if already exists.
