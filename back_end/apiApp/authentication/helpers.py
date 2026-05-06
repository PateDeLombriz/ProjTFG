from datetime import date

from rest_framework.exceptions import PermissionDenied

from ..models import (
    Empresa,
    ContracteTreballador,
    ObraEmpresa,
    PermisTreballador,
    ResponsableObra,
    SolRecurs,
    TascaTreballador,
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