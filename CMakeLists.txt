cmake_minimum_required(VERSION 3.20)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED TRUE)

project(zeus VERSION 1.0)

add_executable(zeus src/main.c)

target_include_directories(zeus PRIVATE ./include/)
