

#************************AQUESTS COMENTARIS LES HE AFEGIT JO PERQUE NO M'ENTERAVA DE COM ANAVA

#Qué hace esto?
#DefaultRouter() es un enrutador de Django REST Framework.

#register('rest', ObraViewSet, ...) le dice: “quiero generar automáticamente rutas REST
#  para la vista ObraViewSet bajo la URL base /rest/”.

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ObraList
# Crea un enrutador y registra la vista ObraList
urlpatterns = [
    path('obres/', ObraList.as_view(), name='obra-list'),  # accessible a /api/obres/
]

#Tienes dos formas de interactuar con tu modelo Obra:

#API REST (URLs /rest/, /rest/1/, etc.) — para clientes tipo frontend en React, Postman, móviles, etc.

#Web tradicional con templates HTML (URLs /, /new/, etc.)

#Ambas formas están disponibles porque has hecho: