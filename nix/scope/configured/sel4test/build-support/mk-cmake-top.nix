{ writeText, runCommand }:

text:

let
  lists = writeText "CMakeLists.txt" ''
    cmake_minimum_required(VERSION 3.13)

    ${text}
  '';
in
  runCommand "cmake-top" {} ''
    mkdir p $out
    ln -s ${lists} $out/CMakeLists.txt
  ''
