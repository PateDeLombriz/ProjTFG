from datetime import datetime
from rest_framework.views import APIView
from rest_framework.permissions import IsAdminUser
from rest_framework import status
from django.db.models import Q
import jwt
from django.contrib.auth.hashers import check_password, make_password
from django.utils import timezone
from datetime import datetime, timedelta,date
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import permissions
from rest_framework.exceptions import PermissionDenied
from .authentication import JWTSubjectAuthentication
from .models import (Obra,Empresa, ObraEmpresa,Treballador, ContracteTreballador,Ubicacio, Contrasenya, Permis, PermisTreballador,
    LogDeSessio, Configuracio, Verificacio, DocumentObra, Tasca, TascaTreballador,
    Incidencia, Solucio, Recurs, SolRecurs, ResponsableObra, LogDeSessio)
from .serializer import (
    ObraEmpresaSerializer, ObraSerializer, TreballadorSerializer, EmpresaSerializer,
    ContracteTreballadorSerializer, ContrasenyaSerializer,
    PermisSerializer, PermisTreballadorSerializer, LogDeSessioSerializer, UbicacioSerializer,
    ConfiguracioSerializer, VerificacioSerializer, DocumentObraSerializer,
    TascaSerializer, TascaTreballadorSerializer, IncidenciaSerializer, SolucioSerializer,
    RecursSerializer, SolRecursSerializer, ResponsableObraSerializer
)
from django.http import Http404
from django.conf import settings
from django.shortcuts import get_object_or_404

def generar_token_jwt(subject_id: int, subject_type: str, expires_hours: int = 24) -> str:
    """
    Retorna un JWT HS256 que encoda:
      sub   -> subject_id
      tipus -> 'empresa' o 'treballador'
      exp   -> ara + expires_hours
    """
    now = timezone.now()
    payload = {
        "sub":   str(subject_id),  # ID del subjecte (empresa o treballador)
        "tipus": subject_type,  # 'empresa' | 'treballador'
        "iat":   int(now.timestamp()),
        "exp":   int((now + timedelta(hours=expires_hours)).timestamp()),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


#*********************************NOMES PER DESENVOLUPAMENT**********************
#Aquests 2 m`todes son per verificar que les contrasenyes inserides de sde el isnertData.sql
#Siguinn compatibles amb Django i no donin error a l'hora de fer login
#********************************************************************************
def _is_django_hash(value: str) -> bool:
    # Format típic: 'algorithm$iterations$salt$hash' (3 o més signes $)
    return isinstance(value, str) and value.count('$') >= 3

def _check_legacy_or_hash(entered_plain: str, stored_value: str):
    """
    Retorna (ok, new_hash_or_None).
    - Si stored_value és hash Django → valida amb check_password.
    - Si és plaintext → compara literal i, si coincideix, retorna un hash per substituir.
    """
    if _is_django_hash(stored_value):
        return check_password(entered_plain, stored_value), None
    # mode compat: plaintext a BD
    if entered_plain == stored_value:
        return True, make_password(entered_plain)  # PBKDF2-SHA256 per defecte
    return False, None

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



#Empresa amb filtres:

class EmpresaList(APIView):
    """
    GET: llista d'empreses amb filtres opcionals (?estat=activa&sector=...&q=...)
    POST: crea empresa (via serializer)
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = Empresa.objects.select_related('ubicacio').all()

        estat = request.query_params.get('estat')
        sector = request.query_params.get('sector')
        q = request.query_params.get('q')  # cerca per nom, CIF, email

        if estat:
            qs = qs.filter(estat=estat)
        if sector:
            qs = qs.filter(sector=sector)
        if q:
            qs = qs.filter(
                Q(nom_empresa__icontains=q) |
                Q(cif__icontains=q) |
                Q(email__icontains=q)
            )

        serializer = EmpresaSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = EmpresaSerializer(data=request.data)
        if serializer.is_valid():
            empresa = serializer.save()
            out = EmpresaSerializer(empresa).data
            return Response(out, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




class EmpresaDetail(APIView):
    """
    Retorna informació completa d'una empresa:
      - dades bàsiques
      - ubicació
      - treballadors contractats
      - obres relacionades
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk, format=None):
        empresa = get_object_or_404(Empresa, pk=pk)

        empresa_data = {
            'id': empresa.id,
            'nom_empresa': empresa.nom_empresa,
            'cif': empresa.cif,
            'telefon': empresa.telefon,
            'email': empresa.email,
            'web': empresa.web,
            'sector': empresa.sector,
            'estat': empresa.estat,
            'persona_contacte': empresa.persona_contacte,
            'comentaris': empresa.comentaris,
            'data_alta': empresa.data_alta,
        }

        # Ubicació
        if empresa.ubicacio:
            empresa_data['ubicacio'] = {
                'adreça': empresa.ubicacio.adreça,
                'ciutat': empresa.ubicacio.ciutat,
                'codi_postal': empresa.ubicacio.codi_postal,
                'provincia': empresa.ubicacio.provincia,
                'país': empresa.ubicacio.país,
            }
        else:
            empresa_data['ubicacio'] = None

        # Contractes de treballadors
        contractes = ContracteTreballador.objects.filter(id_empresa=empresa)
        empresa_data['treballadors'] = [
            {
                'id_treballador': c.id_treballador.id,
                'nom': c.id_treballador.nom,
                'cognoms': c.id_treballador.cognoms,
                'estat': c.estat,
                'carrec': c.carrec,
                'data_contracte': c.data_contracte,
                'data_fi': c.data_fi,
                'salari': c.salari,
            }
            for c in contractes
        ]

        return Response(empresa_data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        empresa = get_object_or_404(Empresa, pk=pk)
        serializer = EmpresaSerializer(empresa, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        empresa = get_object_or_404(Empresa, pk=pk)
        empresa.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ───────────────────────────────────────────────
# TREBALLADOR
# ───────────────────────────────────────────────
class TreballadorList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        treballadors = Treballador.objects.all()
        serializer = TreballadorSerializer(treballadors, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = TreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TreballadorDetail(APIView):
    """
    Retorna informació completa d'un treballador:
      - dades bàsiques
      - ubicació
      - contractes i empreses
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        # Aquesta vista només la poden usar empreses.
        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden consultar aquestes obres.")

        # Una empresa només pot consultar les seves pròpies obres.
        if subject_id != pk:
            raise PermissionDenied("No pots consultar les obres d'una altra empresa.")

        treballador = get_object_or_404(Treballador, pk=pk)

        treballador_data = {
            'id': treballador.id,
            'nom': treballador.nom,
            'nickname': treballador.nickname,
            'cognoms': treballador.cognoms,
            'dni_nie_passaport': treballador.dni_nie_passaport,
            'telefon': treballador.telefon,
            'email': treballador.email,
            'data_naixement': treballador.data_naixement,
            'comentaris': treballador.comentaris,
        }



        # Contractes
        contractes = ContracteTreballador.objects.filter(id_treballador=treballador)
        treballador_data['contractes'] = [
            {
                'empresa': c.id_empresa.nom_empresa if c.id_empresa else None,
                'estat': c.estat,
                'carrec': c.carrec,
                'data_contracte': c.data_contracte,
                'data_fi': c.data_fi,
                'salari': c.salari,
            }
            for c in contractes
        ]

        return Response(treballador_data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        treballador = get_object_or_404(Treballador, pk=pk)
        serializer = TreballadorSerializer(treballador, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        treballador = get_object_or_404(Treballador, pk=pk)
        treballador.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ───────────────────────────────────────────────
# UBICACIÓ
# ───────────────────────────────────────────────
class UbicacioList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        ubicacions = Ubicacio.objects.all()
        serializer = UbicacioSerializer(ubicacions, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = UbicacioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UbicacioDetail(APIView):

    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        serializer = UbicacioSerializer(ubicacio)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        serializer = UbicacioSerializer(ubicacio, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        ubicacio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ContracteTreballadorList(APIView):
    """
    Endpoint per gestionar la llista de contractes.
    - GET: permet obtenir contractes amb filtres opcionals
    - POST: permet crear nous contractes
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        # Obtenim tots els contractes de la base de dades
        qs = ContracteTreballador.objects.all()

        # ───── Lectura de paràmetres de filtratge ─────
        id_treballador = request.query_params.get('id_treballador')
        empresa_id     = request.query_params.get('empresa')
        estat          = request.query_params.get('estat')        # actiu/baixa/acomiadat
        actiu          = request.query_params.get('actiu')        # '1' → data_fi és NULL
        vigent_en      = request.query_params.get('vigent_en')    # data en format YYYY-MM-DD

        # ───── Aplicació dels filtres ─────
        if id_treballador:
            qs = qs.filter(id_treballador_id=id_treballador)  # Filtra per ID de treballador
        if empresa_id:
            qs = qs.filter(id_empresa_id=empresa_id)              # Filtra per empresaid_empresa_id es el valor numeric
        if estat:
            qs = qs.filter(estat=estat)                        # Filtra per estat del contracte
        if actiu == '1':
            qs = qs.filter(data_fi__isnull=True)                # Només contractes sense data de finalització
        if vigent_en:
            try:
                # Convertim la data de text a objecte date
                data_ref = datetime.fromisoformat(vigent_en).date()
                # Contractes amb data d'inici ≤ data_ref i sense data final o amb data final ≥ data_ref
                qs = qs.filter(
                    data_contracte__lte=data_ref
                ).filter(
                    Q(data_fi__isnull=True) | Q(data_fi__gte=data_ref)
                )
            except ValueError:
                pass  # Si el format és incorrecte, ignorem aquest filtre

        # Serialitzem els resultats i els retornem en format JSON
        serializer = ContracteTreballadorSerializer(qs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request, format=None):
        """
        Crea un nou contracte.
        - Comprova que el serializer és vàlid
        - Si viola unique_together, es captura l'excepció
        """
        serializer = ContracteTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            try:
                instance = serializer.save()  # Desa el contracte a la BBDD
                return Response(ContracteTreballadorSerializer(instance).data, status=status.HTTP_201_CREATED)
            except Exception as e:
                # Error com violació de unique_together
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ContracteTreballadorDetail(APIView):
    """
    Endpoint per gestionar un contracte concret.
    - GET: obté un contracte i informació extra
    - PUT: reemplaça totes les dades del contracte
    - PATCH: actualitza parcialment
    - DELETE: elimina el contracte
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self, pk):
        # Recupera el contracte o retorna 404 si no existeix
        return get_object_or_404(ContracteTreballador, pk=pk)

    def get(self, request, pk, format=None):
        obj = self.get_object(pk)  # Obtenim el contracte
        data = ContracteTreballadorSerializer(obj).data

        # ───── Afegim camp calculat "vigent_avui" ─────
        avui = timezone.now().date()
        data['vigent_avui'] = (obj.data_contracte is None or obj.data_contracte <= avui) and \
                              (obj.data_fi is None or obj.data_fi >= avui)

        # ───── Afegim informació bàsica de relacions ─────
        if obj.id_treballador_id:
            data['treballador'] = {'id': obj.id_treballador_id}
        if obj.id_empresa_id:
            data['empresa_info'] = {'id': obj.id_empresa_id}

        return Response(data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        """
        Reemplaça totes les dades del contracte amb les noves
        """
        obj = self.get_object(pk)
        serializer = ContracteTreballadorSerializer(obj, data=request.data, partial=False)
        if serializer.is_valid():
            try:
                instance = serializer.save()
                return Response(ContracteTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        """
        Actualitza parcialment un contracte (només camps enviats)
        """
        obj = self.get_object(pk)
        serializer = ContracteTreballadorSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            try:
                instance = serializer.save()
                return Response(ContracteTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        """
        Elimina un contracte concret
        """
        obj = self.get_object(pk)
        obj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TreballadorContracteVigentView(APIView):
    """
    Endpoint específic per obtenir el contracte vigent d'un treballador avui.
    GET /api/treballadors/<id_treballador>/contracte_vigent/
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, id_treballador, format=None):
        avui = timezone.now().date()
        # Filtra contractes que comencen abans o igual a avui i que no han acabat
        obj = (
            ContracteTreballador.objects
            .filter(id_treballador_id=id_treballador, data_contracte__lte=avui)
            .filter(Q(data_fi__isnull=True) | Q(data_fi__gte=avui))
            .order_by('-data_contracte')  # El més recent primer
            .first()
        )
        if not obj:
            # Si no hi ha contracte vigent, retornem 404
            return Response({'detail': 'Sense contracte vigent'}, status=status.HTTP_404_NOT_FOUND)
        return Response(ContracteTreballadorSerializer(obj).data, status=status.HTTP_200_OK)



#Gestiona llistes d'objectes del model d'Obres en aquest cas
class ObraList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        obres = Obra.objects.all()
        obra_data = ObraSerializer(obres, many=True)
        if(obra_data.ubicacio != None):
                obra_data['ubicacio_info'] = {
                'id_ubicacio': obra_data.ubicacio.id_ubicacio,
                'adreca': obra_data.ubicacio.adreca,
                'ciutat': obra_data.ubicacio.ciutat,
                'codi_postal': obra_data.ubicacio.codi_postal,
                'latitud': obra_data.ubicacio.latitud,
                'longitud': obra_data.ubicacio.longitud,
            }
                
        responsable = ResponsableObra.objects.filter(id_obra=obra_data.id_obra)
        if(responsable.exists()):
            obra_data['responsable'] = ResponsableObraSerializer(responsable, many=True).data

        return Response(obra_data)
    
    def post(self, request, format=None):
        serializer = ObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ObresListEmpresa(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        # Recuperam del JWT quin subjecte està autenticat.
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        # Aquesta vista només la poden usar empreses.
        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden consultar aquestes obres.")

        # Una empresa només pot consultar les seves pròpies obres.
        if subject_id != pk:
            raise PermissionDenied("No pots consultar les obres d'una altra empresa.")

        # Cercam les relacions empresa-obra d'aquesta empresa.
        # select_related evita consultes extra en accedir a id_obra i ubicacio.
        obres = ObraEmpresa.objects.filter(id_empresa=pk).select_related(
            "id_obra",
            "id_obra__ubicacio",
        )

        # Serialitzam la relació base ObraEmpresa.
        serializer = ObraEmpresaSerializer(obres, many=True)
        data = serializer.data

        # Afegim només la informació d'obra que vols retornar.
        for i, relacio in enumerate(obres):
            obra = relacio.id_obra

            if obra is None:
                data[i]["obra_info"] = None
                continue

            data[i]["obra_info"] = {
                "nom": obra.nom,
                "descripcio": obra.descripcio,
                "estat": obra.estat,
                "ubicacio": obra.ubicacio.adreca if obra.ubicacio else None,
            }

        return Response(data, status=status.HTTP_200_OK)

    def post(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden crear obres.")

        if subject_id != pk:
            raise PermissionDenied("No pots crear obres per una altra empresa.")

        serializer = ObraEmpresaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden eliminar obres.")

        if subject_id != pk:
            raise PermissionDenied("No pots eliminar obres d'una altra empresa.")

        obres = ObraEmpresa.objects.filter(id_empresa=pk)
        obres.delete()

        return Response(status=status.HTTP_204_NO_CONTENT)
    

    # Detall d'una obra amb totes les seves incidències, tasques i documents
class ObraDetail(APIView):
    """
    Vista detallada d'una obra concreta. Retorna:
    - Les dades bàsiques de l'obra
    - Les incidències relacionades
    - Les tasques relacionades
    - Els documents de l'obra
    - Les sol·licituds de recursos
    - El responsable d'obra (si n'hi ha)
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):

        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden crear obres.")

        if subject_id != pk:
            raise PermissionDenied("No pots crear obres per una altra empresa.")

        # Comprovar que l'obra existeix o retornar 404
        obra = get_object_or_404(Obra, pk=pk)

        # Serialitzar l'obra
        obra_data = ObraSerializer(obra).data

         # ───────────────────────────────────────────────
        # Afegir informació detallada de la ubicació
        # ───────────────────────────────────────────────
        if obra.ubicacio != None:
            obra_data['ubicacio_info'] = {
                'id_ubicacio': obra.ubicacio.id_ubicacio,
                'adreca': obra.ubicacio.adreca,
                'ciutat': obra.ubicacio.ciutat,
                'codi_postal': obra.ubicacio.codi_postal,
                'provincia': obra.ubicacio.provincia,
                'pais': obra.ubicacio.pais,
                'latitud': obra.ubicacio.latitud,
                'longitud': obra.ubicacio.longitud,
            }
        else:
            obra_data['ubicacio_info'] = None

        # ───────────────────────────────────────────────
        # Llistar les incidències associades
        # ───────────────────────────────────────────────
        incidencies = Incidencia.objects.filter(id_obra=obra)
        obra_data['incidencies'] = IncidenciaSerializer(incidencies, many=True).data

        # ───────────────────────────────────────────────
        # Llistar les tasques associades
        # ───────────────────────────────────────────────
        tasques = Tasca.objects.filter(id_obra=obra)
        obra_data['tasques'] = TascaSerializer(tasques, many=True).data

        # ───────────────────────────────────────────────
        # Llistar documents relacionats amb l'obra
        # ───────────────────────────────────────────────
        documents = DocumentObra.objects.filter(id_obra=obra)
        obra_data['documents'] = DocumentObraSerializer(documents, many=True).data

        # ───────────────────────────────────────────────
        # Llistar sol·licituds de recurs fetes per a l’obra
        # ───────────────────────────────────────────────
        sol_recursos = SolRecurs.objects.filter(id_obra=obra)
        obra_data['sol_recursos'] = SolRecursSerializer(sol_recursos, many=True).data

        # ───────────────────────────────────────────────
        # Afegir el responsable d’obra (si n'hi ha)
        # ───────────────────────────────────────────────
        try:
            responsable = ResponsableObra.objects.filter(id_obra=obra)
            obra_data['responsable'] = ResponsableObraSerializer(responsable, many=True).data
        except ResponsableObra.DoesNotExist:
            obra_data['responsable'] = None

        return Response(obra_data, status=status.HTTP_200_OK)

    def delete(self, request, pk):
        obra = get_object_or_404(Obra, pk=pk)
        obra.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    def put(self, request, pk):
        obra = get_object_or_404(Obra, pk=pk)
        serializer = ObraSerializer(obra, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TasquesList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

# El metode_getObject obté una tasca específica per ID
    def getObject(self, pk):#Aixo he de mirar si va be i funciona correctament si se li passa un id
        try:
            return Tasca.objects.get(pk=pk)
        except Tasca.DoesNotExist:
            raise Http404
        
    # El metode get retorna totes les tasques
    def get(self, request, format=None):
        qs = Tasca.objects.all()
        id_obra = request.query_params.get('id_obra')
        if id_obra:
            qs = qs.filter(id_obra_id=id_obra)
        serializer = TascaSerializer(qs, many=True)
        return Response(serializer.data)   
    

    def post(self, request, format=None):
        serializer = TascaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self, request, format=None):
        tasques = Tasca.objects.all()
        tasques.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    #Es diferencia de post perquè post crea una nova tasca, mentre que put actualitza les existents.
    def put(self, request, format=None):
        tasques = Tasca.objects.all()
        serializer = TascaSerializer(tasques, data=request.data, many=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class RecursDetail(APIView):
    """
    API View que retorna tots els detalls d'un recurs concret, incloent:
    - Informació del recurs
    - Totes les sol·licituds associades (SolRecurs)
    - Informació bàsica de les obres implicades
    """
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk):
        # Busquem el recurs pel seu ID (primary key)
        recurs = get_object_or_404(Recurs, pk=pk)

        # Serialitzem el recurs principal
        recurs_data = RecursSerializer(recurs).data

        # ──────────────────────────────────────────────────────────────────────
        # RELACIÓ: Sol·licituds relacionades amb aquest recurs (SolRecurs)
        # ──────────────────────────────────────────────────────────────────────
        sol_entrades = SolRecurs.objects.filter(id_recurs=recurs)

        # Serialitzem totes les sol·licituds relacionades
        sol_entrades_data = SolRecursSerializer(sol_entrades, many=True).data

        # ──────────────────────────────────────────────────────────────────────
        # OBRIM L'OBRA ASSOCIADA per cada sol·licitud i l'afegim manualment
        # ──────────────────────────────────────────────────────────────────────
        for i, sol in enumerate(sol_entrades):
            if sol.id_obra:
                obra_data = ObraSerializer(sol.id_obra).data
                sol_entrades_data[i]['obra'] = obra_data

        # Afegim totes les sol·licituds al recurs final
        recurs_data['sollicituds'] = sol_entrades_data

        # Retornem tota la informació del recurs amb les relacions
        return Response(recurs_data, status=status.HTTP_200_OK)

class IncidenciaDetail(APIView):

    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk):
        incidencia = get_object_or_404(Incidencia, pk=pk)

        # Serialitzar la incidència principal
        incidencia_data = IncidenciaSerializer(incidencia).data

        # Afegir obra relacionada
        if incidencia.id_obra:
            obra_data = ObraSerializer(incidencia.id_obra).data
            incidencia_data['obra'] = obra_data

        # Afegir tasca associada
        if incidencia.id_tasca:
            tasca_data = TascaSerializer(incidencia.id_tasca).data
            incidencia_data['tasca'] = tasca_data

        # Afegir solucions relacionades
        solucions = Solucio.objects.filter(id_incidencia=incidencia)
        solucions_data = SolucioSerializer(solucions, many=True).data
        incidencia_data['solucions'] = solucions_data

        return Response(incidencia_data, status=status.HTTP_200_OK)


class TasquesDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk):
        tasca = get_object_or_404(Tasca, pk=pk)

        # Serialitzar la tasca principal
        tasca_data = TascaSerializer(tasca).data

        # Afegir obra relacionada
        if tasca.id_obra:
            obra_data = ObraSerializer(tasca.id_obra).data
            tasca_data['obra'] = obra_data

        # Afegir tasca pare
        if tasca.id_tasca_pare:
            tasca_pare_data = TascaSerializer(tasca.id_tasca_pare).data
            tasca_data['tasca_pare'] = tasca_pare_data

        # Afegir incidències associades
        incidencies = Incidencia.objects.filter(id_tasca=tasca)
        tasca_data['incidencies'] = IncidenciaSerializer(incidencies, many=True).data

        # Afegir solucions associades
        solucions = Solucio.objects.filter(id_tasca=tasca)
        tasca_data['solucions'] = SolucioSerializer(solucions, many=True).data

        # Afegir treballador assignat (si n'hi ha)
        try:
            tasca_treballador = TascaTreballador.objects.get(id_tasca=tasca)
            treballador_data = TreballadorSerializer(tasca_treballador.id_treballador).data
            tasca_data['treballador_assignat'] = {
                'usuari': treballador_data,
                'comentari': tasca_treballador.comentari
            }
        except TascaTreballador.DoesNotExist:
            tasca_data['treballador_assignat'] = None

        return Response(tasca_data, status=status.HTTP_200_OK)


class ContrasenyaList(APIView):
    permission_classes = [IsAdminUser]
    authentication_classes = [JWTSubjectAuthentication]
    #permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        contrasenyes = Contrasenya.objects.all()
        serializer = ContrasenyaSerializer(contrasenyes, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = ContrasenyaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PermisList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        permisos = Permis.objects.all()
        serializer = PermisSerializer(permisos, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = PermisSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




# ─────────────────────────────────────────────────────────────
# Login d’usuari/empresa
# ─────────────────────────────────────────────────────────────
class LoginView(APIView):

    authentication_classes = []      # <-- perquè aquest endpoint és públic
    permission_classes = [] # <-- cap permís requerit

    def get(self, request):
        print("⚠️ Algu ha fet un GET a /api/login/")
        print("User-Agent:", request.META.get('HTTP_USER_AGENT'))
        return Response({"detail": "No es permet GET"}, status=status.HTTP_405_METHOD_NOT_ALLOWED)


    def post(self, request, format=None):
        ident = request.data.get('identificador')  # email (empresa) o nickname (treballador)
        password = request.data.get('password')

        if not ident or not password:
          return Response({'detail': 'Cal identificador i contrasenya'}, status=status.HTTP_400_BAD_REQUEST)

        subject_type = None
        subject_id = None

    # 1) Localitza subjecte (empresa per email / treballador per nickname)
        try:
            if '@' in ident:
                empresa = Empresa.objects.get(email=ident)
                subject_type = 'empresa'
                subject_id = empresa.pk
                pwd_qs = Contrasenya.objects.filter(id_empresa=empresa).order_by('-data_creacio')
            else:
                persona = Treballador.objects.get(nickname=ident)
                subject_type = 'treballador'
                subject_id = persona.pk
                pwd_qs = Contrasenya.objects.filter(id_treballador=persona).order_by('-data_creacio')
        
        except (Empresa.DoesNotExist, Treballador.DoesNotExist):
            return Response({'detail': 'Credencials incorrectes'}, status=status.HTTP_400_BAD_REQUEST)

    # 2) Valida contrasenya vigent (prioritza data_reemplas IS NULL)
        pwd_obj = pwd_qs.filter(data_reemplas__isnull=True).first() or pwd_qs.first()
        if not pwd_obj:
            return Response({'detail': 'Credencials incorrectes'}, status=status.HTTP_400_BAD_REQUEST)
        #Tan sols per desenvolupament perque aguanta contras hash i text pla*****************************************************************************************************
        ok, new_hash = _check_legacy_or_hash(password, pwd_obj.clau)
        if not ok:
            return Response({'detail': 'Credencials incorrectes'}, status=status.HTTP_400_BAD_REQUEST)

        # Si estava en plaintext i ha passat, la reemplacem pel hash
        if new_hash:
            pwd_obj.clau = new_hash
            pwd_obj.save(update_fields=['clau'])
        
        # Prepara les dades per al registre de sessió a l'historial
        now = timezone.localtime()

        log_data = {
        'data_inici': now.date(),
        'hora_inici': now.time().replace(microsecond=0),
        }

        if subject_type == 'treballador':
            log_data['id_treballador_id'] = subject_id
        else:
            log_data['id_empresa_id'] = subject_id
        #Crear elr registre a l'historial de entrades i l'envia a backend
        LogDeSessio.objects.create(**log_data)

        # 3) Token encriptat amb subject_id i subject_type
        token = generar_token_jwt(subject_id, subject_type)
        
        return Response({'token': token, 'subject_id': subject_id, 'tipus': subject_type}, status=status.HTTP_200_OK)

class MeView(APIView):
    """
    Endpoint de sessió per saber qui és l'usuari autenticat.

    Aquesta vista NO necessita rebre cap id des del frontend.
    Tot surt del token validat al backend.

    Retorna:
    - tipus del subjecte autenticat
    - subject_id
    - id_empresa resolt al backend
    - una mica d'informació bàsica útil per la UI
    """
    def get(self, request, format=None):
        subject_type = request.auth["tipus"] #objecte Empresa o Treballador
        subject_id = request.auth["subject_id"]
        subject_obj = request.user   #dades del token

        empresa_activa = self.getEmpresaSubj(
            subject_obj=subject_obj,
            subject_type=subject_type,
        )

        resposta = {
            "tipus": subject_type, 
            "subject_id": subject_id,
            "id_empresa": empresa_activa.id if empresa_activa else None,
        }

        # Afegim una mica d'informació bàsica segons el tipus
        if subject_type == "empresa":
            resposta["subjecte"] = {
                "id": subject_obj.id,
                "nom_empresa": subject_obj.nom_empresa,
            }

        elif subject_type == "treballador":
            resposta["subjecte"] = {
                "id": subject_obj.id,
                "nom": subject_obj.nom,
                "cognoms": subject_obj.cognoms,
                "nickname": subject_obj.nickname,
            }

        # Afegim empresa activa si n'hi ha
      # if empresa_activa:
      #     resposta["empresa_activa"] = {
      #         "id": empresa_activa.id,
      #         "nom_empresa": empresa_activa.nom_empresa,
      #         "email": empresa_activa.email,
      #         "sector": empresa_activa.sector,
      #         "estat": empresa_activa.estat,
      #     }

        return Response(resposta, status=status.HTTP_200_OK)
    
    @staticmethod
    def getEmpresaSubj(subject_obj, subject_type):
        """
        Resol quina és l'empresa activa del subjecte autenticat.

        Regles:
        - Si el subjecte és una empresa, la seva empresa activa és ella mateixa.
        - Si el subjecte és un treballador, cercam un contracte vigent avui:
            * estat = 'actiu'
            * data_contracte <= avui (o nul)
            * data_fi >= avui (o nul)

        Retorna:
        - objecte Empresa si es pot determinar
        - None si no hi ha empresa activa
        """

        # Cas 1: ha entrat una empresa
        if subject_type == "empresa":
            return subject_obj

        # Cas 2: ha entrat un treballador
        if subject_type == "treballador":
            avui = date.today()

            contracte = (
                ContracteTreballador.objects
                .select_related("id_empresa")
                .filter(
                    id_treballador=subject_obj,
                    estat="actiu"
                )
                .filter(
                    Q(data_contracte__isnull=True) | Q(data_contracte__lte=avui)
                )
                .filter(
                    Q(data_fi__isnull=True) | Q(data_fi__gte=avui)
                )
                .order_by("-data_contracte", "-id")
                .first()
            )

            if contracte and contracte.id_empresa:
                return contracte.id_empresa

            return None

        # Si arriba un tipus desconegut, retornam None per seguretat
        return None

class LogDeSessioList(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request, format=None):
        logs = LogDeSessio.objects.all()
        serializer = LogDeSessioSerializer(logs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = LogDeSessioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ConfiguracioList(APIView):

    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        configs = Configuracio.objects.all()
        serializer = ConfiguracioSerializer(configs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = ConfiguracioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerificacioList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        verificacions = Verificacio.objects.all()
        serializer = VerificacioSerializer(verificacions, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = VerificacioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DocumentObraList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = DocumentObra.objects.all()
        id_obra = request.query_params.get('id_obra')
        if id_obra:
            qs = qs.filter(id_obra_id=id_obra)
        serializer = DocumentObraSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = DocumentObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TascaList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        tasques = Tasca.objects.all()
        serializer = TascaSerializer(tasques, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = TascaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TascaTreballadorList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = TascaTreballador.objects.all()
        id_tasca = request.query_params.get('id_tasca')
        if id_tasca:
            qs = qs.filter(id_tasca_id=id_tasca)
        serializer = TascaTreballadorSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = TascaTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class IncidenciaList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        incidencies = Incidencia.objects.all()
        serializer = IncidenciaSerializer(incidencies, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = IncidenciaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SolucioList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = Solucio.objects.all()
        id_incidencia = request.query_params.get('id_incidencia')
        if id_incidencia:
            qs = qs.filter(id_incidencia_id=id_incidencia)
        serializer = SolucioSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = SolucioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SolucioDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """
    API endpoint per obtenir els detalls complets d'una solució.
    Inclou dades relacionades: incidència associada i tasca (si n'hi ha).
    """

    def get(self, request, pk, format=None):
        # Recuperar la instància de la solució o retornar 404 si no existeix
        solucio = get_object_or_404(Solucio, pk=pk)

        # Serialitzar la solució bàsica
        solucio_data = {
            'id': solucio.id,
            'descripcio': solucio.descripcio,
            'cost_monetari': solucio.cost_monetari,
            'eficacia': solucio.eficacia,
            'cost_temporal': solucio.cost_temporal,
            'impacte': solucio.impacte,
        }

        # Afegir dades de la incidència associada
        if solucio.id_incidencia:
            incidencia = solucio.id_incidencia
            solucio_data['incidencia'] = {
                'id': incidencia.id,
                'descripcio': incidencia.descripcio,
                'estat': incidencia.estat,
                'data_inici': incidencia.data_inici,
                'data_fi': incidencia.data_fi,
                'criticitat': incidencia.criticitat,
                'prioritat': incidencia.prioritat,
                'categoria': incidencia.categoria,
            }

        # Afegir dades de la tasca associada (si existeix)
        if solucio.id_tasca:
            tasca = solucio.id_tasca
            solucio_data['tasca'] = {
                'id': tasca.id,
                'descripcio': tasca.descripcio,
                'data_inici': tasca.data_inici,
                'data_fi': tasca.data_fi,
                'prioritat': tasca.prioritat,
                'visibilitat_tasca': tasca.visibilitat_tasca,
            }

        return Response(solucio_data, status=status.HTTP_200_OK)

    


class RecursList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        recursos = Recurs.objects.all()
        serializer = RecursSerializer(recursos, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = RecursSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SolRecursList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        qs = SolRecurs.objects.all()
        id_obra = request.query_params.get('id_obra')
        id_recurs = request.query_params.get('id_recurs')
        if id_obra:
            qs = qs.filter(id_obra_id=id_obra)
        if id_recurs:
            qs = qs.filter(id_recurs_id=id_recurs)
        serializer = SolRecursSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = SolRecursSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------- DOCUMENT_OBRA DETAIL --------------------
class DocumentObraDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        serializer = DocumentObraSerializer(doc)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        serializer = DocumentObraSerializer(doc, data=request.data, partial=False)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        doc.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# Opcional: pujada de fitxer BINARI amb multipart/form-data
class DocumentObraUploadView(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, format=None):
        # Exemple mínim: espera camp 'file' i metadades a 'data'
        fitxer = request.FILES.get('file')
        if not fitxer:
            return Response({'detail': 'file requerit'}, status=status.HTTP_400_BAD_REQUEST)

        # Aquí podries guardar el fitxer a disk/S3 i calcular mida, format, etc.
        mida_mb = fitxer.size / (1024 * 1024)
        nom = request.data.get('nom', fitxer.name)
        format_ext = nom.split('.')[-1].lower() if '.' in nom else 'bin'

        data = {
            'id_obra': request.data.get('id_obra'),
            'id_creador': request.data.get('id_creador'),
            'nom': nom,
            'format': format_ext,
            'mida': round(mida_mb, 2),
            'comentari': request.data.get('comentari'),
            'data_pujada': request.data.get('data_pujada') or timezone.now(),
            'tipus': request.data.get('tipus', 'general'),
        }

        serializer = DocumentObraSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------- TASCA_TREBALLADOR DETAIL & BULK DELETE --------------------
class TascaTreballadorDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        serializer = TascaTreballadorSerializer(assignacio)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        serializer = TascaTreballadorSerializer(assignacio, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        assignacio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TascaTreballadorBulkDeleteView(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """
    Elimina totes les assignacions d'una tasca.
    URL: /api/tasca_treballador/<id_tasca>/bulk_delete/
    """
    def delete(self, request, id_tasca, format=None):
        deleted, _ = TascaTreballador.objects.filter(id_tasca_id=id_tasca).delete()
        return Response({'deleted': deleted}, status=status.HTTP_204_NO_CONTENT)


# -------------------- SOLUCIO BULK DELETE --------------------
class SolucioBulkDeleteView(APIView):
    """
    Elimina totes les solucions d'una incidència.
    URL: /api/solucions/<id_incidencia>/bulk_delete/
    """
    def delete(self, request, id_incidencia, format=None):
        deleted, _ = Solucio.objects.filter(id_incidencia_id=id_incidencia).delete()
        return Response({'deleted': deleted}, status=status.HTTP_204_NO_CONTENT)


# -------------------- SOL_RECurs DETAIL --------------------
class SolRecursDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        sol = get_object_or_404(SolRecurs, pk=pk)
        data = SolRecursSerializer(sol).data

        # Afegim info extra d'obra i recurs
        if sol.id_obra:
            data['obra'] = ObraSerializer(sol.id_obra).data
        if sol.id_recurs:
            data['recurs'] = RecursSerializer(sol.id_recurs).data

        return Response(data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        sol = get_object_or_404(SolRecurs, pk=pk)
        serializer = SolRecursSerializer(sol, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        sol = get_object_or_404(SolRecurs, pk=pk)
        sol.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# ---------- 2) Permisos d'usuari: llista amb filtres + DETAIL amb PUT ----------
class PermisUsuariList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = PermisTreballador.objects.all()
        id_treballador = request.query_params.get('id_treballador')
        id_permis = request.query_params.get('id_permis')
        if id_treballador:
            qs = qs.filter(id_treballador_id=id_treballador)
        if id_permis:
            qs = qs.filter(id_permis_id=id_permis)
        serializer = PermisTreballadorSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = PermisTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(data_creacio=timezone.now())
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class PermisUsuariDetail(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        return Response(PermisTreballadorSerializer(obj).data)

    def put(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        serializer = PermisTreballadorSerializer(obj, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save(data_modif=timezone.now())
            return Response(PermisTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        serializer = PermisTreballadorSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            instance = serializer.save(data_modif=timezone.now())
            return Response(PermisTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        obj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# ---------- 3) ResponsableObra: afegeix filtres útils ----------
class ResponsableObraList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = ResponsableObra.objects.all()
        id_treballador = request.query_params.get('id_treballador')
        id_obra = request.query_params.get('id_obra')
        actiu = request.query_params.get('actiu')  # '1' -> data_fi IS NULL
        if id_treballador:
            qs = qs.filter(id_treballador_id=id_treballador)
        if id_obra:
            qs = qs.filter(id_obra_id=id_obra)
        if actiu == '1':
            qs = qs.filter(data_fi__isnull=True)
        return Response(ResponsableObraSerializer(qs, many=True).data)

    def post(self, request, format=None):
        serializer = ResponsableObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# ---------- 4) TascaTreballador: afegeix filtre per id_treballador ----------
class TascaTreballadorList(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request, format=None):
        qs = TascaTreballador.objects.all()
        id_tasca = request.query_params.get('id_tasca')
        id_treballador = request.query_params.get('id_treballador')
        if id_tasca:
            qs = qs.filter(id_tasca_id=id_tasca)
        if id_treballador:
            qs = qs.filter(id_treballador_id=id_treballador)
        return Response(TascaTreballadorSerializer(qs, many=True).data)

    def post(self, request, format=None):
        serializer = TascaTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# ---------- 5) Endpoint opcional: tasques d'un usuari (evita bucles al front) ----------
class TreballladorTasquesAssignadesView(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """Retorna les tasques detallades assignades a un usuari.
    GET /api/usuaris/<usuari_id>/tasques/
    """
    def get(self, request, treballador_id, format=None):
        # ids de tasques assignades
        tasca_ids = TascaTreballador.objects.filter(id_treballador_id=treballador_id).values_list('id_tasca_id', flat=True)
        tasques = Tasca.objects.filter(id__in=list(tasca_ids))
        data = []
        for t in tasques:
            t_data = TascaSerializer(t).data
            # obra
            if t.id_obra_id:
                t_data['obra'] = ObraSerializer(t.id_obra).data
            # incidències
            inc_qs = Incidencia.objects.filter(id_tasca=t)
            t_data['incidencies'] = IncidenciaSerializer(inc_qs, many=True).data
            # solucions
            sol_qs = Solucio.objects.filter(id_tasca=t)
            t_data['solucions'] = SolucioSerializer(sol_qs, many=True).data
            data.append(t_data)
        return Response(data, status=status.HTTP_200_OK)

# ---------- 6) Endpoint opcional: obres participades per usuari ----------
class TreballadorObresParticipadesView(APIView):
    authentication_classes = [JWTSubjectAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """Retorna la llista d'obres on l'usuari ha participat (tasques o responsable)."""
    def get(self, request, treballador_id, format=None):
        ids_tasques = TascaTreballador.objects.filter(id_treballador_id=treballador_id).values_list('id_tasca_id', flat=True)
        obra_ids_tasques = Tasca.objects.filter(id__in=list(ids_tasques)).values_list('id_obra_id', flat=True)
        obra_ids_resp = ResponsableObra.objects.filter(id_treballador_id=treballador_id).values_list('id_obra_id', flat=True)
        ids = set(list(obra_ids_tasques) + list(obra_ids_resp))
        obres = Obra.objects.filter(id__in=list(ids))
        return Response(ObraSerializer(obres, many=True).data, status=status.HTTP_200_OK)
