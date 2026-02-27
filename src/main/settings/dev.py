from .base import *

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

CSRF_TRUSTED_ORIGINS = ["*"]

try:
    from .local import *
except ImportError:
    pass
