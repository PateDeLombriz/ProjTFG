from datetime import date

from rest_framework.exceptions import PermissionDenied

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from ..models import (
    Empresa, ContracteTreballador,Notificacio, ObraEmpresa, PermisTreballador, ResponsableObra,
    SolRecurs,Tasca,TascaTreballador,Incidencia,DocumentObra, ObraEmpresa, Treballador
)
# ───────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────
def _is_contracte_vigent(c):
    """
    Consideram 'vigent' si:
      - estat != 'actiu'
      - i (data_fi és None o >= avui)
    """
    if c is None:
        return False
    avui = date.today()
    return (c.estat == 'actiu') and (c.data_fi is None or c.data_fi >= avui)



def _get_auth_context(request):
    return request.auth["tipus"], int(request.auth["subject_id"])

# ───────────────────────────────────────────────
# Helpers genèrics per subjecte: empresa / treballador
# ───────────────────────────────────────────────

def _treballador_te_acces_a_obra(treballador_id, obra_id):
    """
    Un treballador té accés a una obra si:
      - té qualque tasca assignada dins aquella obra
      - o és responsable d'aquella obra

    Aquesta regla és la base perquè els treballadors puguin veure
    documents de les obres on participen.
    """
    obra_id = int(obra_id)
    treballador_id = int(treballador_id)

    te_tasca_assignada = TascaTreballador.objects.filter(
        id_treballador_id=treballador_id,
        id_tasca__id_obra_id=obra_id,
    ).exists()

    if te_tasca_assignada:
        return True

    es_responsable = ResponsableObra.objects.filter(
        id_treballador_id=treballador_id,
        id_obra_id=obra_id,
    ).exists()

    return es_responsable


def _treballador_accessible_obra_ids(treballador_id):
    """
    Retorna ids d'obres accessibles per un treballador.

    Fonts d'accés:
      - tasques assignades
      - responsable_obra
    """
    treballador_id = int(treballador_id)

    obra_ids_tasques = TascaTreballador.objects.filter(
        id_treballador_id=treballador_id,
    ).values_list(
        'id_tasca__id_obra_id',
        flat=True,
    )

    obra_ids_responsable = ResponsableObra.objects.filter(
        id_treballador_id=treballador_id,
    ).values_list(
        'id_obra_id',
        flat=True,
    )

    return list(set(list(obra_ids_tasques) + list(obra_ids_responsable)))

def _assert_subject_can_access_tasca(request, tasca):
    """
    Valida que el subjecte autenticat pugui accedir a la tasca.
    Funciona tant per empresa com per treballador.
    """
    subject_type, subject_id = _get_auth_context(request)

    if subject_type == "empresa":
        return _assert_empresa_can_access_tasca(request, tasca)

    if subject_type == "treballador":
        return _assert_treballador_can_access_tasca(request, tasca)

    raise PermissionDenied("Tipus de subjecte no autoritzat.")


def _assert_treballador_can_access_tasca(request, tasca):
    subject_type, subject_id = _get_auth_context(request)

    if subject_type != "treballador":
        raise PermissionDenied("Només els treballadors poden accedir a aquesta tasca.")

    if not _treballador_te_acces_a_obra(subject_id, tasca.id_obra_id):
        raise PermissionDenied("No pots accedir a una tasca d'una obra on no participes.")

    return subject_id


def _subject_te_acces_a_obra(subject_type, subject_id, obra_id):
    """
    Comprova accés a obra per qualsevol subjecte autenticat.
    """
    if subject_type == "empresa":
        return _empresa_te_acces_a_obra(subject_id, obra_id)

    if subject_type == "treballador":
        return _treballador_te_acces_a_obra(subject_id, obra_id)

    return False


def _assert_subject_can_access_obra(request, obra_id):
    """
    Valida que el subjecte autenticat pugui accedir a l'obra.
    Funciona tant per empresa com per treballador.
    """
    subject_type, subject_id = _get_auth_context(request)

    if not _subject_te_acces_a_obra(subject_type, subject_id, int(obra_id)):
        raise PermissionDenied("No pots accedir a aquesta obra.")

    return subject_type, subject_id


def _subject_accessible_obra_ids(request):
    """
    Retorna les obres accessibles segons el subjecte autenticat.
    """
    subject_type, subject_id = _get_auth_context(request)

    if subject_type == "empresa":
        return list(_empresa_accessible_obra_ids(subject_id))

    if subject_type == "treballador":
        return _treballador_accessible_obra_ids(subject_id)

    return []


def _assert_query_obra_in_subject_context(request, obra_id):
    """
    Versió genèrica de _assert_query_obra_in_context.
    No assumeix que el subjecte sigui empresa.
    """
    return _assert_subject_can_access_obra(request, int(obra_id))


def _assert_subject_can_access_document_obra(request, doc):
    """
    Valida accés al document a partir de l'obra associada.
    """
    return _assert_subject_can_access_obra(request, doc.id_obra_id)


def _assert_subject_can_modify_document_obra(request, doc):
    """
    Regla recomanada:
      - Empresa: pot modificar documents de les seves obres.
      - Treballador: només pot modificar documents creats per ell.
    """
    subject_type, subject_id = _get_auth_context(request)

    _assert_subject_can_access_document_obra(request, doc)

    if subject_type == "empresa":
        return subject_id

    if subject_type == "treballador" and int(doc.id_creador) == int(subject_id):
        return subject_id

    raise PermissionDenied("No pots modificar aquest document.")


def _check_treballador_permis(treballador_id, clau_funcional):
    """
    Valida que el treballador tingui escriptura=True per a clau_funcional.

    Fallback: si el treballador no té cap PermisTreballador configurat
    (taula buida per a ell), es concedeix l'accés per mantenir paritat
    amb AppCapabilities.workerDefaults() al frontend.

    Llança PermissionDenied si el permís existeix però escriptura=False.
    """
    te_algun_permis = PermisTreballador.objects.filter(
        id_treballador_id=treballador_id
    ).exists()

    if not te_algun_permis:
        return  # Fallback: sense configuració → accés concedit (workerDefaults)

    te_permis_escriptura = PermisTreballador.objects.filter(
        id_treballador_id=treballador_id,
        id_permis__clau_funcional=clau_funcional,
        escriptura=True,
    ).exists()

    if not te_permis_escriptura:
        raise PermissionDenied(
            f"No tens permís per a l'acció '{clau_funcional}'."
        )

def _assert_empresa_subject(request):
    subject_type, subject_id = _get_auth_context(request)
    if subject_type != "empresa":
        raise PermissionDenied("Només les empreses poden fer aquesta acció.")
    return subject_id


def _empresa_te_acces_a_obra(empresa_id, obra_id):
    return ObraEmpresa.objects.filter(
        id_empresa=empresa_id,
        id_obra=obra_id
    ).exists()


def _empresa_te_acces_a_treballador(empresa_id, treballador_id):
    contracte = (
        ContracteTreballador.objects
        .filter(id_empresa_id=empresa_id, id_treballador_id=treballador_id)
        .order_by("-data_contracte")
        .first()
    )
    if contracte is None:
        return False
    return True


def _assert_empresa_can_access_obra(request, obra_id):
    empresa_id = _assert_empresa_subject(request)
    
    if not _empresa_te_acces_a_obra(empresa_id, obra_id):
        raise PermissionDenied("No pots accedir a una obra d'una altra empresa.")
    
    return empresa_id

def _assert_can_access_treballador_profile(request, treballador_id):
    subject_type = request.auth["tipus"]
    subject_id = int(request.auth["subject_id"])

    if subject_type == "treballador":
        if subject_id != int(treballador_id):
            raise PermissionDenied("No pots accedir al perfil d'un altre treballador.")
        return subject_id

    if subject_type == "empresa":
        return _assert_empresa_can_access_treballador(request, treballador_id)

    raise PermissionDenied("Tipus de subjecte no autoritzat.")

def _assert_empresa_can_access_treballador(request, treballador_id):
    empresa_id = _assert_empresa_subject(request)
    if not _empresa_te_acces_a_treballador(empresa_id, treballador_id):
        raise PermissionDenied("No pots accedir a un treballador fora del teu context.")
    return empresa_id


def _assert_can_access_contracte(request, contracte):
    subject_type, subject_id = _get_auth_context(request)

    if subject_type == "empresa":
        if contracte.id_empresa_id != subject_id:
            raise PermissionDenied("No pots accedir a contractes d'una altra empresa.")
        return subject_id

    if subject_type == "treballador":
        if contracte.id_treballador_id != subject_id:
            raise PermissionDenied("No pots accedir a contractes d'un altre treballador.")
        return subject_id

    raise PermissionDenied("Tipus de subjecte no autoritzat.")


def _assert_empresa_can_access_tasca(request, tasca):
    return _assert_empresa_can_access_obra(request, tasca.id_obra_id)


def _assert_empresa_can_access_incidencia(request, incidencia):
    return _assert_empresa_can_access_obra(request, incidencia.id_obra_id)


def _assert_empresa_can_access_document_obra(request, doc):
    return _assert_empresa_can_access_obra(request, doc.id_obra_id)


def _assert_empresa_can_access_sol_recurs(request, sol_recurs):
    return _assert_empresa_can_access_obra(request, sol_recurs.id_obra_id)

def _assert_empresa_can_access_empresa(request, empresa_id):
    empresa_auth_id = _assert_empresa_subject(request)
    if empresa_auth_id != empresa_id:
        raise PermissionDenied("No pots accedir a una altra empresa.")
    return empresa_auth_id


def _assert_empresa_can_access_permis_usuari(request, permis_obj):
    return _assert_empresa_can_access_treballador(request, permis_obj.id_treballador_id)


def _assert_empresa_can_access_tasca_treballador(request, assignacio):
    if not assignacio.id_tasca_id:
        raise PermissionDenied("Assignació sense tasca associada.")
    tasca = assignacio.id_tasca
    if tasca is None:
        raise PermissionDenied("Assignació amb tasca no resolta.")
    return _assert_empresa_can_access_obra(request, tasca.id_obra_id)



def _assert_empresa_can_access_recurs(request, recurs):
    empresa_id = _assert_empresa_subject(request)

    obra_ids = _empresa_accessible_obra_ids(empresa_id)

    te_acces = SolRecurs.objects.filter(
        id_recurs=recurs,
        id_obra_id__in=obra_ids
    ).exists()

    if not te_acces:
        raise PermissionDenied("No pots accedir a un recurs fora del teu context.")

    return empresa_id


def _assert_empresa_can_access_solucio(request, solucio):
    empresa_id = _assert_empresa_subject(request)

    obra_id = None

    if solucio.id_incidencia_id:
        obra_id = solucio.id_incidencia.id_obra_id
    elif solucio.id_tasca_id:
        obra_id = solucio.id_tasca.id_obra_id

    if obra_id is None:
        raise PermissionDenied("Solució sense context d'obra resoluble.")

    if not _empresa_te_acces_a_obra(empresa_id, obra_id):
        raise PermissionDenied("No pots accedir a una solució fora del teu context.")

    return empresa_id

#retorna una llista amb els ids de les obres a les que pot accedir una empresa, per a fer consultes del tipus "id_obra__in=..." i evitar errors de permisos a nivell de base de dades
def _empresa_accessible_obra_ids(empresa_id):
    return list(
        ObraEmpresa.objects.filter(
            id_empresa_id=empresa_id
        ).values_list('id_obra_id', flat=True)
    )


def _empresa_accessible_treballador_ids(empresa_id):
    contractes = (
        ContracteTreballador.objects
        .filter(id_empresa_id=empresa_id)
        .order_by('id_treballador_id', '-data_contracte')
    )

    vigents = []
    vistos = set()

    for c in contractes:
        tid = c.id_treballador_id
        if tid in vistos:
            continue
        vistos.add(tid)
        if _is_contracte_vigent(c):
            vigents.append(tid)

    return vigents


def _assert_query_obra_in_context(request, obra_id):
    return _assert_empresa_can_access_obra(request, int(obra_id))


def _assert_query_treballador_in_context(request, treballador_id):
    return _assert_empresa_can_access_treballador(request, int(treballador_id))

def _assert_empresa_can_access_configuracio(request, cfg):
    empresa_id = _assert_empresa_subject(request)

    if cfg.id_empresa_id is not None:
        if cfg.id_empresa_id != empresa_id:
            raise PermissionDenied("No pots accedir a la configuració d'una altra empresa.")
        return empresa_id

    if cfg.id_treballador_id is not None:
        return _assert_empresa_can_access_treballador(request, cfg.id_treballador_id)

    raise PermissionDenied("Configuració sense subjecte vàlid.")


def _assert_empresa_can_access_verificacio(request, verificacio):
    return _assert_empresa_can_access_empresa(request, verificacio.id_empresa_id)

def _assert_empresa_can_access_ubicacio(request, ubicacio):
    empresa_id = _assert_empresa_subject(request)

    te_acces_empresa = Empresa.objects.filter(
        id=empresa_id,
        ubicacio_id=ubicacio.id_ubicacio
    ).exists()

    te_acces_obra = ObraEmpresa.objects.filter(
        id_empresa_id=empresa_id,
        id_obra__ubicacio_id=ubicacio.id_ubicacio
    ).exists()

    if not (te_acces_empresa or te_acces_obra):
        raise PermissionDenied("No pots accedir a una ubicació fora del teu context.")

    return empresa_id


"""
-------------------------
HELPTERS DE NOTIFICACIONS
-------------------------
"""




# =============================================================================
# CONSTANTS
# =============================================================================

ESTAT_TASCA_PENDENT_REVISIO = 'finalitzada_pendent_revisio'
ESTAT_TASCA_FINALITZADA = 'finalitzada'
ESTAT_TASCA_EN_CURS = 'en_curs'
ESTAT_TASCA_CANCELADA = 'cancelada'

ESTAT_SOL_RECURS_APROVADA = 'aprovada'
ESTAT_SOL_RECURS_REBUTJADA = 'rebutjada'
ESTAT_SOL_RECURS_PENDENT_SORTIDA = 'pendent_sortida'

ESTATS_INCIDENCIA_TANCADA = {'tancada', 'resolta', 'finalitzada'}


# =============================================================================
# HELPERS LOCALS
# =============================================================================

def _get_attr(obj, attr, default=None):
    return getattr(obj, attr, default)


def _camp_canviat(anterior, actual, camp):
    return _get_attr(anterior, camp) != _get_attr(actual, camp)


def _descripcio_curta(obj, llargada=80):
    return (_get_attr(obj, 'descripcio', '') or '')[:llargada]


def _nom_obra(obra):
    return _get_attr(obra, 'nom', 'obra')


def _nom_recurs(sol_recurs):
    return _get_attr(_get_attr(sol_recurs, 'id_recurs', None), 'nom', 'recurs')


def _notificar_treballadors_unics(treballadors, tipus, titol, missatge, entitat_id=None, entitat_tipus=None):
    vistos = set()
    for treballador in treballadors:
        if not treballador:
            continue
        treballador_id = _get_attr(treballador, 'id', None)
        if treballador_id in vistos:
            continue
        vistos.add(treballador_id)
        crear_notificacio_treballador(treballador, tipus, titol, missatge, entitat_id, entitat_tipus)


def _notificar_empreses_uniques(empreses, tipus, titol, missatge, entitat_id=None, entitat_tipus=None):
    vistes = set()
    for empresa in empreses:
        if not empresa:
            continue
        empresa_id = _get_attr(empresa, 'id', None)
        if empresa_id in vistes:
            continue
        vistes.add(empresa_id)
        crear_notificacio_empresa(empresa, tipus, titol, missatge, entitat_id, entitat_tipus)


def _treballadors_implicats_obra(obra):
    treballadors, vistos = [], set()

    for responsable in responsables_obra(obra):
        treballador_id = _get_attr(responsable, 'id', None)
        if treballador_id and treballador_id not in vistos:
            vistos.add(treballador_id)
            treballadors.append(responsable)

    assignacions = TascaTreballador.objects.filter(id_tasca__id_obra=obra).select_related('id_treballador')
    for assignacio in assignacions:
        treballador = assignacio.id_treballador
        treballador_id = _get_attr(treballador, 'id', None)
        if treballador_id and treballador_id not in vistos:
            vistos.add(treballador_id)
            treballadors.append(treballador)

    return treballadors


def _destinataris_incidencia(incidencia):
    treballadors, vistos = [], set()
    tasca = _get_attr(incidencia, 'id_tasca', None)
    obra = _get_attr(incidencia, 'id_obra', None)

    if tasca:
        for treballador in treballadors_assignats_tasca(tasca):
            treballador_id = _get_attr(treballador, 'id', None)
            if treballador_id and treballador_id not in vistos:
                vistos.add(treballador_id)
                treballadors.append(treballador)

    if obra:
        for responsable in responsables_obra(obra):
            treballador_id = _get_attr(responsable, 'id', None)
            if treballador_id and treballador_id not in vistos:
                vistos.add(treballador_id)
                treballadors.append(responsable)

    return treballadors, empreses_obra(obra) if obra else []


# =============================================================================
# CAPTURA D'ESTAT ANTERIOR
# =============================================================================

@receiver(pre_save, sender=Tasca, dispatch_uid='capturar_tasca_anterior')
def capturar_tasca_anterior(sender, instance, **kwargs):
    if not instance.pk:
        instance._anterior = None
        instance._estat_anterior = None
        return

    try:
        anterior = Tasca.objects.get(pk=instance.pk)
        instance._anterior = anterior
        instance._estat_anterior = _get_attr(anterior, 'estat', None)
    except Tasca.DoesNotExist:
        instance._anterior = None
        instance._estat_anterior = None


@receiver(pre_save, sender=SolRecurs, dispatch_uid='capturar_sol_recurs_anterior')
def capturar_sol_recurs_anterior(sender, instance, **kwargs):
    if not instance.pk:
        instance._anterior = None
        instance._estat_anterior = None
        return

    try:
        anterior = SolRecurs.objects.get(pk=instance.pk)
        instance._anterior = anterior
        instance._estat_anterior = _get_attr(anterior, 'estat', None)
    except SolRecurs.DoesNotExist:
        instance._anterior = None
        instance._estat_anterior = None


@receiver(pre_save, sender=Incidencia, dispatch_uid='capturar_incidencia_anterior')
def capturar_incidencia_anterior(sender, instance, **kwargs):
    if not instance.pk:
        instance._anterior = None
        instance._estat_anterior = None
        return

    try:
        anterior = Incidencia.objects.get(pk=instance.pk)
        instance._anterior = anterior
        instance._estat_anterior = _get_attr(anterior, 'estat', None)
    except Incidencia.DoesNotExist:
        instance._anterior = None
        instance._estat_anterior = None


# =============================================================================
# TASQUES
# =============================================================================

@receiver(post_save, sender=TascaTreballador, dispatch_uid='notificar_nova_tasca_assignada')
def notificar_nova_tasca_assignada(sender, instance, created, **kwargs):
    if not created:
        return

    tasca = instance.id_tasca
    treballador = instance.id_treballador

    crear_notificacio_treballador(
        treballador, 'nova_tasca', 'Nova tasca assignada',
        f"T'han assignat: {_descripcio_curta(tasca)}", tasca.id, 'tasca',
    )


@receiver(post_save, sender=Tasca, dispatch_uid='notificar_tasca_actualitzada')
def notificar_tasca_actualitzada(sender, instance, created, **kwargs):
    if created:
        return

    anterior = _get_attr(instance, '_anterior', None)
    if not anterior:
        return

    estat_anterior = _get_attr(anterior, 'estat', None)
    estat_nou = _get_attr(instance, 'estat', None)

    canvi_especial = (
        (estat_anterior == ESTAT_TASCA_PENDENT_REVISIO and estat_nou == ESTAT_TASCA_FINALITZADA) or
        (estat_anterior == ESTAT_TASCA_PENDENT_REVISIO and estat_nou == ESTAT_TASCA_EN_CURS) or
        estat_nou == ESTAT_TASCA_CANCELADA or
        estat_nou == ESTAT_TASCA_PENDENT_REVISIO
    )

    if canvi_especial:
        return

    camps_canviats = any(_camp_canviat(anterior, instance, camp) for camp in ('descripcio', 'data_inici', 'data_fi', 'prioritat'))
    if not camps_canviats:
        return

    _notificar_treballadors_unics(
        treballadors_assignats_tasca(instance), 'tasca_actualitzada', 'Tasca actualitzada',
        f"S'ha actualitzat la tasca: {_descripcio_curta(instance)}", instance.id, 'tasca',
    )


@receiver(post_save, sender=Tasca, dispatch_uid='notificar_tasca_cancelada')
def notificar_tasca_cancelada(sender, instance, created, **kwargs):
    if created:
        return

    anterior = _get_attr(instance, '_anterior', None)
    if not anterior:
        return

    estat_anterior = _get_attr(anterior, 'estat', None)
    estat_nou = _get_attr(instance, 'estat', None)

    if estat_anterior == ESTAT_TASCA_CANCELADA or estat_nou != ESTAT_TASCA_CANCELADA:
        return

    _notificar_treballadors_unics(
        treballadors_assignats_tasca(instance), 'tasca_cancelada', 'Tasca cancel·lada',
        f"S'ha cancel·lat la tasca: {_descripcio_curta(instance)}", instance.id, 'tasca',
    )


@receiver(post_save, sender=Tasca, dispatch_uid='notificar_tasca_finalitzada')
def notificar_tasca_finalitzada(sender, instance, created, **kwargs):
    if created:
        return

    anterior = _get_attr(instance, '_anterior', None)
    if not anterior:
        return

    estat_anterior = _get_attr(anterior, 'estat', None)
    estat_nou = _get_attr(instance, 'estat', None)

    if estat_anterior == ESTAT_TASCA_PENDENT_REVISIO or estat_nou != ESTAT_TASCA_PENDENT_REVISIO:
        return

    obra = instance.id_obra

    _notificar_treballadors_unics(
        responsables_obra(obra), 'tasca_finalitzada', 'Tasca finalitzada pendent de revisió',
        f"Una tasca ha estat marcada com a finalitzada: {_descripcio_curta(instance)}", instance.id, 'tasca',
    )

    _notificar_empreses_uniques(
        empreses_obra(obra), 'tasca_finalitzada', 'Tasca finalitzada pendent de revisió',
        f"Una tasca de l'obra {_nom_obra(obra)} espera revisió.", instance.id, 'tasca',
    )


@receiver(post_save, sender=Tasca, dispatch_uid='notificar_tasca_validada_o_rebutjada')
def notificar_tasca_validada_o_rebutjada(sender, instance, created, **kwargs):
    if created:
        return

    estat_anterior = _get_attr(instance, '_estat_anterior', None)
    estat_nou = _get_attr(instance, 'estat', None)

    if estat_anterior != ESTAT_TASCA_PENDENT_REVISIO:
        return

    if estat_nou == ESTAT_TASCA_FINALITZADA:
        tipus = 'tasca_validada'
        titol = 'Tasca validada'
        missatge = f'La tasca "{_descripcio_curta(instance, 60)}" ha estat aprovada.'
    elif estat_nou == ESTAT_TASCA_EN_CURS:
        tipus = 'tasca_rebutjada'
        titol = 'Tasca retornada'
        missatge = f'La tasca "{_descripcio_curta(instance, 60)}" ha estat retornada. Revisa els comentaris.'
    else:
        return

    _notificar_treballadors_unics(treballadors_assignats_tasca(instance), tipus, titol, missatge, instance.id, 'tasca')


# =============================================================================
# SOL·LICITUDS DE RECURS
# =============================================================================

@receiver(post_save, sender=SolRecurs, dispatch_uid='notificar_sol_recurs_creada')
def notificar_sol_recurs_creada(sender, instance, created, **kwargs):
    if not created:
        return

    obra = instance.id_obra
    recurs_nom = _nom_recurs(instance)
    quantitat = _get_attr(instance, 'quantitat', '')

    _notificar_empreses_uniques(
        empreses_obra(obra), 'sol_recurs_creada', 'Nova sol·licitud de recurs',
        f"S'ha creat una sol·licitud de {quantitat} unitats de {recurs_nom}.", instance.id, 'sol_recurs',
    )

    _notificar_treballadors_unics(
        responsables_obra(obra), 'sol_recurs_creada', 'Nova sol·licitud de recurs',
        f"S'ha creat una sol·licitud de recurs a l'obra {_nom_obra(obra)}.", instance.id, 'sol_recurs',
    )


@receiver(post_save, sender=SolRecurs, dispatch_uid='notificar_sol_recurs_assignada')
def notificar_sol_recurs_assignada(sender, instance, created, **kwargs):
    if created:
        return

    anterior = _get_attr(instance, '_anterior', None)
    if not anterior:
        return

    treballador_anterior_id = _get_attr(anterior, 'id_treballador_id', None)
    treballador_nou_id = _get_attr(instance, 'id_treballador_id', None)

    if not treballador_nou_id or treballador_anterior_id == treballador_nou_id:
        return

    crear_notificacio_treballador(
        instance.id_treballador, 'sol_recurs_assignada', 'Sol·licitud de recurs assignada',
        f"T'han assignat la gestió del recurs {_nom_recurs(instance)}.", instance.id, 'sol_recurs',
    )


@receiver(post_save, sender=SolRecurs, dispatch_uid='notificar_canvi_estat_sol_recurs')
def notificar_canvi_estat_sol_recurs(sender, instance, created, **kwargs):
    if created:
        return

    estat_anterior = _get_attr(instance, '_estat_anterior', None)
    estat_nou = _get_attr(instance, 'estat', None)

    if estat_anterior == estat_nou:
        return

    recurs_nom = _nom_recurs(instance)

    if estat_nou == ESTAT_SOL_RECURS_APROVADA:
        treballador = _get_attr(instance, 'id_treballador', None)
        if treballador:
            crear_notificacio_treballador(treballador, 'sol_recurs_aprovada', 'Sol·licitud aprovada', f'La teva sol·licitud de recurs ({recurs_nom}) ha estat aprovada.', instance.id, 'sol_recurs')
        return

    if estat_nou == ESTAT_SOL_RECURS_REBUTJADA:
        treballador = _get_attr(instance, 'id_treballador', None)
        if treballador:
            crear_notificacio_treballador(treballador, 'sol_recurs_rebutjada', 'Sol·licitud rebutjada', f'La teva sol·licitud de recurs ({recurs_nom}) ha estat rebutjada.', instance.id, 'sol_recurs')
        return

    if estat_nou == ESTAT_SOL_RECURS_PENDENT_SORTIDA:
        obra = instance.id_obra
        missatge = f'Hi ha una sortida pendent del recurs {recurs_nom} a l’obra {_nom_obra(obra)}.'

        _notificar_empreses_uniques(empreses_obra(obra), 'sortida_pendent', 'Sortida pendent', missatge, instance.id, 'sol_recurs')
        _notificar_treballadors_unics(responsables_obra(obra), 'sortida_pendent', 'Sortida pendent', missatge, instance.id, 'sol_recurs')


# =============================================================================
# INCIDÈNCIES
# =============================================================================

@receiver(post_save, sender=Incidencia, dispatch_uid='notificar_nova_incidencia')
def notificar_nova_incidencia(sender, instance, created, **kwargs):
    if not created:
        return

    treballadors, empreses = _destinataris_incidencia(instance)
    obra = instance.id_obra
    missatge = f"S'ha registrat una incidència a l'obra {_nom_obra(obra)}: {_descripcio_curta(instance)}"

    _notificar_treballadors_unics(treballadors, 'nova_incidencia', 'Nova incidència', missatge, instance.id, 'incidencia')
    _notificar_empreses_uniques(empreses, 'nova_incidencia', 'Nova incidència', missatge, instance.id, 'incidencia')


@receiver(post_save, sender=Incidencia, dispatch_uid='notificar_incidencia_actualitzada_o_tancada')
def notificar_incidencia_actualitzada_o_tancada(sender, instance, created, **kwargs):
    if created:
        return

    anterior = _get_attr(instance, '_anterior', None)
    if not anterior:
        return

    estat_anterior = _get_attr(anterior, 'estat', None)
    estat_nou = _get_attr(instance, 'estat', None)
    es_tancament = estat_anterior != estat_nou and estat_nou in ESTATS_INCIDENCIA_TANCADA

    if es_tancament:
        tipus, titol, missatge = 'incidencia_tancada', 'Incidència tancada', f"S'ha tancat la incidència: {_descripcio_curta(instance)}"
    else:
        camps_canviats = any(_camp_canviat(anterior, instance, camp) for camp in ('descripcio', 'criticitat', 'prioritat', 'categoria', 'estat', 'id_tasca_id'))
        if not camps_canviats:
            return
        tipus, titol, missatge = 'incidencia_actualitzada', 'Incidència actualitzada', f"S'ha actualitzat la incidència: {_descripcio_curta(instance)}"

    treballadors, empreses = _destinataris_incidencia(instance)
    _notificar_treballadors_unics(treballadors, tipus, titol, missatge, instance.id, 'incidencia')
    _notificar_empreses_uniques(empreses, tipus, titol, missatge, instance.id, 'incidencia')


# =============================================================================
# OBRES
# =============================================================================

@receiver(post_save, sender=ObraEmpresa, dispatch_uid='notificar_nova_obra_assignada')
def notificar_nova_obra_assignada(sender, instance, created, **kwargs):
    if not created:
        return

    obra = instance.id_obra
    empresa = instance.id_empresa

    crear_notificacio_empresa(
        empresa, 'nova_obra_assignada', 'Nova obra assignada',
        f"S'ha assignat l'obra {_nom_obra(obra)} a la teva empresa.", obra.id, 'obra',
    )


@receiver(post_save, sender=ResponsableObra, dispatch_uid='notificar_responsable_obra_assignat')
def notificar_responsable_obra_assignat(sender, instance, created, **kwargs):
    if not created:
        return

    obra = instance.id_obra
    treballador = instance.id_treballador

    crear_notificacio_treballador(
        treballador, 'responsable_obra_assignat', 'Responsable d’obra assignat',
        f"Has estat assignat com a responsable de l'obra {_nom_obra(obra)}.", obra.id, 'obra',
    )


# =============================================================================
# DOCUMENTS
# =============================================================================

@receiver(post_save, sender=DocumentObra, dispatch_uid='notificar_document_pujat')
def notificar_document_pujat(sender, instance, created, **kwargs):
    if not created:
        return

    obra = instance.id_obra
    missatge = f"S'ha pujat un document nou a l'obra {_nom_obra(obra)}."

    _notificar_treballadors_unics(_treballadors_implicats_obra(obra), 'document_pujat', 'Document nou', missatge, instance.id, 'document_obra')
    _notificar_empreses_uniques(empreses_obra(obra), 'document_pujat', 'Document nou', missatge, instance.id, 'document_obra')



def crear_notificacio_treballador(treballador, tipus, titol, missatge, entitat_id=None, entitat_tipus=None):
    if not treballador:
        return None

    return Notificacio.objects.create(
        id_treballador=treballador,
        tipus=tipus,
        titol=titol,
        missatge=missatge,
        entitat_id=entitat_id,
        entitat_tipus=entitat_tipus,
    )


def crear_notificacio_empresa(empresa, tipus, titol, missatge, entitat_id=None, entitat_tipus=None):
    if not empresa:
        return None

    return Notificacio.objects.create(
        id_empresa=empresa,
        tipus=tipus,
        titol=titol,
        missatge=missatge,
        entitat_id=entitat_id,
        entitat_tipus=entitat_tipus,
    )


def empreses_obra(obra):
    if not obra:
        return []

    return [
        rel.id_empresa
        for rel in ObraEmpresa.objects
            .filter(id_obra=obra)
            .select_related('id_empresa')
    ]


def responsables_obra(obra):
    if not obra:
        return []

    return [
        rel.id_treballador
        for rel in ResponsableObra.objects
            .filter(id_obra=obra, data_fi__isnull=True)
            .select_related('id_treballador')
    ]


def treballadors_assignats_tasca(tasca):
    if not tasca:
        return []

    return [
        rel.id_treballador
        for rel in TascaTreballador.objects
            .filter(id_tasca=tasca)
            .select_related('id_treballador')
    ]


