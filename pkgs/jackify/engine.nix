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
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "Omni-guides";
    repo = "dev-jackify-engine";
    rev = "0b82ee9d07b9f62895231cea9440df0fc47a92ff";
    sha256 = "0k0nhqmwyinmgy8q0vhd9lqnsxmh6hfb4ay9zvm953w467l6gs27";
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
