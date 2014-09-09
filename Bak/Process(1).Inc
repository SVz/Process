WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
svadditemprocess proto :DWORD, :DWORD
svadditemmodule proto :DWORD, :DWORD, :DWORD
LoadDLLinProcess proto :DWORD, :DWORD

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc
include \masm32\include\masm32.inc
include \masm32\include\comdlg32.inc
include \masm32\include\advapi32.inc
include \masm32\include\ApiHooks.inc
include \masm32\include\ApiHooks.pro
include \masm32\include\ComCtl32.inc
include \masm32\include\psapi.inc
include \masm32\macros\Strings.mac

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\advapi32.lib
includelib \masm32\lib\SApiHooks.lib
includelib \masm32\lib\ComCtl32.lib
includelib \masm32\lib\psapi.lib

.const
IDC_REFRESH                                    equ 3001
IDC_EXIT                                       equ 3002
IDC_MODULE                                     equ 3003
IDC_PROCESS                                    equ 3004
IDC_KILL                                       equ 3005
IDC_DUMP                                       equ 3006
IDC_DLL                                        equ 3007

LVN_DBLCLK                                     equ -16
 MAXSIZE equ 260

.data
pRCI            PRCINFO 0
ofn             OPENFILENAME <>
buffer          db MAXSIZE dup(0)
FilterString    db "All Files",0,"*.*",0,0
template_cb     db "ps:%d pd:%d",0
template_deci   db "%08X",0
template_ratio  db "%d%%",0
txtemplate      db "%s",0 
ClassName       db "DLGCLASS",0
MenuName        db "MyMenu",0
DlgName         db "SVDialog",0
AppName         db "SVPROCESS",0
Titlecolumn1    db "Process Name",0
Titlecolumn2    db "ID",0
Titlecolumn3    db "Module Name",0
Titlecolumn4    db "Base",0
Titlecolumn5    db "Size",0
nbitem          dd 0
fontname        db "Lucida Console",0
indexitem       dd 0
ModSize         dd 0
ModBase         dd 0
MsgCaption      db "Good",0
MsgBoxText      db "Dump done !",0
dll_name        db "SVimpor.dll",0
kernel          db "kernel32.dll",0
openprocess     db "OpenProcess",0
osinfo 				OSVERSIONINFO <>
etat            dd FALSE

.data?
szProcessName   db MAXSIZE dup(?)
hInstance       HINSTANCE ?
CommandLine     LPSTR ?
pcol            LVCOLUMN <?>
pitem           LVITEM <?>
processname     db 512 dup(?)
textbuffer      db 512 dup(?)
textbuffer2     db 512 dup(?)
hFileRead       HANDLE ?
nFileSize       dd ?
pBuffer         dd ?
pData           dd ?
nbread          dd ?
hwnd            dd ?
pstrname        dd ?
pe32            PROCESSENTRY32 <>
mo32            MODULEENTRY32 <?>
tagNMHDR        NMHDR <>
hSnapshot       DWORD ?
hprocess        DWORD ?
processID       DWORD ?
hMemory         HANDLE ?
pMemory         DWORD ?
hFile           HANDLE ?
SizeReadWrite   DWORD ?
obsfucator      dd ?
cbNeeded        DWORD ?
cProcesses      DWORD ?
aProcesses      dd 1024 dup(?)
aModules        dd 1024 dup(?)
hMod            HMODULE ?
NewMemory       dd ?
Library         dd ?
ApiAddress      dd ?
