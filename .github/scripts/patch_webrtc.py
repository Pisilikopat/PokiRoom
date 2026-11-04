import os
import re

def patch():
    print("--- PokiRoom WebRTC / compileSdk Auto-Patcher ---")
    cache_dirs = [
        os.environ.get("PUB_CACHE", ""),
        os.path.expanduser("~/.pub-cache"),
        "/home/runner/.pub-cache",
    ]
    patched_count = 0
    for cdir in cache_dirs:
        if not cdir or not os.path.exists(cdir):
            continue
        print(f"Scanning pub cache in: {cdir}")
        for root, _, files in os.walk(cdir):
            for file in files:
                if file in ("build.gradle", "build.gradle.kts"):
                    path = os.path.join(root, file)
                    try:
                        with open(path, "r", encoding="utf-8") as f:
                            content = f.read()

                        def bump(m):
                            val = int(m.group(1))
                            if val < 34:
                                return m.group(0).replace(str(val), '34', 1)
                            return m.group(0)

                        new_content = re.sub(r'compileSdkVersion\s*\(?\s*(\d+)\s*\)?', bump, content)
                        new_content = re.sub(r'compileSdk\s*=\s*(\d+)', bump, new_content)
                        if new_content != content:
                            with open(path, "w", encoding="utf-8") as f:
                                f.write(new_content)
                            print(f"Patched compileSdkVersion -> 34 in {path}")
                            patched_count += 1
                    except Exception as e:
                        pass
    print(f"--- Patching Done: {patched_count} files patched ---")

if __name__ == "__main__":
    patch()
