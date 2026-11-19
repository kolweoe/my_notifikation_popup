import os, re

# ---------- AndroidManifest ----------
m = 'android/app/src/main/AndroidManifest.xml'
s = open(m, encoding='utf-8').read()

perms = '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
'''
receivers = '''        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
s = s.replace('<application', perms + '    <application', 1)
s = s.replace('</application>', receivers + '    </application>', 1)
s = s.replace('android:name=".MainActivity"',
              'android:name=".MainActivity"\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="Pengingat"', s, count=1)
open(m, 'w', encoding='utf-8').write(s)

# ---------- Gradle (desugaring) ----------
kts = 'android/app/build.gradle.kts'
groovy = 'android/app/build.gradle'
if os.path.exists(kts):
    g = open(kts, encoding='utf-8').read()
    g = g.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    open(kts, 'w', encoding='utf-8').write(g)
else:
    g = open(groovy, encoding='utf-8').read()
    g = g.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true', 1)
    g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    open(groovy, 'w', encoding='utf-8').write(g)
print('Selesai menerapkan konfigurasi Android')
