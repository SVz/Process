.386
.model flat,stdcall
option casemap:none

include Process.Inc
.code
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;--------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    invoke InitCommonControls
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
exit:
    invoke ExitProcess,eax
    
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hDlg:HWND
    LOCAL hPicture:HWND
    
    mov   wc.cbSize,SIZEOF WNDCLASSEX
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,DLGWINDOWEXTRA
    push  hInst
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_BTNFACE+1
    mov   wc.lpszMenuName,OFFSET ClassName
    mov   wc.lpszClassName,OFFSET ClassName
    
    invoke LoadIcon,hInst,1
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax
    invoke RegisterClassEx, addr wc
    invoke CreateDialogParam,hInstance,ADDR DlgName,NULL,NULL,NULL
    mov   hDlg,eax
    INVOKE ShowWindow, hDlg,SW_SHOWNORMAL
    INVOKE UpdateWindow, hDlg

    invoke GetDlgItem,hDlg,IDC_PROCESS
    invoke  SendMessage,eax,LVM_SETEXTENDEDLISTVIEWSTYLE,0,LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT 

    mov ofn.lStructSize,SIZEOF ofn
    push hDlg
    pop  ofn.hWndOwner
    push hInstance
    pop  ofn.hInstance
    mov  ofn.lpstrFilter, OFFSET FilterString
    mov  ofn.lpstrFile, OFFSET buffer
    mov  ofn.nMaxFile,MAXSIZE

    mov pcol.imask,LVCF_FMT or LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM
    mov pcol.fmt,LVCFMT_LEFT
    mov pcol.lx,338
    mov pcol.pszText,offset Titlecolumn1
    mov pcol.iSubItem,0
    invoke GetDlgItem,hDlg,IDC_PROCESS
    invoke SendMessage,eax,LVM_INSERTCOLUMN,1,offset pcol

    mov pcol.iSubItem,1
    mov pcol.pszText,offset Titlecolumn2
    mov pcol.lx,70
    mov pcol.fmt,LVCFMT_RIGHT
    invoke GetDlgItem,hDlg,IDC_PROCESS
    invoke SendMessage,eax,LVM_INSERTCOLUMN,1,offset pcol

    mov pcol.imask,LVCF_FMT or LVCF_TEXT or LVCF_WIDTH or LVCF_SUBITEM
    mov pcol.fmt,LVCFMT_LEFT
    mov pcol.lx,268
    mov pcol.pszText,offset Titlecolumn3
    mov pcol.iSubItem,0
    invoke GetDlgItem,hDlg,IDC_MODULE
    invoke SendMessage,eax,LVM_INSERTCOLUMN,1,offset pcol

    mov pcol.iSubItem,1
    mov pcol.pszText,offset Titlecolumn5
    mov pcol.lx,70
    mov pcol.fmt,LVCFMT_RIGHT
    invoke GetDlgItem,hDlg,IDC_MODULE
    invoke SendMessage,eax,LVM_INSERTCOLUMN,1,offset pcol

    mov pcol.iSubItem,2
    mov pcol.pszText,offset Titlecolumn4
    mov pcol.lx,70
    mov pcol.fmt,LVCFMT_RIGHT
    invoke GetDlgItem,hDlg,IDC_MODULE
    invoke SendMessage,eax,LVM_INSERTCOLUMN,1,offset pcol

    invoke Sleep,500
    push hDlg
    pop hwnd
    call affprocess

    .WHILE TRUE
                INVOKE GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke IsDialogMessage, hDlg, ADDR msg
                .if eax==FALSE
                        INVOKE TranslateMessage, ADDR msg
                        INVOKE DispatchMessage, ADDR msg
                .endif
    .ENDW
    mov     eax,msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
 LOCAL hdc:HDC 
 LOCAL ps:PAINTSTRUCT 
 LOCAL hfont:HFONT
    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        mov edx,wParam
        shr edx,16
        .IF dx==BN_CLICKED
            .IF ax==IDC_REFRESH
                push hWnd
                pop hwnd
                call affprocess
             .ELSEIF ax==IDC_KILL ;------------------------------KILL---------
                invoke OpenProcess ,PROCESS_TERMINATE,0,processID
                mov hprocess,eax
                invoke TerminateProcess,hprocess,0
                invoke Sleep,500
                invoke SendMessage,hWnd,WM_COMMAND,IDC_REFRESH,0
            .ELSEIF ax==IDC_DUMP
;               int 3
                invoke CreateToolhelp32Snapshot, TH32CS_SNAPMODULE, processID 
                mov hSnapshot, eax
                mov mo32.dwSize, sizeof MODULEENTRY32
                invoke Module32First, hSnapshot, addr mo32
                svloops:
                invoke lstrcmp, addr mo32.szExePath, addr processname
                test eax,eax
                jz suite
                invoke Module32Next, hSnapshot, addr mo32
                test eax,eax
                jnz svloops
                jmp rien
                suite:
                invoke CloseHandle, hSnapshot
                mov ofn.Flags,OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
                lea eax,buffer
                xor ebx,ebx
                mov [eax],bl                            ;filename a vide
                invoke GetSaveFileName, ADDR ofn
                .if eax==TRUE
                    invoke CreateFile,ADDR buffer,\
                                                GENERIC_READ or GENERIC_WRITE ,\
                                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                                NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,\
                                                NULL
                    .if (eax)
                        mov hFile,eax
                        invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,mo32.modBaseSize
                        mov  hMemory,eax
                        invoke GlobalLock,hMemory
                        mov  pMemory,eax
                    ;int 3
                        invoke OpenProcess ,1f0fffh,0,processID
                        mov hprocess,eax
                        invoke ReadProcessMemory,hprocess,mo32.modBaseAddr,pMemory,mo32.modBaseSize,0
                        invoke CloseHandle,hprocess
                   
                        invoke WriteFile,hFile,pMemory,mo32.modBaseSize,ADDR SizeReadWrite,NULL
                        invoke CloseHandle,hFile
                        invoke GlobalUnlock,pMemory
                        invoke GlobalFree,hMemory
                        invoke MessageBox, NULL,addr MsgBoxText, addr MsgCaption, MB_OK
                    .endif
                .endif
                rien:
            .ELSEIF ax==IDC_DLL
                mov osinfo.dwOSVersionInfoSize,sizeof osinfo
                mov osinfo.szCSDVersion,128
                invoke GetVersionEx,addr osinfo
                .if eax==TRUE 
                    .if osinfo.dwPlatformId==1 ;win95/98
        		        invoke GetDefaultRCInfo
                        invoke EstablishApiHooks,eax,offset dll_name, processID, 1000           
                    .elseif osinfo.dwPlatformId==VER_PLATFORM_WIN32_NT ;=2 winNT
                        invoke LoadDLLinProcess,processID,addr dll_name
                    .endif
                .endif
            .ELSEIF ax==IDC_EXIT
                invoke DestroyWindow,hWnd
                invoke GetOpenFileName, ADDR ofn
            .ENDIF
        .ENDIF
    .ELSEIF uMsg==WM_NOTIFY
        mov eax,wParam
        mov ebx,lParam
        add ebx,8
        mov ecx,[ebx]
        .IF eax==IDC_PROCESS
            .IF ecx==NM_CLICK
                mov nbitem,0
                push hWnd
                pop hwnd
                add ebx,4
                mov eax,[ebx]
                mov pitem.iItem,eax
                mov pitem.iSubItem,1
                mov pitem.imask,LVIF_TEXT
                mov pitem.cchTextMax,512
                lea eax,textbuffer
                mov pitem.pszText,eax
;
                invoke GetDlgItem,hwnd,IDC_PROCESS  ; recup process ID
                invoke SendMessage,eax,LVM_GETITEM,0,offset pitem 
                invoke htodw,addr textbuffer
                mov processID,eax

                mov pitem.iSubItem,0        ; recup process name
                lea eax,processname
                mov pitem.pszText,eax
                invoke GetDlgItem,hwnd,IDC_PROCESS
                invoke SendMessage,eax,LVM_GETITEM,0,offset pitem 
                
                invoke OpenProcess ,PROCESS_TERMINATE,0,processID
                .if (eax)
                    invoke CloseHandle,eax
                    mov etat,TRUE
                .else
                    mov etat,FALSE
                .endif
                invoke GetDlgItem,hWnd,IDC_KILL
                invoke EnableWindow,eax,etat
                invoke GetDlgItem,hWnd,IDC_DUMP
                invoke EnableWindow,eax,etat
                invoke GetDlgItem,hWnd,IDC_DLL
                invoke EnableWindow,eax,etat


;                invoke GetDlgItem,hwnd,IDC_MODULE
;                invoke SendMessage,eax,LVM_DELETEALLITEMS,0,0
;                lea eax,processname
;                mov pitem.pszText,eax
;                invoke CreateToolhelp32Snapshot, TH32CS_SNAPMODULE, processID 
;                mov hSnapshot, eax
;                mov mo32.dwSize, sizeof MODULEENTRY32
;                invoke Module32First, hSnapshot, addr mo32
;                svloopm:
;                invoke wsprintf,addr textbuffer,offset template_deci,mo32.modBaseAddr
;                invoke wsprintf,addr textbuffer2,offset template_deci,mo32.modBaseSize
;                invoke svadditemmodule,addr mo32.szExePath,addr textbuffer,addr textbuffer2
;                invoke Module32Next, hSnapshot, addr mo32
;                test eax,eax
;                jnz svloopm
;                invoke CloseHandle, hSnapshot
;    @@:
            .ENDIF                
        .ENDIF
    .ENDIF
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam
    ret
WndProc endp
LoadDLLinProcess proc pID:DWORD, pstr_DLL:DWORD
LOCAL strdll_size :DWORD
LOCAL result :DWORD
    mov result,FALSE
    invoke OpenProcess ,PROCESS_ALL_ACCESS,FALSE,pID
    .if (eax)
        mov hprocess,eax
       	invoke VirtualAllocEx,hprocess,NULL,sizeof dll_name,MEM_COMMIT,PAGE_READWRITE
      	.if (eax)
           	mov NewMemory,eax
           	invoke lstrlen,pstr_DLL
           	mov strdll_size,eax
           	invoke WriteProcessMemory,hprocess,NewMemory,pstr_DLL,strdll_size,NULL
           	.if (eax)
           		invoke LoadLibrary,CTXT("Kernel32.dll")
           		mov Library,eax
           		invoke GetProcAddress,Library,CTXT("LoadLibraryA")
          		mov ApiAddress,eax
       	        invoke CreateRemoteThread,hprocess,NULL,NULL,ApiAddress,NewMemory,0,NULL
       	        .if (eax)
       	            mov result,TRUE
       	        .endif
                invoke FreeLibrary,Library
           	.endif
           	invoke VirtualFreeEx,hprocess, NewMemory, strdll_size ,MEM_FREE
        .endif
        invoke CloseHandle,hprocess
    .endif
    mov eax,result
    ret
LoadDLLinProcess endp
svadditemprocess proc ptext:DWORD, psize:DWORD
    mov pitem.imask,LVIF_TEXT
    push nbitem  
    pop pitem.iItem
    mov pitem.iSubItem,0
    mov eax,ptext
    mov pitem.pszText,eax
    invoke GetDlgItem,hwnd,IDC_PROCESS
    invoke SendMessage,eax,LVM_INSERTITEM,0,offset pitem

    mov pitem.iSubItem,1
    mov eax,psize
    mov pitem.pszText,eax
    invoke GetDlgItem,hwnd,IDC_PROCESS
    invoke SendMessage,eax,LVM_SETITEMTEXT,nbitem,offset pitem
    add nbitem,1
    ret
svadditemprocess endp

svadditemmodule proc ptext:DWORD, pbase:DWORD ,psize:DWORD
    mov pitem.imask,LVIF_TEXT
    push nbitem  
    pop pitem.iItem
    mov pitem.iSubItem,0
    mov eax,ptext
    mov pitem.pszText,eax
    invoke GetDlgItem,hwnd,IDC_MODULE
    invoke SendMessage,eax,LVM_INSERTITEM,0,offset pitem

    mov pitem.iSubItem,1
    mov eax,pbase
    mov pitem.pszText,eax
    invoke GetDlgItem,hwnd,IDC_MODULE
    invoke SendMessage,eax,LVM_SETITEMTEXT,nbitem,offset pitem

    mov pitem.iSubItem,2
    mov eax,psize
    mov pitem.pszText,eax
    invoke GetDlgItem,hwnd,IDC_MODULE
    invoke SendMessage,eax,LVM_SETITEMTEXT,nbitem,offset pitem

    add nbitem,1
    ret
svadditemmodule endp

affprocess proc
LOCAL nb_proc:DWORD
LOCAL hProcess:HANDLE
LOCAL ProcessID:DWORD
LOCAL ind_proc:DWORD
LOCAL nb_module:DWORD
LOCAL ind_module:DWORD
    mov nbitem,0
    invoke GetDlgItem,hwnd,IDC_PROCESS
    invoke SendMessage,eax,LVM_DELETEALLITEMS,0,0

    mov osinfo.dwOSVersionInfoSize,sizeof osinfo
    mov osinfo.szCSDVersion,128
    invoke GetVersionEx,addr osinfo
    .if eax==TRUE 
        .if osinfo.dwPlatformId==1 ;win95/98
            invoke GetDlgItem,hwnd,IDC_PROCESS
            invoke SendMessage,eax,LVM_DELETEALLITEMS,0,0
            invoke CreateToolhelp32Snapshot, TH32CS_SNAPPROCESS, 0 
            mov hSnapshot, eax
            mov pe32.dwSize, sizeof PROCESSENTRY32
            invoke Process32First, hSnapshot, addr pe32
            @@:
            invoke wsprintf,addr textbuffer,offset template_deci,pe32.th32ProcessID
            invoke svadditemprocess,addr pe32.szExeFile,addr textbuffer
            invoke Process32Next, hSnapshot, addr pe32
            test eax,eax
            jnz @b
            invoke CloseHandle, hSnapshot
         .elseif osinfo.dwPlatformId==VER_PLATFORM_WIN32_NT ;=2 winNT
            invoke EnumProcesses,offset aProcesses, sizeof aProcesses, addr cbNeeded 
            .if (eax)
                mov eax,cbNeeded
                shr eax,2
                mov nb_proc,eax
                mov ind_proc,0
                mov edi,ind_proc
                .while (edi<nb_proc)
                    mov eax,aProcesses[edi*4]
                    mov ProcessID,eax
                    invoke OpenProcess,PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,FALSE,ProcessID
                    .if (eax)
                        mov hProcess,eax
                        invoke EnumProcessModules,hProcess,addr hMod, sizeof hMod,addr cbNeeded
                        .if (eax)
                            invoke GetModuleFileNameEx,hProcess, hMod,addr szProcessName,sizeof szProcessName
                            invoke wsprintf,addr textbuffer,offset template_deci,ProcessID
                            invoke svadditemprocess,addr szProcessName,addr textbuffer
                        .endif
                    .endif
                    inc ind_proc
                    mov edi,ind_proc    
                .endw
            .endif
        .endif
    .endif
    ret
affprocess endp
end start
