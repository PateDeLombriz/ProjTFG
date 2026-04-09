
from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
    #TokenVerifyView  // No es necesssaris'utilitza per verificara a l'usuari si el seu token es valid
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('apiApp.urls')),  # ✅ tot l’API aquí,
]
  