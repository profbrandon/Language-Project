@echo off

nasm -f win32 -Ox printf.asm
link /ENTRY:main /SUBSYSTEM:console /LIBPATH "C:/masm32/lib/kernel32.lib" printf.obj

@echo on