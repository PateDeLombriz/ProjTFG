from django.urls import path
from .views import (
    ContracteTreballadorDetail, MeView, ObraDetail,
    EmpresaDetail, ObresListEmpresa, RegistreHorariMeView, TasquesList,
    TreballadorDetail, TreballadorEmpresaList, TreballadorMeObresParticipadesView, TreballadorMeTascaFinalitzarView, TreballadorMeTasquesView, TreballadorProfileView,
    UbicacioDetail,PermisUsuariList, PermisUsuariDetail,IncidenciaList, IncidenciaDetail,TasquesDetail,
    RecursList, RecursDetail,
    SolucioList, SolucioDetail, SolucioBulkDeleteView,
    DocumentObraList, DocumentObraDetail,
    TascaTreballadorList, TascaTreballadorDetail, TascaTreballadorBulkDelete,
    SolRecursList, SolRecursDetail,
    ResponsableObraList,
    LoginView,EmpresaRegisterView
)

urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('register/empresa/', EmpresaRegisterView.as_view(), name='register-empresa'),
    path('me/', MeView.as_view(), name='me'),
    path('empreses/<int:pk>/', EmpresaDetail.as_view(), name='empresa-detail'),

    # Obres
    #path('obres/', ObraList.as_view(), name='obra-list'),#Totes les obres
    path ('obresEmpresa/<int:pk>/', ObresListEmpresa.as_view(), name='obres-empresa-list'),#Obres d'una empresa
    path('obres/<int:pk>/', ObraDetail.as_view(), name='obra-detail'),

    # Treballadors
    path('treballadors/<int:pk>/', TreballadorDetail.as_view(), name='treballador-detail'),
    path('treballadors/profile/<int:pk>/', TreballadorProfileView.as_view(), name='treballador-profile'),
    path('treballadors/empresa/<int:pk>/', TreballadorEmpresaList.as_view(), name='treballadors-empresa-list'),
    # Vistes me (treballador autenticat accedeix a les seves propies dades)
    path('treballadors/me/tasques/', TreballadorMeTasquesView.as_view(), name='treballador-me-tasques'),
    path('treballadors/me/obres_participades/', TreballadorMeObresParticipadesView.as_view(), name='treballador-me-obres'),
    path('treballadors/me/registre_horari/', RegistreHorariMeView.as_view(), name='treballador-me-registre-horari'),
    path('treballadors/me/tasques/<int:tasca_id>/finalitzar/', TreballadorMeTascaFinalitzarView.as_view(), name='treballador-me-tasca-finalitzar'),

        # id:TascaTreballador
    path('tasca_treballador/', TascaTreballadorList.as_view(), name='tascatreballador-list'),
    path('tasca_treballador/<int:pk>/', TascaTreballadorDetail.as_view(), name='tascatreballador-detail'),
    
    path('contracte_treballador/<int:pk>/', ContracteTreballadorDetail.as_view(), name= 'contractetreballador-detail'),
    #TascaTreballadorBulkDeleteView: id de tasca
    path('tasca_treballador/<int:id_tasca>/bulk_delete/', TascaTreballadorBulkDelete.as_view(), name='tascatreballador-bulk-delete'),
    path('ubicacio/<int:pk>/', UbicacioDetail.as_view(), name='ubicacio-detail'),

    # Permisos
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
    #path('document_obra/upload/', DocumentObraUploadView.as_view(), name='documentobra-upload'),


    # Sol·licituds de recursos
    path('sol_recurs/', SolRecursList.as_view(), name='solrecurs-list'),
    path('sol_recurs/<int:pk>/', SolRecursDetail.as_view(), name='solrecurs-detail'),

    # Responsable d’obra (N-a-N; només llista/filtre)
    path('responsable_obra/', ResponsableObraList.as_view(), name='responsableobra-list'),

]
