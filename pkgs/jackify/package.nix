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
  # For desktop file
  copyDesktopItems,
  makeDesktopItem,
  # For Qt wrapping
  qt6,
  makeWrapper,
}:

buildPythonApplication rec {
  pname = "jackify";
  version = "0.2.0.10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Omni-guides";
    repo = "Jackify";
    rev = "v${version}";
    hash = "sha256-OA3uIciM/+KK9HiBcsJZfwF7UqOS5WL4hkCxswQRtlA=";
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

  dependencies = [
    pyside6
    psutil
    requests
    tqdm
    pycryptodome
    pyyaml
    vdf
    packaging
  ];

  # Create a minimal pyproject.toml since upstream doesn't have one
  postPatch = ''
    cat > pyproject.toml << EOF
    [build-system]
    requires = ["setuptools", "wheel"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "jackify"
    version = "${version}"
    description = "Wabbajack modlist installation and configuration tool for Linux"
    requires-python = ">=3.8"

    [project.scripts]
    jackify = "jackify.__main__:main"

    [tool.setuptools.packages.find]
    where = ["."]
    include = ["jackify*"]
    EOF

    # Create __init__.py with version if it doesn't have one
    if ! grep -q "__version__" jackify/__init__.py 2>/dev/null; then
      echo '__version__ = "${version}"' > jackify/__init__.py
    fi
  '';

  # Skip tests as there aren't any defined
  doCheck = false;

  # Ensure Qt wrapper picks up the Python app
  dontWrapQtApps = true;

  # Install assets and wrap with Qt environment
  postInstall = ''
    # Copy GUI assets if they exist
    if [ -d "jackify/frontends/gui/assets" ]; then
      cp -r jackify/frontends/gui/assets $out/${python.sitePackages}/jackify/frontends/gui/
    fi
  '';

  # Wrap the executable with Qt environment variables
  postFixup = ''
    wrapQtApp $out/bin/jackify
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "jackify";
      exec = "jackify";
      desktopName = "Jackify";
      comment = "Wabbajack modlist installation and configuration tool for Linux";
      categories = [
        "Game"
        "Utility"
      ];
      terminal = false;
    })
  ];

  meta = with lib; {
    description = "Wabbajack modlist installation and configuration tool for Linux";
    longDescription = ''
      Jackify is a Linux-native application for installing and configuring
      Wabbajack modlists. It provides both GUI and CLI interfaces for
      seamless modlist management, automated Steam shortcut creation,
      and Proton prefix configuration.
    '';
    homepage = "https://github.com/Omni-guides/Jackify";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ mistyttm ];
    platforms = platforms.linux;
    mainProgram = "jackify";
  };
}
