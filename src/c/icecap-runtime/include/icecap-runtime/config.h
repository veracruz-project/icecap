#pragma once

#include <icecap-runtime/config_in.h>

#ifdef ICECAP_RUNTIME_ROOT
  #ifndef ICECAP_RUNTIME_ROOT_STACK_SIZE
    #define ICECAP_RUNTIME_ROOT_STACK_SIZE 0x200000
  #endif
  #ifndef ICECAP_RUNTIME_ROOT_HEAP_SIZE
    #define ICECAP_RUNTIME_ROOT_HEAP_SIZE 0x200000
  #endif
#endif
