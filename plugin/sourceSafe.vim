" Author: David S. Eggum <email: TBD>
" Last Update: Sept 13 2001
" Version: 1.4a
" 
" sourceSafe.vim - Interfaces with the MS VSS command line.  This script is
" not meant to be a full replacement of the VSS GUI, but instead it provides a
" shortcut to the most frequently used operations such as checkin, checkout,
" get current file, check differences, and so on.
"
" Special Note:
" I am unable to give further support until I am able to get back online.
" If you find bugs, please try to fix and post them on your own.
"
" Setup:
"   There has been some talk in the VIM community about simplifying script
"   installation processes.  But until that happens, you will need to do the
"   following...
" - Place this file under $VIM/vimfiles/plugin
" - Copy the help file included (pi_ss.txt) into your local doc directory,
"   probably under $VIM/vimfiles/doc
" - type :helptags $VIM/vimfiles/doc from any vim window
" - type :help sourcesafe-setup, and follow the customization instructions.
" - Also see :help sourcesafe for an overview of this plugin.
"
" Send any feature suggestions or improvements you would like to have included!
" If you would like to help beta test new versions or be notified when a new
" version is released, then send an email to the address above.
"
" Updates:
" The latest version is available at vim.sourceforge.net
" 1.4a
"   Minor Features:
"     - Speedup: SS Status now looks for a local vssver.scc file before
"       requesting for the current lock status.  (Colman Curtin)
"     - Added ssLocalDB option.  (Vince Negri)
"     - Added ssExecutable option to specify the path to ss.exe.  (Vince Negri)
"   Bug Fixes:
"     - s:getFile() didn't return the filename correctly in some cases.
"       Reminder to self: Don't add features just before a release!  :~|
" 1.4
"   Major Features:
"     - Added online help.
"     - Added SS commands to the menubar. see :help sourcesafe-menus
"     - Improved script configuration setup.
"   Minor Features:
"     - Added SSRestore to revert settings before :diff changed them.
"     - Added quiet diff mode from the showAll window.
"     - Added ">" mappings for diff mode.  See :help sourcesafe-diff
"     - Changed SSDiff, SSStatus, SSShowAll to SS Diff, SS Status, and SS
"       ShowAll for uniformity.
"     - The showAll window is synchronized with the open buffers.
"   Bug Fixes:
"     - Removed Diff temp file from buffer list.
"     - Prevented diffing a file that isn't in VSS.
"     - Filtered non-informative messages in s:Generic.
"     - SS Status did not recognize deleted status.
"     - Temp files were not deleted.
"     - showAll now removes messages about directories that you do not have access
"       to.  (Colman Curtin)
"     - windows w/o file names (like cwindow) are now ignored for SS Status
"     - If VSS truncates the file in showAll and more than one file matches,
"       getFile() now returns the locked one.
" 1.3
"   Major Features:
"     - Added SSShowAll which lists all checked out files.  
"   Minor Features:
"     - Added some important VSS configuration information.  See :help
"       sourcesafe-special-note.
"     - Added mapleader.
" 1.2
"   Major Features:
"     - Diffing the file with the latest version in VSS now takes advantage of
"       Vim's built-in diff feature.
"   Minor Features:
"     - Added new lock status mode. (Daniel Einspanjer)
"     - Added extra lock information (old) and (exc). (Daniel Einspanjer)
"     - Added "!" (bang) switch to all commands for direct interaction with VSS.
" 1.1a
"   Bug Fixes:
"     - Fixed hang with Undocheckout when the current file has changed.
" 1.1
"   Major Features:
"     - The current lock status is now available from the SSGetLockStatus()
"       function.  It looks really good in the ruler!  Samples are provided
"       below.  Also see :help rulerformat.
"   Minor Features:
"     - Command responses are now echo'ed to the screen.
"     - Added silent flag (Daniel Einspanjer)
" 1.0 - Initial release
" 
" Todo:
" - Allow tagging of lines in showall window
" - Allow diffing against a history listing.
" - Add menu tearoff shortcut?
" - Add checked out version in status?
" - Consider adding a command to add a file to VSS.

if exists("loaded_sourcesafe")
   finish
endif
let loaded_sourcesafe=1

if !exists("ssLocalDB")
   let ssLocalDB=0
endif

if ssLocalDB
   let ssLocalTree=""
else
   if !exists("$SSDIR")
      echom "sourceSafe.vim: $SSDIR is not set. See :help SSDIR"
      finish
   endif

   if !exists("ssLocalTree")
      echom "sourceSafe.vim: ssLocalTree is not set. See :help ssLocalTree"
      finish
   endif
endif

if !exists("ssUserName")
   echom "sourceSafe.vim: ssUserName is not set. See :help ssUserName"
   finish
endif

" Set defaults
if !exists("ssExecutable")
   let ssExecutable="ss"
endif

if !exists("ssShowAllLocks")
   let ssShowAllLocks=1
endif

if !exists("ssShowExtra")
   let ssShowExtra=0
endif

if !exists("ssDiffVertical")
   let ssDiffVertical=1
endif

if !exists("ssQuietMode")
   let ssQuietMode=1
endif

if !exists("ssSetRuler")
   let ssSetRuler=1
endif

if (strlen(&rulerformat) == 0) && (ssSetRuler == 1)
   set rulerformat=%60(%=%{SSGetLockStatus()}%)\ %4l,%-3c\ %3p%%
endif 

if !exists("ssMenuPath")
   let ssMenuPath = "Plugin."
endif

if !exists("ssMapLeader")
   let mapleader = ",c"
else
   let mapleader = ssMapLeader
endif

if !hasmapto("SS! Checkout")
   nnoremap <Leader>O :SS! Checkout<cr>
endif
if !hasmapto("SS Checkout")
   nnoremap <Leader>o :SS Checkout -I-Y<cr>
endif
if !hasmapto("SS! Checkin")
   nnoremap <Leader>I :SS! Checkin<cr>
endif
if !hasmapto("SS Checkin")
   nnoremap <Leader>i :SS Checkin -I-Y<cr>
endif
if !hasmapto("SS! Undocheckout")
   nnoremap <Leader>U :SS! Undocheckout<cr>
endif
if !hasmapto("SS Undocheckout")
   nnoremap <Leader>u :SS Undocheckout -I-Y<cr>
endif
if !hasmapto("SS! Get")
   nnoremap <Leader>G :SS! Get<cr>
endif
if !hasmapto("SS Get")
   nnoremap <Leader>g :SS Get<cr>
endif
if !hasmapto("SS! Status")
   nnoremap <Leader>S :SS! Status<cr>
endif
if !hasmapto("SS Status")
   nnoremap <Leader>s :SS Status<cr>
endif
if !hasmapto("SS! Diff")
   nnoremap <Leader>D :SS! Diff -DU<cr>
endif
if !hasmapto("SS Diff")
   nnoremap <Leader>d :SS Diff<cr>
endif
if !hasmapto("SS! ShowAll")
   nnoremap <Leader>A :SS! ShowAll<cr>
endif
if !hasmapto("SS ShowAll")
   nnoremap <Leader>a :SS ShowAll<cr>
endif


au! BufRead * SS Status

let s:showAllWindow = 0

function <SID>displayMenus(bang)
   exec 'silent! aunmenu' g:ssMenuPath.'VSS'
   if a:bang == "!"
      let mode = "Quiet"
      let b = ""
      let diff = " -DU"
   else
      let mode = "Interactive"
      let b = "!"
      let diff = ""
   endif
   exec 'anoremenu' g:ssMenuPath.'VSS.Check\ &Out<Tab>:SS'.a:bang.'\ CheckOut :SS'.a:bang 'CheckOut<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.Check\ &In<Tab>:SS'.a:bang.'\ CheckIn :SS'.a:bang 'CheckIn<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Undo\ Check\ Out<Tab>:SS'.a:bang.'\ Undocheckout :SS'.a:bang 'Undocheckout<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Get<Tab>:SS'.a:bang.'\ Get :SS'.a:bang 'Get<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Diff<Tab>:SS'.a:bang.'\ Diff :SS'.a:bang 'Diff'.diff.'<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Summary<Tab>:SS'.a:bang.'\ ShowAll :SS'.a:bang 'ShowAll<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Update\ Status<Tab>:SS'.a:bang.'\ Status :SS'.a:bang 'Status<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.-Sep-   :'
   exec 'anoremenu <silent> <script> '.g:ssMenuPath.'&VSS.Set\ Menu\ '.mode.'\ &Mode :call <SID>displayMenus("'.b.'")<cr>'
   exec 'anoremenu' g:ssMenuPath.'VSS.&Help<Tab>:help\ sourceSafe :help sourceSafe<cr>'
endfunction

let b:checked_out_status = ""

function s:GetSSName(filename)
   let ssfile = substitute(a:filename,g:ssLocalTree,"\$","")
   return substitute(ssfile,"\\","/","g")
endfunction

function SSGetLockStatus()
   if exists("b:checked_out_status")
      return b:checked_out_status
   else
      return ""
   endif
endfunction

" get the current lock status from VSS and place it in b:checked_out_status
function s:UpdateStatus(bang,cmd_args,filename)
   let sCmd = g:ssExecutable." ".a:cmd_args." ".s:GetSSName(a:filename)
   if a:bang == "!" " Raw VSS interaction
      exec "!".sCmd
      return
   endif

   " speedup: we know the file is not in VSS if a local vssver.scc doesn't
   " exist.  (Colman Curtin)
   if !filereadable(fnamemodify(a:filename,":p:h").'\vssver.scc')
      let b:checked_out_status = "Not in VSS"
      return
   endif
   let sFull = system(sCmd)
   let sLine = sFull
   if (match(sFull,"No checked out files found.") == 0)
      let b:checked_out_status = "Not Locked"
      return b:checked_out_status
   elseif (match(sFull,"is not valid SourceSafe syntax") != -1 || 
            \match(sFull,"is not an existing filename or project") != -1 ||
            \match(sFull,"has been deleted") != -1)
      let b:checked_out_status = "Not in VSS"
      return b:checked_out_status
   elseif (strlen(sFull) == 0)
      let b:checked_out_status = ""
      return ""
   endif

   " Quirk: VSS truncates files over 19 characters long
   let file = strpart(expand("%:t"),0,19)
   let sUsers = ""
   let sStatus = ""
   while (strlen(sLine) != 0)
      let sMatch = matchstr(sLine,".\\{-1,}\n")
      if match(sMatch,file) == 0
         if g:ssShowAllLocks == 1
            if strlen(sUsers) > 0
               let sUsers = sUsers.','
            endif
            let sUsers = sUsers.matchstr(sMatch,' \w\+')
            " If this checkout is exclusive, append it and break.
            if g:ssShowExtra
               if match(sMatch,'\w\+\s\+\w\+\s\+Esc') > -1
                  let sUsers = sUsers.' (exc)'
                  break
               " If this checkout is old, append it.
               elseif match(sMatch,'\w\+\s\+\w\+\s\+v') > -1
                  let sUsers = sUsers.' (old)'
               endif
            endif
         else
            " Get the index of where ssUserName ends.
            let iMatchedAt = matchend(sMatch,g:ssUserName)
            " If *I* have it checked out...
            if iMatchedAt > -1
               let sStatus = "Locked"
               " If this checkout is exclusive, append it and break.
               if g:ssShowExtra
                  if match(sMatch,'\s\+Exc', iMatchedAt) > -1
                     let sStatus = sStatus." (exc)"
                  " If this checkout is old, append it and break.
                  elseif match(sMatch,'\s\+v', iMatchedAt) > -1
                     let sStatus = sStatus." (old)"
                  endif
               endif
               break
            " ElseIf someone else has it exclusively checked out,
            " Notify and break.
            elseif match(sMatch,'\w\+\s\+\w\+\s\+Esc') > -1
               let sStatus = sStatus."Locked by".matchstr(sMatch,' \w\+')
               break
            " Else I don't care about any other status.
            else
               let sStatus = "Not Locked"
            endif
         endif
      endif

      let iLen = strlen(sMatch)
      let sLine = strpart(sLine,iLen,strlen(sLine)-iLen)
   endwhile

   if strlen(sUsers) > 0
      let b:checked_out_status = "Locked by".sUsers
   elseif strlen(sStatus) > 0
      let b:checked_out_status = sStatus
   else
      echom "VSS plugin: Unrecoginzed output:" sFull
   endif

   return b:checked_out_status
endfunction

" execute the SS command and echo the results to the vim window.
function s:Generic(bang,cmd_args,filename,bExternal)
   " look for special cases...
   if match(a:cmd_args,"Status") != -1
      " Bug fix: cwindow does not have a file name
      if (a:filename != "")
         call s:UpdateStatus(a:bang,a:cmd_args,a:filename)
      endif
      return
   elseif match(a:cmd_args,"Diff") != -1
      call s:Diff(a:bang,strpart(a:cmd_args,5),a:filename,0) " not summary
      return
   elseif match(a:cmd_args,"ShowAll") != -1
      call s:showAll(a:bang)
      return
   endif
   let sCmd = g:ssExecutable." ".a:cmd_args." ".s:GetSSName(a:filename)." -GL".fnamemodify(a:filename,":h")
   if a:bang == "!" " Raw VSS interaction
      exec "!".sCmd
      if a:bExternal == 0
         e
         call s:UpdateStatus("","Status",a:filename)
      endif
      return
   endif

   if &modified
      echom "This file has been modified. Please save it."
      return
   endif

   let sFull = system(sCmd)

   let sMatch = matchstr(sFull,".* is already checked out, continue.\\{-1,}\n")
   let iLen = strlen(sMatch)
   if (iLen == 0)
      let sMatch = matchstr(sFull,".* has changed. Undo check out and lose changes.\\{-1,}\n")
      let iLen = strlen(sMatch)
   endif
   if (iLen > 0)
      let sLine = strpart(sFull,iLen,strlen(sFull)-iLen)
   else
      let sLine = sFull
   endif

   if a:bExternal && bufloaded(a:filename)
      " Jump to the window.  Thanks to Benji Fisher for how to do this.
      exec "normal" bufwinnr(a:filename) "\<C-w>w"
   endif
   if (a:bExternal == 0) || bufloaded(a:filename)
      call s:UpdateStatus("","Status",a:filename)

      let v:errmsg = ""

      normal M

      silent! e

      exec "normal \<c-o>"
      exec "normal \<c-o>"

      if v:errmsg != ""
         echom "reopen failed:" v:errmsg
         return
      endif
   endif
   if a:bExternal && bufloaded(a:filename)
      wincmd p
   endif

   " update the showAll winow
   if !a:bExternal && s:showAllWindow == 1
      call s:synchronize()
   endif

   " Echo command response, useful if there's an error.
   " Do not echo non-informative msgs, esp. if operating on more than one file.
   if (match(sLine,'^\f\+$') != -1)
      echom sLine
   endif
endfunction

function SSRestore()
   if !s:bufferclosed
      return
   endif
   set nodiff
   let &fdc = s:fdc
" Haven't found a good way to restore the previous folds
"    let &fdm = s:fdm
" 
   let &scb = s:scb
   let &sbo = s:sbo
   let &wrap = s:wrap
   au! sourceSafe
endfunction

function s:Diff(bang,cmd_args,filename,bSummary)
   if a:bang == "!" " Raw VSS interaction
      exec "!".g:ssExecutable." Diff" a:cmd_args s:GetSSName(a:filename) a:filename
      return
   endif

   if !a:bSummary && match(SSGetLockStatus(),"Not in VSS") != -1
      echom "Cannot diff, file not in VSS"
      return
   endif

   " save current settings before diff screws them up
   let s:fdc = &fdc " foldcolumn
   let s:fdm = &fdm " foldmethod
   let s:scb = &scb " scrollbind
   let s:sbo = &sbo " scrollopt
   let s:wrap = &wrap

   let sFile = tempname().".".fnamemodify(a:filename,":e") " append same extention for syntax highlighting
   call system(g:ssExecutable." View ".a:cmd_args." -O".sFile." ".s:GetSSName(a:filename))

   let sFull = system("diff -q ".sFile." ".a:filename)
   if (strlen(sFull) > 0)
      " the files differ
      if a:bSummary
         return 1
      endif

      let s:bufferclosed = 0

      augroup sourceSafe
         exec "au BufEnter" expand("%:t") "call SSRestore()"
      augroup end

" 
"       " Not sure if this is useful
"       if !hasmapto('diffput') && maparg("<","v") == ""
"          vmap <buffer> < :diffput<cr>
"       endif
" 

      if g:ssDiffVertical
         exec "vert diffsplit" sFile
      else
         exec "diffsplit" sFile
      endif
      set nobuflisted

      augroup sourceSafe
         exec "au BufUnload" expand("%:t") "let s:bufferclosed = 1"
         exec "au BufUnload" expand("%:t") "call delete('".sFile."')"
      augroup end

      if !hasmapto('diffput') && maparg(">","nv") == ""
         nmap <buffer> > :diffput<cr>
         vmap <buffer> > :diffput<cr>
      endif
   else
      if a:bSummary
         return 0
      endif

      echom "No differences"
   endif
endfunction

" show all files locked by the current user
function s:showAll(bang)
   let sCmd = g:ssExecutable." Status $/ -R -U"
   if a:bang == "!"
      exec "!".sCmd
      return
   endif

   echom "Searching for locked files, please wait..."

   " sent to a temporary file to prevent VSS from splitting long lines
   let sFile = tempname()
   let s:showAllWindow = sFile
   let sFull = system(sCmd." -O".sFile)
   exec "sp" sFile
   set nobuflisted
   set noswapfile
   set bufhidden=delete
   let s:showAllWindow = 1
   exec "au BufUnload" expand("%:t") "call delete('".sFile."')"
   exec "au BufUnload" expand("%:t") "let s:showAllWindow = 0"
   silent g/:$/d
   silent g/^$/d
   silent g/You do not have access/d
   silent exec '%s/\zs'.g:ssUserName.'\s\+\zev//e'
   silent exec '%s/'.g:ssUserName.'\s\+/      /e'

   1
   normal mv

   let @v = "\" Note: Use a (V)isual line to operate on multiple files.\n"
          \."\" (e)dit, (E)dit and close, (s)plit edit, (v)ert split edit\n"
          \."\" check(i)n, (u)ndocheckout, (d)iff, (D)iff summary, (q)uit\n"
          \."\" (!) change interaction mode. Current mode is quiet.\n"
          \."\" Files checked out by ".g:ssUserName.":\n"
   put! v
   if g:ssQuietMode == 0
      silent %s/quiet/interactive/
   endif
   w

   setlocal nomodifiable

   if winheight(".") > line("$")
      exec "resize" line("$")
   endif

   1
   normal 'v

   syn keyword String contained quiet interactive
   syn match Comment "^\".*$" contains=Special,String,Directory
   syn match Directory "^\f\+" contains=Special
   syn match String "^\" \zsFiles.*$"
   syn match Special "(\zs.\ze)" contained
   syn match Special "^\" \zsNote:\ze" contained
   syn match Title "No files found.*$"
   syn match Special "No changes" contained
   syn match Directory "\zschanges\ze." contained

   nnoremap <script> <buffer> <silent> !      :call <SID>ChangeMode()<cr>
   nnoremap <script> <buffer> <silent> D      :call <SID>DiffSummary()<cr>
   nnoremap <script> <buffer> <silent> e      :call <SID>EditFile(0)<cr>
   nnoremap <script> <buffer> <silent> E      :call <SID>EditFile(1)<cr>
   nnoremap <script> <buffer> <silent> v      :call <SID>EditFile(2)<cr>
   nnoremap <script> <buffer> <silent> s      :call <SID>EditFile(3)<cr>
   nnoremap <script> <buffer> <silent> i      :call <SID>Generical("Checkin",0)<cr>
   vnoremap <script> <buffer> <silent> i      :call <SID>Generical("Checkin",1)<cr>
   nnoremap <script> <buffer> <silent> u      :call <SID>Generical("Undocheckout",0)<cr>
   vnoremap <script> <buffer> <silent> u      :call <SID>Generical("Undocheckout",1)<cr>
   nnoremap <script> <buffer> <silent> d      :call <SID>Diffical()<cr>
   vnoremap <script> <buffer> <silent> d      :call <SID>Diffical()<cr>
   nnoremap          <buffer>          <esc>  :q!<cr>
   nnoremap          <buffer>          q      :q!<cr>
endfunction

function <SID>DiffSummary()
   let iLastLine = line("$")
   let i = 1
   while i <= iLastLine
      let sFile = s:getFile(i)
      let i = i + 1
      if strlen(sFile) == 0
         continue
      endif

      if s:Diff("","",sFile,1) == 0
         let sFile = strpart(fnamemodify(sFile,":t"),0,19)
         exec "syn match Special '".sFile."' contained"
      endif
   endwhile

   normal mv
   setlocal modifiable
   silent! %s/\zsiff summary\ze\,/&; No changes, changes/
   noh
   setlocal nomodifiable
   set nomodified
   normal 'v
endfunction

function <SID>ChangeMode()
   setlocal modifiable
   normal mv
   if g:ssQuietMode == 1
      let g:ssQuietMode = 0
      silent %s/quiet/interactive/
   else
      let g:ssQuietMode = 1
      silent %s/interactive/quiet/
   endif
   normal 'v
   setlocal nomodifiable
   set nomodified
endfunction

function s:getFile(spot)
   let sLine = getline(a:spot)
   if match(sLine,"^\"") != -1
      return ""
   elseif match(sLine,"^No files found.*") != -1
      return ""
   endif
   let sFile = matchstr(sLine,"\\f\\+")
   let sFull = matchstr(sLine,"\\f\\+$")."\\".sFile
   if (strlen(sFile) == 19) " VSS probably truncated the filename
      let sAll = glob(sFull."*") " try to restore it
      let iPos = stridx(sAll, "\n")
      if (iPos == -1)
         return sAll
      endif

      " if more than one file matches, then look for the locked one
      let sPart = matchstr(sAll,"^\\zs.\\{-1,}\\ze[\n]")
      let iPos = 0
      while (sPart != "")
         let sFull = system(g:ssExecutable." Status ".s:GetSSName(sPart)." -U".g:ssUserName)
         if (match(sFull,"No files found checked out by ".g:ssUserName) == 0)
            let iPos = iPos + strlen(sPart) + 1
            let sPart = matchstr(sAll,"^\\zs.\\{-1,}\\ze[\n]",iPos)
            " Haven't figured out how to match [\n$], so....
            if (strlen(sPart) == 0) " found the end of the list, return this file.
               return strpart(sAll,iPos)
            endif
            continue
         else
            " found the file, return it
            return sPart
         endif
      endwhile
   endif
   return sFull
endfunction

function <SID>EditFile(iMode)
   let sFile = s:getFile(".")
   if strlen(sFile) == 0
      return
   endif
   if a:iMode == 0 " edit
      wincmd p
      exec "e" sFile
   else
      q!
      if a:iMode == 1 " edit and close
         exec "e" sFile
      elseif a:iMode == 2 " vertical edit
         exec "vert sp" sFile
      elseif a:iMode == 3 " split edit
         exec "sp" sFile
      endif
   endif
endfunction

" update the showAll window.  Assumes the user hasn't moved the preview window
" from the top.
function s:synchronize()
   let sCurrent = escape(expand("%:p"), '\')
   wincmd t
   let iLast = line("$")
   let iCurrent = 1
   while (iCurrent <= iLast)
      let sFile = s:getFile(iCurrent)
      if strlen(sFile) == 0 " don' do nuttin
      elseif match(sFile,sCurrent) != -1
         setlocal modifiable
         d
         set nomodified
         setlocal nomodifiable
         return
      endif
      let iCurrent = iCurrent + 1
   endwhile
   wincmd p
endfunction

function <SID>Generical(cmd,bVisual)
   let sFile = s:getFile(".")
   if strlen(sFile) == 0
      return
   endif
   if g:ssQuietMode == 1
      call s:Generic("",a:cmd." -I-Y",sFile,1)
   else
      call s:Generic("!",a:cmd,sFile,1)
   endif

   " Note: can't use mode(), it always returns "n" :(
   if a:bVisual == 0
      setlocal modifiable
      d
      set nomodified
      setlocal nomodifiable
   elseif line("'>") == line(".")
      " we are operating on the last line in the visual block, so delete the
      " entire block
      setlocal modifiable
      silent '<,'>d
      set nomodified
      setlocal nomodifiable
   endif
endfunction

function <SID>Diffical()
   let sFile = s:getFile(".")
   if strlen(sFile) == 0
      return
   endif
   if g:ssQuietMode == 1
      wincmd j
      exec "e" sFile
      call s:Diff("","",sFile,0)
   else
      call s:Diff("!","-DU",sFile,0)
   endif
endfunction

if ssLocalDB
   command! -bang -nargs=+ SS call s:Generic(<q-bang>,<q-args>,expand("%"),0)
else
   command! -bang -nargs=+ SS call s:Generic(<q-bang>,<q-args>,expand("%:p"),0)
endif

if g:ssQuietMode == 0
   call <SID>displayMenus("!")
else
   call <SID>displayMenus("")
endif

" vim: sw=3:expandtab
