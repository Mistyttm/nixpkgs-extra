{
  buildPythonPackage,
  lib,
  fetchFromGitHub,
  fetchPypi,
  pypresence,
  beautifulsoup4,
  requests,
  psutil,
  setuptools,
  wheel,
  python,
  nix-update-script,
}:
let
  python-steamgriddb = buildPythonPackage {
    pname = "python-steamgriddb";
    version = "1.0.5";
    format = "pyproject";

    src = fetchPypi {
      pname = "python-steamgriddb";
      version = "1.0.5";
      hash = "sha256-A223uwmGXac7QLaM8E+5Z1zRi0kIJ1CS2R83vxYkUGk=";
    };

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
      requests
    ];

    meta = {
      description = "Python library for SteamGridDB API";
      homepage = "https://pypi.org/project/python-steamgriddb/";
      license = lib.licenses.mit;
    };
  };
in
buildPythonPackage {
  pname = "steam-presence";
  version = "v1.12.2";
  format = "other";

  src = fetchFromGitHub {
    owner = "JustTemmie";
    repo = "steam-presence";
    rev = "5439cfe35e154f7a80c6a6b1fc160d2b431a7584";
    hash = "sha256-6w8ZsLc0+p0EByNhbs10+5AWvOiEmIE1eyxoN4VHYhQ=";
  };

  propagatedBuildInputs = [
    pypresence
    beautifulsoup4
    requests
    psutil
    python-steamgriddb
  ];

  patches = [
    ./0001-feat-convert-absolute-baths-to-use-the-xdg-spec.patch
  ];

  doCheck = false;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        mkdir -p $out/${python.sitePackages}/steam_presence

        # Copy all Python files to the package directory
        find . -name "*.py" -exec cp {} $out/${python.sitePackages}/steam_presence/ \;

        # Look for the main script and create a wrapper
        if [ -f "main.py" ]; then
          cat > $out/bin/steam-presence << EOF
    #!${python}/bin/python
    import sys
    sys.path.insert(0, '$out/${python.sitePackages}')
    import steam_presence.main
    if __name__ == '__main__':
        steam_presence.main.main() if hasattr(steam_presence.main, 'main') else exec(open('$out/${python.sitePackages}/steam_presence/main.py').read())
    EOF
        elif [ -f "steam_presence.py" ]; then
          cat > $out/bin/steam-presence << EOF
    #!${python}/bin/python
    import sys
    sys.path.insert(0, '$out/${python.sitePackages}')
    exec(open('$out/${python.sitePackages}/steam_presence/steam_presence.py').read())
    EOF
        else
          # Fallback: create a generic wrapper
          cat > $out/bin/steam-presence << EOF
    #!${python}/bin/python
    import sys
    import os
    sys.path.insert(0, '$out/${python.sitePackages}')
    os.chdir('$out/${python.sitePackages}/steam_presence')
    exec(open('$(ls $out/${python.sitePackages}/steam_presence/*.py | head -1)').read())
    EOF
        fi

        chmod +x $out/bin/steam-presence

        runHook postInstall
  '';

  meta = {
    description = "Display your currently played Steam game in Discord";
    homepage = "https://github.com/JustTemmie/steam-presence";
    license = lib.licenses.gpl3Plus; # Check the actual license
    maintainers = with lib.maintainers; [ mistyttm ];
  };

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
