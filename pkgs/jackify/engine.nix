{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  dotnet-sdk_8,
  dotnet-runtime_8,
  git,
}:

buildDotnetModule rec {
  pname = "jackify-engine";
  version = "0.4.6.0";

  src = fetchFromGitHub {
    owner = "Omni-guides";
    repo = "dev-jackify-engine";
    rev = "209a096268d7f619f71957ea5341d654c93d0a12";
    sha256 = "0ibyswdcf09ssy972ap84hdfgsa77ixjpy9xqrc4r9sjjzkvd9l0";
  };

  projectFile = "jackify-engine/jackify-engine.csproj";

  # Nuget dependencies - would normally be generated via `nuget-to-nix`
  # Since we are in a dev environment without the ability to run that easily,
  # we will use a placeholder. The user will need to update this.
  nugetDeps = ./nuget-deps.json;

  nativeBuildInputs = [ git ];

  dotnet-sdk = dotnet-sdk_8;
  dotnet-runtime = dotnet-runtime_8;

  # Remove global.json to allow using our Nix-provided .NET SDK
  postPatch = ''
    rm global.json
  '';

  # Disable tests as they might require network or complex setup
  doCheck = false;

  dotnetFlags = [
    "-p:Version=${version}"
    "-p:InformationalVersion=${version}"
    "-p:FileVersion=${version}"
    "-p:AssemblyVersion=${version}"
  ];

  meta = with lib; {
    description = "Jackify Engine - Linux-native Wabbajack fork";
    homepage = "https://github.com/omni-guides/dev-jackify-engine";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
