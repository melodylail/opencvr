if(PROTOBUF_SRC_ROOT_FOLDER)
  message(AUTHOR_WARNING "Variable PROTOBUF_SRC_ROOT_FOLDER defined, but not"
    " used in CONFIG mode")
endif()

function(PROTOBUF_GENERATE_CPP SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif()

  if(PROTOBUF_GENERATE_CPP_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobuf_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_protobuf_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  # Add well-known type protos include path
  list(APPEND _protobuf_include_path
    -I "${_PROTOBUF_IMPORT_PREFIX}/include")

  if(DEFINED PROTOBUF_IMPORT_DIRS)
    foreach(DIR ${PROTOBUF_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobuf_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    list(APPEND ${SRCS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.cc")
    list(APPEND ${HDRS} "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h")

    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h"
      COMMAND ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS --cpp_out  ${CMAKE_CURRENT_BINARY_DIR} ${_protobuf_include_path} ${ABS_FIL}
      DEPENDS ${ABS_FIL} ${PROTOBUF_PROTOC_EXECUTABLE}
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM)
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()

# Internal function: search for normal library as well as a debug one
#    if the debug one is specified also include debug/optimized keywords
#    in *_LIBRARIES variable
function(_protobuf_find_libraries name filename)
   get_target_property(${name}_LIBRARY lib${filename}
     IMPORTED_LOCATION_RELEASE)
   set(${name}_LIBRARY "${${name}_LIBRARY}" PARENT_SCOPE)
   get_target_property(${name}_LIBRARY_DEBUG lib${filename}
     IMPORTED_LOCATION_DEBUG)
   set(${name}_LIBRARY_DEBUG "${${name}_LIBRARY_DEBUG}" PARENT_SCOPE)

   if(NOT ${name}_LIBRARY_DEBUG)
      # There is no debug library
      set(${name}_LIBRARY_DEBUG ${${name}_LIBRARY} PARENT_SCOPE)
      set(${name}_LIBRARIES     ${${name}_LIBRARY} PARENT_SCOPE)
   else()
      # There IS a debug library
      set(${name}_LIBRARIES
          optimized ${${name}_LIBRARY}
          debug     ${${name}_LIBRARY_DEBUG}
          PARENT_SCOPE
      )
   endif()
endfunction()

# Internal function: find threads library
function(_protobuf_find_threads)
    set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
    find_package(Threads)
    if(Threads_FOUND)
        list(APPEND PROTOBUF_LIBRARIES ${CMAKE_THREAD_LIBS_INIT})
        set(PROTOBUF_LIBRARIES "${PROTOBUF_LIBRARIES}" PARENT_SCOPE)
    endif()
endfunction()

#
# Main.
#

# By default have PROTOBUF_GENERATE_CPP macro pass -I to protoc
# for each directory where a proto file is referenced.
if(NOT DEFINED PROTOBUF_GENERATE_CPP_APPEND_PATH)
  set(PROTOBUF_GENERATE_CPP_APPEND_PATH TRUE)
endif()

# The Protobuf library
_protobuf_find_libraries(PROTOBUF protobuf)

# The Protobuf Lite library
_protobuf_find_libraries(PROTOBUF_LITE protobuf-lite)

# The Protobuf Protoc Library
_protobuf_find_libraries(PROTOBUF_PROTOC protoc)

if(UNIX)
  _protobuf_find_threads()
endif()

# Set the include directory
set(PROTOBUF_INCLUDE_DIR "${_PROTOBUF_IMPORT_PREFIX}/include")

# Set the protoc Executable
get_target_property(PROTOBUF_PROTOC_EXECUTABLE protoc
  IMPORTED_LOCATION_RELEASE)
if(NOT PROTOBUF_PROTOC_EXECUTABLE)
  get_target_property(PROTOBUF_PROTOC_EXECUTABLE protoc
    IMPORTED_LOCATION_DEBUG)
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PROTOBUF DEFAULT_MSG
    PROTOBUF_LIBRARY PROTOBUF_INCLUDE_DIR)

if(PROTOBUF_FOUND)
    set(PROTOBUF_INCLUDE_DIRS ${PROTOBUF_INCLUDE_DIR})
endif()
