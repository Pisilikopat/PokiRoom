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

    print("--- Firebase Configuration Done ---")

if __name__ == "__main__":
    configure()
