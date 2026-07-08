# back_end/apiApp/signals.py

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from .authentication.helpers import (
    crear_notificacio_empresa, crear_notificacio_treballador,
    empreses_obra, responsables_obra, treballadors_assignats_tasca,
)

from .models import Tasca, TascaTreballador, SolRecurs, Incidencia, ObraEmpresa, ResponsableObra, DocumentObra


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