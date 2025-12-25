class AppSetting {
  AppSetting({
    this.providerCurrentVersionAndroidApp,
    this.providerCurrentVersionIosApp,
    this.providerCompulsaryUpdateForceUpdate,
    this.messageForProviderApplication,
    this.providerAppMaintenanceMode,
    this.customerAppAppStoreURL,
    this.customerAppPlayStoreURL,
    this.providerCurrentBuildNumberAndroidApp,
    this.providerCurrentBuildNumberIosApp,
  });

  AppSetting.fromJson(final Map<String, dynamic> json) {
    providerCurrentVersionAndroidApp = json["playstore_version"];
    providerCurrentVersionIosApp = json["appstore_version"];
    providerCompulsaryUpdateForceUpdate = json["app_force_update"] ?? "0";
    customerAppPlayStoreURL = json['playstore_url'] ?? "";
    customerAppAppStoreURL = json['appstore_url'] ?? "";

    providerCurrentBuildNumberAndroidApp = json["playstore_buildnumber"];
    providerCurrentBuildNumberIosApp = json["appstore_buildnumber"];
    providerAppMaintenanceMode = json["provider_app_maintenance_mode"];
  }

  String? providerCurrentVersionAndroidApp;
  String? providerCurrentVersionIosApp;
  String? providerCompulsaryUpdateForceUpdate;
  String? messageForProviderApplication;
  String? providerAppMaintenanceMode;
  String? customerAppAppStoreURL;
  String? customerAppPlayStoreURL;
  String? providerCurrentBuildNumberAndroidApp;
  String? providerCurrentBuildNumberIosApp;

  factory AppSetting.initial() => AppSetting(
        providerCurrentVersionAndroidApp: "0.0.1",
        providerCurrentVersionIosApp: "1.0.0",
        providerCompulsaryUpdateForceUpdate: "0",
        messageForProviderApplication: "",
        providerAppMaintenanceMode: "0",
        customerAppPlayStoreURL:
            "https://play.google.com/store/apps/details?id=opendoorsapp.com",
        customerAppAppStoreURL: "https://apps.apple.com/app/id6746260499",
        providerCurrentBuildNumberAndroidApp: "1",
        providerCurrentBuildNumberIosApp: "1",
      );

  get appSetting => AppSetting(
        providerCurrentVersionAndroidApp: "0.0.1",
        providerCurrentVersionIosApp: "1.0.0",
        providerCompulsaryUpdateForceUpdate: "0",
        messageForProviderApplication: "",
        providerAppMaintenanceMode: "0",
        customerAppPlayStoreURL:
            "https://play.google.com/store/apps/details?id=opendoorsapp.com",
        customerAppAppStoreURL: "https://apps.apple.com/app/id6746260499",
        providerCurrentBuildNumberAndroidApp: "1",
        providerCurrentBuildNumberIosApp: "1",
      );
}
