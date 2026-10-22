{
  lib,
  stdenv,
  cmake,
  ninja,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "typeshi";
  version = "0.1.18";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase      
    qt6.qtdeclarative
    qt6.qtsvg 
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [
    qt6.qtwayland  
  ];

  meta = {
    description = "Typing application built with Qt/QML";
    mainProgram = "typeshi";
    platforms = lib.platforms.linux;
  };
})
