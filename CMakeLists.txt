#
# Copyright 2020, Data61, CSIRO (ABN 41 687 119 230)
#
# SPDX-License-Identifier: BSD-2-Clause
#
cmake_minimum_required(VERSION 3.7.2)

project(icecap C)

set(configure_string "")

include(settings.cmake)

# This is a default file that can be copied/symlinked into the top level of a project
# if you have the expected directory layout and you want no customizations beyond
# the defaults provided in the all.cmake

# Try a bunch of different default locations for the script. The different locations
# come about from different project layouts depending on how far through the transition
# from the old build system they are
include(../../tools/seL4/cmake-tool/all.cmake OPTIONAL RESULT_VARIABLE found_all_cmake)
if(NOT found_all_cmake)
    include(tools/cmake-tool/all.cmake OPTIONAL RESULT_VARIABLE found_all_cmake)
    if(NOT found_all_cmake)
        message(FATAL_ERROR "No path for including cmake-tool/all.cmake was successful")
    endif()
endif()

# In future tutorials, these setup steps will be replaced with
# sel4_tutorials_setup_roottask_tutorial_environment()
find_package(seL4 REQUIRED)
find_package(elfloader-tool REQUIRED)
find_package(musllibc REQUIRED)
find_package(util_libs REQUIRED)
find_package(seL4_libs REQUIRED)

#sel4_import_kernel()
#elfloader_import_project()

# This sets up environment build flags and imports musllibc and runtime libraries.
musllibc_setup_build_environment_with_sel4runtime()
util_libs_import_libraries()
sel4_libs_import_libraries()


add_executable(icecap-runtime EXCLUDE_FROM_ALL examples/00-hello-sel4/src/main.c)
target_link_libraries(
    icecap-runtime
    PUBLIC
    sel4runtime sel4
    muslc utils
    sel4muslcsys sel4platsupport sel4utils sel4debug
)
target_compile_options(icecap-runtime PRIVATE -Werror -g)

include(rootserver)
DeclareRootserver(icecap-runtime)

include(simulation)
if(KernelSel4ArchX86_64)
    SetSimulationScriptProperty(MEM_SIZE "3G")
endif()
if(KernelPlatformQEMUArmVirt)
    SetSimulationScriptProperty(MEM_SIZE "2G")
endif()

GenerateSimulateScript()