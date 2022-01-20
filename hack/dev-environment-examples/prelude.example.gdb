target remote :1234

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

layout src
