{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [ closurecompiler gawk gnumake zip emacs watchexec curl gnugrep ];
}
