cmake_minimum_required(VERSION 3.3)

project(sender_host)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

set (CMAKE_CXX_STANDARD 14)

set(CMAKE_CXX_FLAGS "-Wall -Werror")

add_executable(sender_host main.cpp uart.cpp uart.h) 

# QT

set (CMAKE_PREFIX_PATH "/home/alex/Qt/5.15.2/gcc_64")

find_package(Qt5 COMPONENTS REQUIRED Widgets Gui Core PrintSupport Network SerialPort)

target_link_libraries(sender_host   
  Qt5::Widgets
  Qt5::Core
  Qt5::Gui
  Qt5::PrintSupport
  Qt5::Network
  Qt5::SerialPort)