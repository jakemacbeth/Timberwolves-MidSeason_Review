from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.pool import Pool
from typing import Optional

from config import get_config
from src.utils.logger import setup_logger

logger = setup_logger(__name__)

# Global engine instance (singleton)
_engine: Optional[Engine] = None


def get_engine(force_reload: bool = False) -> Engine:

    global _engine
    
    if _engine is not None and not force_reload:
        return _engine
    
    config = get_config()
    db_config = config.db
    
    logger.info(f"Creating database engine for {db_config.host}:{db_config.port}/{db_config.name}")
    
    _engine = create_engine(
        db_config.connection_url,
        
        # Connection pool settings
        pool_size=db_config.pool_size,
        max_overflow=db_config.max_overflow,
        pool_recycle=db_config.pool_recycle,
        pool_pre_ping=db_config.pool_pre_ping,
        
        # Connection arguments
        connect_args={
            "connect_timeout": 10,
            "options": "-c timezone=utc",
        },
        
        echo=False,
        poolclass=None, 
    )
    
    _setup_engine_events(_engine)
    
    logger.info("Database engine created successfully")
    
    return _engine


def _setup_engine_events(engine: Engine) -> None:

    
    @event.listens_for(engine, "connect")
    def receive_connect(dbapi_conn, connection_record):
        logger.debug("New database connection established")
    
    @event.listens_for(engine, "close")
    def receive_close(dbapi_conn, connection_record):
        logger.debug("Database connection closed")
    
    @event.listens_for(Pool, "checkout")
    def receive_checkout(dbapi_conn, connection_record, connection_proxy):
        logger.debug("Connection checked out from pool")
    
    @event.listens_for(Pool, "checkin")
    def receive_checkin(dbapi_conn, connection_record):
        logger.debug("Connection returned to pool")


def dispose_engine() -> None:

    global _engine
    
    if _engine is not None:
        logger.info("Disposing database engine")
        _engine.dispose()
        _engine = None


def get_pool_status() -> dict:

    engine = get_engine()
    pool = engine.pool
    
    return {
        "size": pool.size(),
        "checked_out": pool.checkedout(),
        "overflow": pool.overflow(),
        "checked_in": pool.size() - pool.checkedout(),
    }