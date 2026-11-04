import os
import shutil

def configure():
    print("--- PokiRoom Firebase Auto-Configurator ---")
    
    # 1. Copy google-services.json
    root_json = "google-services.json"
    target_dir = os.path.join("android", "app")
    target_json = os.path.join(target_dir, "google-services.json")
    
    if os.path.exists(root_json):
        os.makedirs(target_dir, exist_ok=True)
        shutil.copyfile(root_json, target_json)
        print(f"Copied {root_json} -> {target_json}")
    else:
        print(f"WARNING: {root_json} not found in root directory!")

    # 2. Configure Settings Gradle
    settings_kts = os.path.join("android", "settings.gradle.kts")
    settings_groovy = os.path.join("android", "settings.gradle")
    
    if os.path.exists(settings_kts):
        with open(settings_kts, "r", encoding="utf-8") as f:
            content = f.read()
        if "com.google.gms.google-services" not in content:
            plugin_def = '    id("com.google.gms.google-services") version "4.4.2" apply false\n'
            content = content.replace("plugins {", f"plugins {{\n{plugin_def}", 1)
            with open(settings_kts, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Added google-services plugin to {settings_kts}")
        else:
            print(f"google-services already present in {settings_kts}")
    elif os.path.exists(settings_groovy):
        with open(settings_groovy, "r", encoding="utf-8") as f:
            content = f.read()
        if "com.google.gms.google-services" not in content:
            plugin_def = '    id "com.google.gms.google-services" version "4.4.2" apply false\n'
            content = content.replace("plugins {", f"plugins {{\n{plugin_def}", 1)
            with open(settings_groovy, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Added google-services plugin to {settings_groovy}")
        else:
            print(f"google-services already present in {settings_groovy}")

    # 3. Configure App Build Gradle
    app_kts = os.path.join("android", "app", "build.gradle.kts")
    app_groovy = os.path.join("android", "app", "build.gradle")

    if os.path.exists(app_kts):
        with open(app_kts, "r", encoding="utf-8") as f:
            content = f.read()
        if "com.google.gms.google-services" not in content:
            if 'id("dev.flutter.flutter-gradle-plugin")' in content:
                content = content.replace(
                    'id("dev.flutter.flutter-gradle-plugin")',
                    'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")',
                    1
                )
            else:
                content = content.replace("plugins {", 'plugins {\n    id("com.google.gms.google-services")\n', 1)
            with open(app_kts, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Applied google-services plugin in {app_kts}")
        else:
            print(f"google-services already present in {app_kts}")
    elif os.path.exists(app_groovy):
        with open(app_groovy, "r", encoding="utf-8") as f:
            content = f.read()
        if "com.google.gms.google-services" not in content:
            if 'id "dev.flutter.flutter-gradle-plugin"' in content:
                content = content.replace(
                    'id "dev.flutter.flutter-gradle-plugin"',
                    'id "dev.flutter.flutter-gradle-plugin"\n    id "com.google.gms.google-services"',
                    1
                )
            elif "apply plugin: 'com.android.application'" in content:
                content += "\napply plugin: 'com.google.gms.google-services'\n"
            else:
                content = content.replace("plugins {", 'plugins {\n    id "com.google.gms.google-services"\n', 1)
            with open(app_groovy, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Applied google-services plugin in {app_groovy}")
        else:
            print(f"google-services already present in {app_groovy}")

    # 4. Configure App Icons for Android and Web
    src_res = os.path.join("assets", "android_res")
    dst_res = os.path.join("android", "app", "src", "main", "res")
    if os.path.exists(src_res) and os.path.exists(dst_res):
        for folder in os.listdir(src_res):
            src_folder = os.path.join(src_res, folder)
            dst_folder = os.path.join(dst_res, folder)
            if os.path.isdir(src_folder):
                os.makedirs(dst_folder, exist_ok=True)
                for file_name in os.listdir(src_folder):
                    shutil.copyfile(
                        os.path.join(src_folder, file_name),
                        os.path.join(dst_folder, file_name)
                    )
                print(f"Overwrote custom PokiRoom icons in {dst_folder}")

    # 5. Configure AndroidManifest.xml (Permissions, Notification Channel & App Name)
    manifest_path = os.path.join("android", "app", "src", "main", "AndroidManifest.xml")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = f.read()

        # Update app launcher title to PokiRoom
        manifest = manifest.replace('android:label="poki_room"', 'android:label="PokiRoom"')

        permissions = [
            '<uses-permission android:name="android.permission.INTERNET"/>',
            '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
            '<uses-permission android:name="android.permission.VIBRATE"/>',
            '<uses-permission android:name="android.permission.WAKE_LOCK"/>',
            '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
            '<uses-permission android:name="android.permission.RECORD_AUDIO"/>',
            '<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>',
        ]
        for perm in permissions:
            if perm not in manifest:
                manifest = manifest.replace("<application", f"{perm}\n    <application", 1)

        channel_meta = '<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id" android:value="poki_channel"/>'
        if channel_meta not in manifest and "</application>" in manifest:
            manifest = manifest.replace("</application>", f"    {channel_meta}\n    </application>", 1)

        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(manifest)
        print(f"Configured AndroidManifest.xml with app label PokiRoom and notification permissions.")

    # 6. Configure strings.xml if exists
    strings_path = os.path.join("android", "app", "src", "main", "res", "values", "strings.xml")
    if os.path.exists(strings_path):
        with open(strings_path, "r", encoding="utf-8") as f:
            strings = f.read()
        strings = strings.replace("poki_room", "PokiRoom")
        with open(strings_path, "w", encoding="utf-8") as f:
            f.write(strings)
        print(f"Updated app title in {strings_path}")

    print("--- Configuration Done ---")

if __name__ == "__main__":
    configure()
