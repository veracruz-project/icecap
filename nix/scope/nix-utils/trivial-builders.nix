{ stdenv, runtimeShell, runCommand, writeTextFile }:

{

  emptyFile = builtins.toFile "empty-file" "";

  emptyDirectory = runCommand "empty-directory" {} ''
    mkdir $out
  '';

  writeShellScript = name: text:
    writeTextFile {
      inherit name;
      executable = true;
      text = ''
        #!${runtimeShell}
        ${text}
        '';
      checkPhase = ''
        ${stdenv.shell} -n $out
      '';
    };

}
