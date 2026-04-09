from datetime import date

from rest_framework.exceptions import PermissionDenied

from ..models import (
    Empresa,
    ContracteTreballador,
    ObraEmpresa,
    SolRecurs,
)
# ───────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────
def _is_contracte_vigent(c):
    """
    Consideram 'vigent' si:
      - estat == 'actiu'
      - i (data_fi és None o >= avui)
    """
    if c is None:
        return False
    avui = date.today()
    return (c.estat == 'actiu') and (c.data_fi is None or c.data_fi >= avui)



def _get_auth_context(request):
    return request.auth["tipus"], int(request.auth["subject_id"])


def _assert_empresa_subject(request):
    subject_type, subject_id = _get_auth_context(request)
    if subject_type != "empresa":
        raise PermissionDenied("Només les empreses poden fer aquesta acció.")
    return subject_id


def _empresa_te_acces_a_obra(empresa_id, obra_id):
    print(f"Comprovant _empresa_te_acces_a_obra accés de empresa {empresa_id} a obra {obra_id}...")
    aux = ObraEmpresa.objects.filter(
        id_empresa=empresa_id,
        id_obra=obra_id
    ).exists()

    print (f"Resultat de _empresa_te_acces_a_obra: {aux}")
    
    return aux


def _empresa_te_acces_a_treballador(empresa_id, treballador_id):
    contracte = (
        ContracteTreballador.objects
        .filter(id_empresa_id=empresa_id, id_treballador_id=treballador_id)
        .order_by("-data_contracte")
        .first()
    )
    return _is_contracte_vigent(contracte)


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

    from ..models import ContracteTreballador, ObraEmpresa, Tasca, Incidencia, DocumentObra, SolRecurs


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



def _empresa_accessible_obra_ids(empresa_id):
    return ObraEmpresa.objects.filter(
        id_empresa_id=empresa_id
    ).values_list('id_obra_id', flat=True)


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