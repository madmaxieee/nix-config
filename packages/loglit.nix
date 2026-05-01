{
  lib,
  fetchFromGitHub,
  buildGoModule,
  installShellFiles,
}:

let
  version = "unstable-2026-05-01";
in
buildGoModule {
  pname = "loglit";
  inherit version;

  src = fetchFromGitHub {
    owner = "madmaxieee";
    repo = "loglit";
    rev = "aaba086d724951aa394a982c33d388be132e5bb4";
    hash = "sha256-LtUz+iBqj1nuiqP3dypb6Rz++U6ry+BECZ8OmquSTVY=";
  };

  vendorHash = "sha256-ixhruUAIHuG6vmLQ1TImgcgN/xVFiKMgHucD/8MJP/0=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd loglit \
      --bash <($out/bin/loglit completion bash) \
      --fish <($out/bin/loglit completion fish) \
      --zsh <($out/bin/loglit completion zsh)
  '';

  meta = with lib; {
    description = "A CLI tool for syntax highlighting logs in the terminal";
    homepage = "https://github.com/madmaxieee/loglit";
    license = licenses.mit;
    mainProgram = "loglit";
  };
}
