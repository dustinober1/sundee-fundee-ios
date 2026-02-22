import os
import shutil

src_dir = '/Users/dustinober/Projects/Sundee-Fundee/flutter_app/android/app/src/main/res/'
backup_dir = '/tmp/backup_icons_android/'

for item in os.listdir(src_dir):
    if item.startswith('mipmap-'):
        dir_path = os.path.join(src_dir, item)
        backup_item_path = os.path.join(backup_dir, item)
        
        for icon_name in ['ic_launcher.png', 'ic_launcher_round.png']:
            current_icon_path = os.path.join(dir_path, icon_name)
            period_icon_path = os.path.join(dir_path, icon_name.replace('.png', '_period.png'))
            backup_icon_path = os.path.join(backup_item_path, icon_name)
            
            if os.path.exists(current_icon_path):
                # Move current to period
                shutil.move(current_icon_path, period_icon_path)
            
            if os.path.exists(backup_icon_path):
                # Restore backup to current
                shutil.copy(backup_icon_path, current_icon_path)

print("Android period icons set.")

# For iOS, AppIcon.appiconset is currently Period icons.
ios_xcassets = '/Users/dustinober/Projects/Sundee-Fundee/flutter_app/ios/Runner/Assets.xcassets/'
ios_appicon = os.path.join(ios_xcassets, 'AppIcon.appiconset')
ios_periodicon = os.path.join(ios_xcassets, 'PeriodIcon.appiconset')
ios_backup = '/tmp/backup_icons_ios/AppIcon.appiconset'

if os.path.exists(ios_appicon):
    if os.path.exists(ios_periodicon):
        shutil.rmtree(ios_periodicon)
    shutil.move(ios_appicon, ios_periodicon)

if os.path.exists(ios_backup):
    shutil.copytree(ios_backup, ios_appicon)

print("iOS period icons set.")
