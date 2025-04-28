"""
Base model configuration for the application.
Provides the base class and database connection settings for all models.
"""
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()