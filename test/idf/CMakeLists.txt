cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(nobetterc_test)

if (${IDF_VERSION_MAJOR} GREATER_EQUAL 5)
    target_link_libraries("${PROJECT_NAME}.elf" PRIVATE "${PROJECT_DIR}/libnobetterc.a")
else()
    target_link_libraries("${PROJECT_NAME}.elf" "${PROJECT_DIR}/libnobetterc.a")
endif()
