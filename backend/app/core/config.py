from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://postgres:1234@localhost:5432/teamap_db"
    jwt_secret: str = "dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30
    cors_origins: str = "*"

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
