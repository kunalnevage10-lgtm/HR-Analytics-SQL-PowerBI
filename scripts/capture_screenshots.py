"""
Script to synchronize dashboard.html and capture high-res screenshots for the README
using Microsoft Edge headless mode.
"""

import os
import subprocess
import time

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_HTML = os.path.join(r"C:\Users\Asus\.gemini\antigravity\brain\efd3f382-000b-406c-9aea-5bb5a3aa6a11", "hr_analytics_dashboard.html")
DEST_HTML = os.path.join(PROJECT_ROOT, "dashboard.html")
IMG_DIR = os.path.join(PROJECT_ROOT, "docs", "images")
os.makedirs(IMG_DIR, exist_ok=True)

with open(SRC_HTML, "r", encoding="utf-8") as f:
    content = f.read()

# Replace gstatic script with standard tailwind cdn for local desktop browser compatibility
content = content.replace(
    'src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"',
    'src="https://cdn.tailwindcss.com"'
)

# Add URL hash navigation logic right before </script>
hash_logic = """
    window.addEventListener('DOMContentLoaded', () => {
      const hash = window.location.hash;
      if (hash) {
        const targetTab = hash.substring(1);
        if (document.getElementById(targetTab)) {
          switchTab(targetTab);
        }
      }
    });
"""
content = content.replace("</script>", f"{hash_logic}\n  </script>")

with open(DEST_HTML, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated dashboard.html successfully.")

# Edge executable
edge_exe = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if not os.path.exists(edge_exe):
    edge_exe = r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"

tabs_to_capture = [
    ("tab-overview", "dashboard_overview.png"),
    ("tab-attrition", "dashboard_attrition_drivers.png"),
    ("tab-compensation", "dashboard_compensation_equity.png"),
    ("tab-velocity", "dashboard_talent_velocity.png")
]

for tab_id, img_name in tabs_to_capture:
    out_path = os.path.join(IMG_DIR, img_name)
    file_url = f"file:///{DEST_HTML.replace(os.sep, '/')}#{tab_id}"
    
    cmd = [
        edge_exe,
        "--headless",
        f"--screenshot={out_path}",
        "--window-size=1440,920",
        "--hide-scrollbars",
        file_url
    ]
    print(f"Capturing {img_name} for #{tab_id}...")
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)

print("Screenshot capture complete!")
