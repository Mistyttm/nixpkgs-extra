{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  setuptools,
  wheel,
  typer,
  pydantic,
  python-frontmatter,
  rich,
  requests,
  makeWrapper,
  ollama,
  nix-update-script,
}:

buildPythonApplication (finalAttrs: {
  pname = "claude-vault";
  version = "0.6.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "MarioPadilla";
    repo = "claude-vault";
    rev = "v${finalAttrs.version}";
    hash = "sha256-1eJpz1/FjEW1g5MnZRhsaJQBNU8JWy5g07IyTr7cOrA=";
  };

  build-system = [
    setuptools
    wheel
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  dependencies = [
    typer
    pydantic
    python-frontmatter
    rich
    requests
  ];

  # Skip tests as they require test data files
  doCheck = false;

  postFixup = ''
    wrapProgram $out/bin/claude-vault \
      --prefix PATH : ${lib.makeBinPath [ ollama ]}
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Sync Claude AI conversations to Obsidian markdown files";
    longDescription = ''
      Claude Vault is a command-line tool that syncs your Claude AI conversations
      into beautifully formatted Markdown files that integrate seamlessly with
      Obsidian and other note-taking tools. Features include AI-powered tagging
      and summarization using local LLMs (Ollama), bi-directional sync, smart
      updates, UUID tracking, and cross-conversation search.
    '';
    homepage = "https://github.com/MarioPadilla/claude-vault";
    changelog = "https://github.com/MarioPadilla/claude-vault/blob/main/CHANGELOG.md";
    license = lib.licenses.agpl3Plus;
    mainProgram = "claude-vault";
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
})
