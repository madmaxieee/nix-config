{ ... }:
rec {
  programs.fish.shellAbbrs = {
    a = "adb";
    al = "adb logcat";
    ar = "adb root";
    arr = "adb reboot";
    as = "adb shell";
    aw = "adb wait-for-device";
    f = "fastboot";
    fr = "fastboot reboot";
  };
  programs.zsh.zsh-abbr.abbreviations = programs.fish.shellAbbrs;
}
