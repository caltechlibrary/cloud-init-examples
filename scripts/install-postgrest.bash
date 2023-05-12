#!/bin/bash
git clone https://github.com/PostgREST/postgrest 
cd postgrest
stack build --install-ghc --copy-bins --local-bin-path $HOME/bin

