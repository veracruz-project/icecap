target remote :1234

# dir ./result/debug/src
# source ./local/seL4/gdb-macros
set pagination off
add-symbol-file ./result/debug/kernel.elf
b armv_init_user_access
c
clear

add-symbol-file ./result/debug/app.elf
b seL4_TCB_Suspend
c
clear
remove-symbol-file -a 0x400900
b restore_user_context
c
clear

# # target of rarely used seL4_DebugSnapshot(), useful kernel-anchored breakpoint
# b api/syscall.c:94
# c
# clear

layout src
