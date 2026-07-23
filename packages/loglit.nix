{
  lib,
  fetchFromGitHub,
  buildGoModule,
  installShellFiles,
}:

let
  version = "unstable-2026-07-23";
in
buildGoModule {
  pname = "loglit";
  inherit version;

  src = fetchFromGitHub {
    owner = "madmaxieee";
    repo = "loglit";
    rev = "2e880339b40f28c919e76f8f215296ba6efbb9f7";
    hash = "sha256-wHWgA6ehZX5yh3hUfqnSwCU4c+RxQ/XEGUHva6EZHwU=";
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
