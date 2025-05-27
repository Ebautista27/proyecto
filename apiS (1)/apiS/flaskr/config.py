import cloudinary
import cloudinary.uploader
import cloudinary.api
import os

class Config:
    # Configuración de Cloudinary usando variables de entorno
    CLOUDINARY_CLOUD_NAME = os.getenv('CLOUDINARY_CLOUD_NAME', 'dodecmh9s')
    CLOUDINARY_API_KEY = os.getenv('CLOUDINARY_API_KEY', '333641574248389')
    CLOUDINARY_API_SECRET = os.getenv('CLOUDINARY_API_SECRET', '15J7-StUyiViYmX8URtqUWVc0Co')
    
    @classmethod
    def init_cloudinary(cls):
        cloudinary.config(
            cloud_name=cls.CLOUDINARY_CLOUD_NAME,
            api_key=cls.CLOUDINARY_API_KEY,
            api_secret=cls.CLOUDINARY_API_SECRET,
            secure=True
        )