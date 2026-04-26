{
  lib,
  fetchFromGitHub,
  buildGoModule,
  installShellFiles,
}:

let
  version = "unstable-2026-04-26";
in
buildGoModule {
  pname = "axon";
  inherit version;

  src = fetchFromGitHub {
    owner = "madmaxieee";
    repo = "axon";
    rev = "a8c2eb8880141225c1c3ab170688c86d9c8e0715";
    hash = "sha256-gdzK0C7mpQ6Xq0H5zOLhQDFowkHepIXHnh4rcuZ83Yk=";
  };

  vendorHash = "sha256-2SAZXCW/GZv6ssHUqhXFRsed7Xecg+0+M+9Nk/4lqp8=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd axon \
      --bash <($out/bin/axon completion bash) \
      --fish <($out/bin/axon completion fish) \
      --zsh <($out/bin/axon completion zsh)
  '';

  meta = with lib; {
    description = "A CLI tool for LLM prompts and workflows";
    homepage = "https://github.com/madmaxieee/axon";
    license = licenses.mit;
    mainProgram = "axon";
  };
}
