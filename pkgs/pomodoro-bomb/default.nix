{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  libnotify,
  qt6,
}: let
  pyEnv = python3.withPackages (ps: [ps.pyside6]);
in
  stdenvNoCC.mkDerivation {
    pname = "pomodoro-bomb";
    version = "0.1.0";
    src = ./.;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      mkdir -p $out/share/pomodoro-bomb $out/bin
      cp main.py bomb.qml $out/share/pomodoro-bomb/
      makeWrapper ${pyEnv}/bin/python3 $out/bin/pomodoro-bomb \
        --add-flags "$out/share/pomodoro-bomb/main.py" \
        --prefix PATH : ${libnotify}/bin \
        --prefix QML2_IMPORT_PATH : ${qt6.qtdeclarative}/lib/qt-6/qml \
        --prefix QML_IMPORT_PATH : ${qt6.qtdeclarative}/lib/qt-6/qml \
        --prefix QT_PLUGIN_PATH : ${qt6.qtbase}/lib/qt-6/plugins
    '';

    meta = with lib; {
      description = "Standalone dynamite-styled pomodoro timer";
      platforms = platforms.linux;
    };
  }
