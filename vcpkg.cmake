include_guard(GLOBAL)
cmake_minimum_version(VERSION 3.16)

include("${CMAKE_CURRENT_LIST_DIR}/common.cmake")

# clone a local vcpkg install if user doesn't already have
# must be called before project()
# sets the toolchain file to vcpkg.cmake
# recommended to add /vcpkg to .gitignore
# set VCPKG_ROOT or ENV{VCPKG_ROOT} to use an alternate vcpkg install location
function(fun_bootstrap_vcpkg)
    cmake_parse_arguments(PARSE_ARGV 0 _arg "NO_SYSTEM" "VERSION_TAG" "")

    if(DEFINED _arg_VERSION_TAG)
        set(version_tag_opt "--branch ${_arg_VERSION_TAG}")
    else()
        set(version_tag_opt "")
    endif()

    # custom toolchain and first run
    if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT DEFINED VCPKG_ROOT)
        message(STATUS "using custom toolchain, include vcpkg to build dependencies.")
        return()
    endif()

    if(DEFINED ENV{VCPKG_ROOT} AND NOT _arg_NO_SYSTEM)
        set(vcpkg_default_root "$ENV{VCPKG_ROOT}")
    else()
        set(vcpkg_default_root "${CMAKE_SOURCE_DIR}/vcpkg")
    endif()

    set(VCPKG_ROOT "${vcpkg_default_root}" CACHE PATH "vcpkg root directory")
    message(STATUS "vcpkg root: ${VCPKG_ROOT}")

    if(WIN32)
        set(vcpkg_cmd "${VCPKG_ROOT}/${vcpkg_cmd}")
        set(vcpkg_bootstrap_cmd "${VCPKG_ROOT}/bootstrap-vcpkg.bat")
    else()
        set(vcpkg_cmd "${VCPKG_ROOT}/${vcpkg_cmd}")
        set(vcpkg_bootstrap_cmd "${VCPKG_ROOT}/bootstrap-vcpkg.sh")
    endif()

    if(NOT EXISTS "${vcpkg_bootstrap_cmd}")
        find_package(Git)
        execute_process(COMMAND "${GIT_EXECUTABLE}" clone --filter=tree:0 "https://github.com/microsoft/vcpkg.git" "${VCPKG_ROOT}")

        if(NOT EXISTS "${vcpkg_bootstrap_cmd}")
            message(FATAL_ERROR "failed to clone vcpkg")
        endif()
    endif()

    if(NOT EXISTS "${vcpkg_cmd}")
        execute_process(COMMAND "${vcpkg_bootstrap_cmd}" -disableMetrics
            WORKING_DIRECTORY "${VCPKG_ROOT}")

        if(NOT EXISTS "${vcpkg_cmd}")
            message(FATAL_ERROR "failed to bootstrap vcpkg")
        endif()
    endif()

    if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
        set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
    endif()
endfunction()

# guess a vcpkg triplet for this platform
function(fun_guess_vcpkg_triplet out_triplet)
    set(target_arch "x64")

    if(WIN32)
        set(triplet "${target_arch}-windows")

        if(NOT BUILD_SHARED_LIBS)
            set(triplet "${triplet}-static")
        endif()
    elseif(UNIX)
        if(APPLE)
            set(triplet "${target_arch}-osx")
        else()
            set(triplet "${target_arch}-linux")
        endif()

        if(BUILD_SHARED_LIBS)
            set(triplet "${triplet}-dynamic")
        endif()
    endif()

    set(${out_triplet} "${triplet}" PARENT_SCOPE)
endfunction()
