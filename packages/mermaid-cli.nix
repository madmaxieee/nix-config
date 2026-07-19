{
  stdenv,
  symlinkJoin,
  makeWrapper,
  mermaid-cli,
}:

if stdenv.isDarwin then
  symlinkJoin {
    name = "mermaid-cli-wrapped";
    paths = [ mermaid-cli ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mmdc \
        --set PUPPETEER_EXECUTABLE_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    '';
  }
else
  mermaid-cli
