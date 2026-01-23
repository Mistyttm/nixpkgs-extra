{ lib
, stdenv
, fetchFromGitHub
, php83
, buildNpmPackage
, makeWrapper
}:

let
  # Create PHP with required extensions
  php = php83.withExtensions ({ enabled, all }: with all;
    enabled ++ [
      ctype
      curl
      dom
      fileinfo
      filter
      mbstring
      openssl
      pdo
      pdo_sqlite
      session
      tokenizer
      zip
    ]
  );
in buildNpmPackage (finalAttrs:{
  pname = "heimdall";
  version = "2.7.6";

   src = fetchFromGitHub {
    owner = "linuxserver";
    repo = "Heimdall";
    rev = "v${finalAttrs.version}";
    hash = "sha256-edV57cc9F8P+Sc3mBB8Bm31Q76SQDxV4nKbz2bpwzuo=";
  };

  npmDepsHash = "sha256-KQuqG8SsUzrKZD6cqSd2EcLtilrT8a+vj+DGHcaXX/A=";

  # Build-time dependencies
  nativeBuildInputs = [
    php
    php.packages.composer
    makeWrapper
  ];

  # Don't run npm install, buildNpmPackage handles it
  dontNpmInstall = true;

  preBuild = ''
    # Install PHP dependencies
    export HOME=$TMPDIR
    ${php.packages.composer}/bin/composer install \
      --no-dev \
      --no-interaction \
      --no-progress \
      --no-scripts \
      --optimize-autoloader
  '';

  buildPhase = ''
    runHook preBuild
    
    npm run production

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/heimdall

    # Copy application files
    cp -r . $out/share/heimdall/

    # Remove build artifacts and unnecessary files
    rm -rf $out/share/heimdall/node_modules
    rm -rf $out/share/heimdall/tests
    rm -rf $out/share/heimdall/.git
    rm -rf $out/share/heimdall/.github
    rm -f $out/share/heimdall/.env.example
    rm -f $out/share/heimdall/.gitignore
    rm -f $out/share/heimdall/.gitattributes
    rm -f $out/share/heimdall/package*.json
    rm -f $out/share/heimdall/webpack.mix.js
    rm -f $out/share/heimdall/.eslintrc
    rm -f $out/share/heimdall/.eslintignore

    # Ensure required directories exist
    mkdir -p $out/share/heimdall/storage/framework/{cache,sessions,views}
    mkdir -p $out/share/heimdall/storage/logs
    mkdir -p $out/share/heimdall/bootstrap/cache

    # Create wrapper script for artisan
    mkdir -p $out/bin
    makeWrapper ${php}/bin/php $out/bin/heimdall-artisan \
      --add-flags "$out/share/heimdall/artisan" \
      --chdir "$out/share/heimdall"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Application dashboard and launcher";
    longDescription = ''
      Heimdall Application Dashboard is a dashboard for all your web applications.
      It doesn't need to be limited to applications though, you can add links to
      anything you like. Heimdall is an elegant solution to organise all your
      web applications.
    '';
    homepage = "https://heimdall.site";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
})
