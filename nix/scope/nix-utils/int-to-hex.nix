{ lib }:

with lib;

let
  digits = "0123456789abcdef";
  digit = i: substring i 1 digits;
  f = acc: x: if x == 0 then acc else f (digit (mod x 16) + acc) (x / 16);

in

x:

assert x >= 0;

"0x" + (if x == 0 then "0" else f "" x)
