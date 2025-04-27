from pydantic import BaseModel, ConfigDict


class BaseModelConfig(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class UploadParams(BaseModelConfig):
    tentacles: str
    name: str
