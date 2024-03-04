-keep class net.sqlcipher.** { *; }

-assumenosideeffects class android.content.pm.PackageManager  {
  public boolean canRequestInstallPackage();
}