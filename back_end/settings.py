from datetime import timedelta
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent#.parent

# Secret key: fail-fast
SECRET_KEY = os.getenv("DJANGO_SECRET_KEY")
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY is not set")

# Debug parsing robust
DEBUG = os.getenv("DEBUG", "0").lower() in ("1", "true", "yes")

# Allowed hosts robust (no peta si falta ENV)
ALLOWED_HOSTS = os.getenv(
    "DJANGO_ALLOWED_HOSTS",
    "localhost,127.0.0.1,0.0.0.0"
).split(",")
ALLOWED_HOSTS = [h.strip() for h in ALLOWED_HOSTS if h.strip()]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'apiApp.apps.ApiappConfig', #'apiApp',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'cryptography',
    'fastapi',
    'uvicorn',
]

REST_FRAMEWORK = {
    # A partir d'ara, per defecte, totes les vistes intentaran
    # autenticar l'usuari amb el nostre JWT.
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',  # Per admin i test s
        'rest_framework_simplejwt.authentication.JWTAuthentication', #Django admin neceessita aquesta llibreria 
     ],
 
    # Per defecte, totes les vistes requeriran usuari autenticat.
    # Les vistes públiques, com LoginView, ja les deixarem obertes
    # explícitament amb authentication_classes = [] i permission_classes = [].
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'wsgi.application'

# CORS: per defecte restringit. Evita ALLOW_ALL en prod per seguretat.
CORS_ALLOWED_ORIGINS = os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:9000").split(",")
CORS_ALLOWED_ORIGINS = [o.strip() for o in CORS_ALLOWED_ORIGINS if o.strip()]
CORS_ALLOW_ALL_ORIGINS = os.getenv("CORS_ALLOW_ALL_ORIGINS", "false").lower() in ("1", "true", "yes")

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'SLIDING_TOKEN_REFRESH_LIFETIME': timedelta(days=1),
    'SLIDING_TOKEN_LIFETIME': timedelta(days=30),
    'SLIDING_TOKEN_REFRESH_LIFETIME_LATE_USER': timedelta(days=1),
    'SLIDING_TOKEN_LIFETIME_LATE_USER': timedelta(days=30),
    "TOKEN_OBTAIN_SERIALIZER": "apiApp.serializer.MyTokenObtainPairSerializer",
}

DATABASES = {
    'default': {
        'ENGINE': os.getenv("DATABASE_ENGINE", "django.db.backends.postgresql"),
        'NAME': os.getenv("DATABASE_NAME", "obraAgil"),
        'USER': os.getenv("DATABASE_USERNAME", "dbuser"),
        'PASSWORD': os.getenv("DATABASE_PASSWORD", "dbpassword"),
        'HOST': os.getenv("DATABASE_HOST", "db"),
        'PORT': os.getenv("DATABASE_PORT", "5432"),
    }
}

LANGUAGE_CODE = os.getenv("LANGUAGE_CODE", "en-us")
TIME_ZONE = os.getenv("TIME_ZONE", "Europe/Madrid")
USE_I18N = True
USE_TZ = True

AUTH_USER_MODEL= 'apiApp.Usuari'# Necessari per utilitzar simpleJwt

STATIC_URL = 'static/'

# Fitxers pujats pels usuaris: documents, imatges, evidències, etc.
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'


DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'