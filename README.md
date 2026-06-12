# Video Downloader

Instagram aur TikTok videos download karein — share karte hi!

## Architecture

```
Phone (Flutter App) ←→ Railway (FastAPI + yt-dlp)
```

## Setup Steps

### 1. GitHub Repo banao

```bash
# Is folder ko GitHub pe push karo
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/video-downloader.git
git push -u origin main
```

### 2. Railway pe Backend Deploy karo

1. Railway.com pe new account banao (naya email)
2. Dashboard → **New Project** → **Deploy from GitHub repo**
3. Apna repo select karo
4. Railway auto-detect kare ga Dockerfile → deploy ho jaye ga
5. Deploy hone ke baad → **Settings** → **Generate Domain** → URL copy karo (jaise `https://your-app.railway.app`)

### 3. Flutter App mein URL set karo

File: `flutter_app/lib/config.dart`

```dart
static const String backendUrl = 'https://your-app.railway.app';  // Railway URL yahan lagao
```

### 4. APK Build karo

**Option A: GitHub Actions (auto build)**

Push karte hi GitHub Actions APK build kare ga:
- GitHub repo mein **Actions** tab → **Build APK** workflow
- Complete hone par APK download karo

**Option B: Apne PC pe build karo**

```bash
cd flutter_app
flutter pub get
flutter build apk --debug
# APK location: build/app/outputs/flutter-apk/app-debug.apk
```

### 5. Phone mein Install karo

APK file phone mein transfer karo → Install karo → Open karo

### 6. Use karo

1. Instagram/TikTok open karo
2. Koi video → **Share** button dabao
3. Share sheet mein **Video Downloader** select karo
4. App open ho ga → automatically download start ho jaye ga
5. 2-5 sec mein gallery mein save ho jaye ga!

## Project Structure

```
video-downloader/
├── backend/
│   ├── main.py              # FastAPI server
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Railway deployment
├── flutter_app/
│   ├── lib/
│   │   ├── config.dart          # Backend URL config
│   │   ├── main.dart            # App entry + share listener
│   │   ├── screens/
│   │   │   └── home_screen.dart # Main UI
│   │   └── services/
│   │       ├── api_service.dart        # Backend API calls
│   │       ├── download_service.dart   # Download logic
│   │       └── notification_service.dart # Notifications
│   ├── android/
│   └── pubspec.yaml
├── railway.json
└── README.md
```

## Notes

- Backend Railway pe deploy hai, 24/7 online
- Videos phone ke gallery mein save hoti hain
- 4K/2K support hai agar source pe available ho
- Personal use ke liye hai
