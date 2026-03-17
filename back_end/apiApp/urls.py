from django.urls import path
from .views import (
    # Obres
    MeView, ObraList, ObraDetail,
    # Empresa / Treballador
    EmpresaList, EmpresaDetail, ObresListEmpresa,
    TreballadorList, TreballadorDetail,
    # Altres entitats
    ContrasenyaList, UbicacioDetail,UbicacioList,
    PermisList, PermisUsuariList, PermisUsuariDetail,
    IncidenciaList, IncidenciaDetail,
    TasquesList, TasquesDetail,
    RecursList, RecursDetail,
    SolucioList, SolucioDetail, SolucioBulkDeleteView,
    DocumentObraList, DocumentObraDetail, DocumentObraUploadView,
    TascaTreballadorList, TascaTreballadorDetail, TascaTreballadorBulkDeleteView,
    SolRecursList, SolRecursDetail,
    ResponsableObraList,
    TreballadorObresParticipadesView, TreballladorTasquesAssignadesView,
    LoginView,
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('', LoginView.as_view(), name='root-login'),
    path('me/', MeView.as_view(), name='me'),
    # Obres
    path('obres/', ObraList.as_view(), name='obra-list'),#Totes les obres
    path ('obresEmpresa/<int:pk>', ObresListEmpresa.as_view(), name='obres-empresa-list'),#Obres d'una empresa
    path('obres/<int:pk>/', ObraDetail.as_view(), name='obra-detail'),

    # Treballadors
    path('treballadors/', TreballadorList.as_view(), name='treballador-list'),
    path('treballadors/<int:pk>/', TreballadorDetail.as_view(), name='treballador-detail'),

    # Empreses
    path('empreses/', EmpresaList.as_view(), name='empresa-list'),
    path('empreses/<int:pk>/', EmpresaDetail.as_view(), name='empresa-detail'),

    # Contrasenyes
    path('contrasenyes/', ContrasenyaList.as_view(), name='contrasenya-list'),
    #Ubicacio
    path('ubicacio/', UbicacioList.as_view(), name='ubicacio-list'),
    path('ubicacio/<int:pk>/', UbicacioDetail.as_view(), name='ubicacio-detail'),

    # Permisos
    path('permis/', PermisList.as_view(), name='permis-list'),
    path('permis_treballador/', PermisUsuariList.as_view(), name='permisusuari-list'),
    path('permis_treballador/<int:pk>/', PermisUsuariDetail.as_view(), name='permisusuari-detail'),

    # Incidències
    path('incidencies/', IncidenciaList.as_view(), name='incidencia-list'),
    path('incidencia/<int:pk>/', IncidenciaDetail.as_view(), name='incidencia-detail'),

    # Tasques
    path('tasques/', TasquesList.as_view(), name='tasques-list'),
    path('tasca/<int:pk>/', TasquesDetail.as_view(), name='tasques-detail'),

    # Recursos
    path('recursos/', RecursList.as_view(), name='recursos-list'),
    path('recursos/<int:pk>/', RecursDetail.as_view(), name='recursos-detail'),

    # Solucions
    path('solucions/', SolucioList.as_view(), name='solucions-list'),
    path('solucions/<int:pk>/', SolucioDetail.as_view(), name='solucions-detail'),
    path('solucions/<int:id_incidencia>/bulk_delete/', SolucioBulkDeleteView.as_view(), name='solucio-bulk-delete'),

    # Documents d’obra
    path('document_obra/', DocumentObraList.as_view(), name='documentobra-list'),
    path('document_obra/<int:pk>/', DocumentObraDetail.as_view(), name='documentobra-detail'),
    path('document_obra/upload/', DocumentObraUploadView.as_view(), name='documentobra-upload'),

    # TascaTreballador
    path('tasca_treballador/', TascaTreballadorList.as_view(), name='tascatreballador-list'),
    path('tasca_treballador/<int:pk>/', TascaTreballadorDetail.as_view(), name='tascatreballador-detail'),
    path('tasca_treballador/<int:id_tasca>/bulk_delete/', TascaTreballadorBulkDeleteView.as_view(), name='tascatreballador-bulk-delete'),

    # Sol·licituds de recursos
    path('sol_recurs/', SolRecursList.as_view(), name='solrecurs-list'),
    path('sol_recurs/<int:pk>/', SolRecursDetail.as_view(), name='solrecurs-detail'),

    # Responsable d’obra (N-a-N; només llista/filtre)
    path('responsable_obra/', ResponsableObraList.as_view(), name='responsableobra-list'),

    # Vistes de conveniència per Treballador
    path('treballadors/<int:treballador_id>/obres_participades/', TreballadorObresParticipadesView.as_view(), name='treballador-obres-participades'),
    path('treballadors/<int:treballador_id>/tasques/', TreballladorTasquesAssignadesView.as_view(), name='treballador-tasques-assignades'),
]
