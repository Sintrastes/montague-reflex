{ system ? builtins.currentSystem
, obelisk ? import ./.obelisk/impl {
    inherit system;
    iosSdkVersion = "13.2";

	  config.android_sdk.accept_license = true;

    # In order to use Let's Encrypt for HTTPS deployments you must accept
    # their terms of service at https://letsencrypt.org/repository/.
    # Uncomment and set this to `true` to indicate your acceptance:
    # terms.security.acme.acceptTerms = false;
  }
}:
with obelisk;
project ./. ({ pkgs, ... }: {

  android.applicationId = "org.bedelibry.demos.montague";
  android.displayName = "Montague App";
  android.resources = ./static/res;
  ios.bundleIdentifier = "org.bedelibry.demos.montague";
  ios.bundleName = "Montague App";

  packages = {
    frontend-lib = ./frontend-lib;
    m1-frontend = ./m1-frontend;
  };

  overrides = self: super: {
      monad-tree = self.callHackageDirect {
        pkg = "monad-tree";
        ver = "0.2.0.0";
        sha256 = "qU50YWyeM1QI3lGQwboJ0iUlC4c4YTOrv3u/aVagRlg=";
      } {};
      montague = self.callCabal2nix "montague" (pkgs.fetchFromGitHub {
        owner = "sintrastes";
        repo = "montague";
        rev = "10662c40ebc8957dba3add2e4c8a6cc5f6921108";
        sha256 = "RpqUFqapRXglcdecWHwTOsJI6qxWuPcfoYTsOuhWHtI=";
      }) {};
    };
})
