from .base import *
import os

DEBUG = False

# ManifestStaticFilesStorage is recommended in production, to prevent
# outdated JavaScript / CSS assets being served from cache
# (e.g. after a Wagtail upgrade).
# See https://docs.djangoproject.com/en/6.0/ref/contrib/staticfiles/#manifeststaticfilesstorage
STORAGES["staticfiles"]["BACKEND"] = (
    "django.contrib.staticfiles.storage.ManifestStaticFilesStorage"
)

csrf_trusted_origins_env = os.environ.get("CSRF_TRUSTED_ORIGINS", "")
if csrf_trusted_origins_env:
    CSRF_TRUSTED_ORIGINS = csrf_trusted_origins_env.split(" ")

try:
    from .local import *
except ImportError:
    pass
