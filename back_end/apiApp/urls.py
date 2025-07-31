

#************************AQUESTS COMENTARIS LES HE AFEGIT JO PERQUE NO M'ENTERAVA DE COM ANAVA

#Qué hace esto?
#DefaultRouter() es un enrutador de Django REST Framework.

#register('rest', ObraViewSet, ...) le dice: “quiero generar automáticamente rutas REST
#  para la vista ObraViewSet bajo la URL base /rest/”.

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    # Existents (corregits)
    ObraList, ObraDetail,
    UsuariList,UsuariDetail,
    UPersonaDetail,UPersonaList, UEmpresaList,
    ContrasenyaList,
    PermisList,
    PermisUsuariList, PermisUsuariDetail,
    IncidenciaList, IncidenciaDetail,
    TasquesList, TasquesDetail,
    RecursosList, RecursDetail,
    SolucioList, SolucioDetail,
    DocumentObraList, DocumentObraDetail, DocumentObraUploadView,
    TascaTreballadorList, TascaTreballadorDetail, TascaTreballadorBulkDeleteView,
    SolucioBulkDeleteView,LoginView,
    SolRecursList, SolRecursDetail,
    # Nous
    ResponsableObraList, 
    UsuariObresParticipadesView,
    UsuariTasquesAssignadesView,
)# Crea un enrutador y registra la vista ObraList
urlpatterns = [
    path('api/login/', LoginView.as_view(), name='login'),
    # --- EXISTENTS (amb correccions) ---
    path('obres/', ObraList.as_view(), name='obra-list'),
    path('obres/<int:pk>/', ObraDetail.as_view(), name='obra-detail'),

    path('usuaris/', UsuariList.as_view(), name='usuari-list'),
    path('usuaris/<int:pk>/', UsuariDetail.as_view(), name='usuari-detail'), 
    path('u_persona/', UPersonaList.as_view(), name='persona-list'), 
    path('u_persona/<int:pk>/', UPersonaDetail.as_view(), name='persona-detail'),
    path('empreses/', UEmpresaList.as_view(), name='empresa-list'),
    path('contrasenyes/', ContrasenyaList.as_view(), name='contrasenya-list'),

    path('permis/', PermisList.as_view(), name='permis-list'),  # ← treu coma
    #path('permis/<int:pk>/', PermisDetail.as_view(), name='permis-detail'),

    path('permis_usuari/', PermisUsuariList.as_view(), name='permisusuari-list'),
    path('permis_usuari/<int:pk>/', PermisUsuariDetail.as_view(), name='permisusuari-detail'),

    path('incidencies/', IncidenciaList.as_view(), name='incidencia-list'),
    path('incidencia/<int:pk>/', IncidenciaDetail.as_view(), name='incidencia-detail'),

    path('tasques/', TasquesList.as_view(), name='tasques-list'),
    path('tasca/<int:pk>/', TasquesDetail.as_view(), name='tasques-detail'),

    path('recursos/', RecursosList.as_view(), name='recursos-list'),
    path('recursos/<int:pk>/', RecursDetail.as_view(), name='recursos-detail'),

    path('solucions/', SolucioList.as_view(), name='solucions-list'),
    path('solucions/<int:pk>/', SolucioDetail.as_view(), name='solucions-detail'),

    # --- DOCUMENTS OBRA ---
    path('document_obra/', DocumentObraList.as_view(), name='documentobra-list'),
    path('document_obra/<int:pk>/', DocumentObraDetail.as_view(), name='documentobra-detail'),
    path('document_obra/upload/', DocumentObraUploadView.as_view(), name='documentobra-upload'),#"detail": "Method \"GET\" not allowed."

    # --- TASCA TREBALLADOR ---
    path('tasca_treballador/', TascaTreballadorList.as_view(), name='tascatreballador-list'),
    path('tasca_treballador/<int:pk>/', TascaTreballadorDetail.as_view(), name='tascatreballador-detail'),
    path('tasca_treballador/<int:id_tasca>/bulk_delete/', TascaTreballadorBulkDeleteView.as_view(), name='tascatreballador-bulk-delete'),#"detail": "Method \"GET\" not allowed."

    # --- SOLUCIONS (bulk delete per incidència) --- no furula
    path('solucions/<int:id_incidencia>/bulk_delete/', SolucioBulkDeleteView.as_view(), name='solucio-bulk-delete'),

    # --- SOL·LICITUDS DE RECURSOS ---
    path('sol_recurs/', SolRecursList.as_view(), name='solrecurs-list'),
    path('sol_recurs/<int:pk>/', SolRecursDetail.as_view(), name='solrecurs-detail'),

    # --- RESPONSABLE OBRA (nou) ---
    # Filters: ?id_treballador= &id_obra= &actiu=1  (actiu := data_fi is null)
    path('responsable_obra/', ResponsableObraList.as_view(), name='responsableobra-list'),
    # Com que el PK és id_obra (OneToOne), el detail va per obra
    #path('responsables/<int:id_obra>/', ResponsableObraDetail.as_view(), name='responsableobra-detail'),

    # --- Vistes de conveniència per al Perfil Treballador (nous) ---
    # Obres on ha participat (per tasques i/o responsable)
    path('usuaris/<int:usuari_id>/obres_participades/', UsuariObresParticipadesView.as_view(), name='usuari-obres-participades'),
    # Tasques assignades a l'usuari (join tasca_treballador)
    path('usuaris/<int:usuari_id>/tasques/', UsuariTasquesAssignadesView.as_view(), name='usuari-tasques-assignades'),
]

#Tienes dos formas de interactuar con tu modelo Obra:

#API REST (URLs /rest/, /rest/1/, etc.) — para clientes tipo frontend en React, Postman, móviles, etc.

#Web tradicional con templates HTML (URLs /, /new/, etc.)

#Ambas formas están disponibles porque has hecho: