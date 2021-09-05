{ stdenv, runCommand }:

{

  emptyFile = builtins.toFile "empty-file" "";

  emptyDirectory = runCommand "empty-directory" {} ''
    mkdir $out
  '';

}
