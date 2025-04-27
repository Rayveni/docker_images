from fastapi import APIRouter, Form, File, UploadFile
# from loguru import logger
from fastapi.responses import StreamingResponse
from fastapi.requests import Request
import json
from .schemas import UploadParams
from ..core.upload import create_export_file

router = APIRouter(prefix="/api", tags=["API"])


@router.get("/url")
async def external_url(request: Request):
    return str(request.url)


@router.post("/upload")
async def upload(upload_params: str = Form(...), file: UploadFile = File(...)):
    _report_params = UploadParams.parse_raw(upload_params)
    output = create_export_file(json.loads(upload_params))
    return StreamingResponse(
        output,
        headers={
            "Content-Disposition": "attachment",
            "filename": "data.xlsx",
            "status": "success",
        },
    )
