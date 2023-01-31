include_guard(GLOBAL)
cmake_minimum_version(VERSION 3.16)

# stricter wrapper of cmake_parse_arguments
macro(fun_parse_arguments _fun_parse_arg_num _fun_parse_prefix _fun_parse_flags _fun_parse_one_value _fun_parse_multi_value _fun_parse_required)

    cmake_parse_arguments(PARSE_ARGV ${_fun_parse_arg_num} ${_fun_parse_prefix} 
        "${_fun_parse_flags}" "${_fun_parse_one_value}" "${_fun_parse_multi_value}")

    if (DEFINED ${_fun_parse_prefix}_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "unparsed arguments in function call")
    endif()

    foreach(required IN LISTS _fun_parse_required)
        if (NOT DEFINED ${_fun_parse_prefix}_)
            message(FATAL_ERROR "required argument is not defined: ${required}")
        endif()
    endforeach()
endmacro()

# TODO: testing
# set_if(MY_VAR IF NOT NOT TRUE THEN "set to this")
# set_if(MY_VAR IF NOT TRUE THEN "xxx" ELSE "set to this")
function(set_if output_variable)
    fun_parse_arguments(1 "_arg" "" "" "IF;THEN;ELSE" "IF;THEN")
    if (${_arg_IF})
        set(${output_variable} ${_arg_THEN} PARENT_SCOPE)
    else()
        if (DEFINED _arg_ELSE)
            set(${output_variable} ${_arg_ELSE} PARENT_SCOPE)
        else()
            unset(${output_variable} PARENT_SCOPE)
        endif()
    endif()
endfunction()
