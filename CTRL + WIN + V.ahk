#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

^#v::   ;work with clipboard: paste clipboard content as plain text
    ClipboardOld := ClipboardAll  ;save original clipboard contents
    Clipboard = %Clipboard%  ;store plain text from clipboard to clipboard
    Send ^v  ;send the Ctrl+V command
    Sleep, 250  ;give some time to finish paste (before restoring clipboard)
    Clipboard := ClipboardOld  ;restore the original clipboard contents
    ClipboardOld =  ;clear temporary variable (potentially contains large data)
    Return