import os
import uuid
import subprocess
import threading
import shutil
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI(title="Video Downloader API")

DOWNLOADS_DIR = Path("downloads")
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
    output_template = str(DOWNLOADS_DIR / f"{task_id}.%(ext)s")
    try:
        result = subprocess.run(
            ["yt-dlp",
             "--no-playlist",
             "-f", "bestvideo[height<=4320]+bestaudio/best[height<=4320]",
             "--merge-output-format", "mp4",
             "-o", output_template,
             "--print", "filename",
             url],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode != 0:
            tasks[task_id]["status"] = "error"
            tasks[task_id]["error"] = result.stderr.strip()
            return

        output_file = result.stdout.strip().split("\n")[-1]
        if not output_file or not os.path.exists(output_file):
            tasks[task_id]["status"] = "error"
            tasks[task_id]["error"] = "File not found after download"
            return

        file_ext = Path(output_file).suffix
        final_path = DOWNLOADS_DIR / f"{task_id}{file_ext}"
        if output_file != str(final_path):
            shutil.move(output_file, final_path)

        tasks[task_id]["status"] = "completed"
        tasks[task_id]["file_path"] = str(final_path)
        tasks[task_id]["title"] = Path(output_file).stem

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
