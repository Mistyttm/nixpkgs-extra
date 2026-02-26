{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  python,
  # Build dependencies
  setuptools,
  wheel,
  # Runtime dependencies
  pyside6,
  psutil,
  requests,
  tqdm,
  pycryptodome,
  pyyaml,
  vdf,
  packaging,
  cryptography,
  # For desktop file
  copyDesktopItems,
  makeDesktopItem,
  # For Qt wrapping
  qt6,
  makeWrapper,
  # Runtime tools
  xdg-utils,
  libnotify,
  steam-run,
  winetricks,
  cabextract,
  _7zz,
  gnutar,
  unzip,
  # Update script
  nix-update-script,
  callPackage,
}:

let
  version = "0.4.0";
  jackify-engine = callPackage ./jackify-engine/engine.nix { };
in
buildPythonApplication {
  pname = "jackify";
  inherit version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Omni-guides";
    repo = "Jackify";
    rev = "v${version}";
    sha256 = "sha256-tvM7ajj4G4O9jdqr5doEbRR6gPrCzVaIR+d8BM6MK08=";
  };

  build-system = [
    setuptools
    wheel
  ];

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtwayland
  ];

  patches = [
    ./patches/fix-protocol-registration.patch
    ./patches/add-pyproject.patch
    ./patches/disable-auto-update.patch
    ./patches/fix-protocol-handler.patch
    ./patches/fix-settings-oauth-freeze.patch
    ./patches/use-steam-run.patch
  ];

  dependencies = [
    pyside6
    psutil
    requests
    tqdm
    pycryptodome
    pyyaml
    vdf
    packaging
    cryptography
  ];

  # Skip tests as there aren't any defined
  doCheck = false;

  passthru = {
    inherit jackify-engine;
  };

  # Ensure Qt wrapper picks up the Python app
  dontWrapQtApps = true;

  # Install assets and wrap with Qt environment
  postInstall = ''
    # Remove bundled binaries to force usage of system tools
    rm -f jackify/tools/{winetricks,cabextract,7z,7zz}

    # Copy GUI assets if they exist
    if [ -d "jackify/frontends/gui/assets" ]; then
      cp -r jackify/frontends/gui/assets $out/${python.sitePackages}/jackify/frontends/gui/
    fi
  '';

  # Wrap the executable with Qt environment variables and runtime dependencies
  postFixup = ''
    wrapQtApp $out/bin/jackify \
      --set JACKIFY_ENGINE_PATH "${jackify-engine}/bin/jackify-engine" \
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          libnotify
          jackify-engine
          steam-run
          winetricks
          cabextract
          _7zz
          gnutar
          unzip
        ]
      }
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "jackify";
      exec = "jackify %u";
      desktopName = "Jackify";
      comment = "Wabbajack modlist installation and configuration tool for Linux";
      mimeTypes = [ "x-scheme-handler/jackify" ];
      categories = [
        "Game"
        "Utility"
      ];
      terminal = false;
    })
  ];

  meta = {
    description = "Wabbajack modlist installation and configuration tool for Linux";
    longDescription = ''
      Jackify is a Linux-native application for installing and configuring
      Wabbajack modlists. It provides both GUI and CLI interfaces for
      seamless modlist management, automated Steam shortcut creation,
      and Proton prefix configuration.
    '';
    homepage = "https://github.com/Omni-guides/Jackify";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "jackify";
  };

  passthru.updateScript = nix-update-script { };
}
