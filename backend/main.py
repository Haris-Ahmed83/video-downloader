import os
import uuid
import subprocess
import threading
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(title="Video Downloader API")

DOWNLOADS_DIR = Path("downloads").resolve()
DOWNLOADS_DIR.mkdir(exist_ok=True)

tasks = {}

class DownloadRequest(BaseModel):
    url: str

class DownloadResponse(BaseModel):
    task_id: str
    status: str

class TaskStatus(BaseModel):
    task_id: str
    status: str
    title: str = ""
    error: str = ""

def download_video(url: str, task_id: str):
    try:
        output_template = f"{task_id}.%(ext)s"
        result = subprocess.run(
            ["yt-dlp", "--no-playlist", "-f", "best",
             "-o", output_template,
             "--no-warnings",
             url],
            capture_output=True, text=True, timeout=120,
            cwd=str(DOWNLOADS_DIR)
        )
        stdout = result.stdout.strip()
        stderr = result.stderr.strip()
        print(f"[{task_id}] RC={result.returncode}")
        print(f"[{task_id}] STDERR={stderr[:300]}")
        print(f"[{task_id}] STDOUT={stdout[:300]}")
        print(f"[{task_id}] FILES={[str(f) for f in DOWNLOADS_DIR.iterdir()]}")

        if result.returncode != 0:
            tasks[task_id]["status"] = "error"
            tasks[task_id]["error"] = stderr[:500]
            return

        for f in DOWNLOADS_DIR.iterdir():
            if f.stem == task_id and f.suffix in [".mp4", ".webm", ".mkv", ".avi"]:
                tasks[task_id]["status"] = "completed"
                tasks[task_id]["file_path"] = str(f)
                tasks[task_id]["title"] = f.stem
                return

        tasks[task_id]["status"] = "error"
        tasks[task_id]["error"] = "File not found after download"

    except subprocess.TimeoutExpired:
        tasks[task_id]["status"] = "error"
        tasks[task_id]["error"] = "Download timed out"
    except Exception as e:
        tasks[task_id]["status"] = "error"
        tasks[task_id]["error"] = str(e)

@app.post("/api/download")
def start_download(req: DownloadRequest):
    task_id = str(uuid.uuid4())[:8]
    tasks[task_id] = {"status": "downloading", "file_path": None, "title": "", "error": ""}
    thread = threading.Thread(target=download_video, args=(req.url, task_id), daemon=True)
    thread.start()
    return DownloadResponse(task_id=task_id, status="started")

@app.get("/api/status/{task_id}")
def get_status(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    t = tasks[task_id]
    return TaskStatus(task_id=task_id, status=t["status"], title=t["title"], error=t["error"])

@app.get("/api/video/{task_id}")
def get_video(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    t = tasks[task_id]
    if t["status"] != "completed" or not t.get("file_path"):
        raise HTTPException(status_code=400, detail="Video not ready yet")
    return FileResponse(t["file_path"], media_type="video/mp4",
                        filename=os.path.basename(t["file_path"]))

@app.get("/api/version")
def get_version():
    return {"version": 1, "latest_apk": ""}

@app.get("/health")
def health():
    return {"status": "ok"}
