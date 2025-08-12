from rest_framework.views import APIView
from rest_framework import status
from django.db.models import Q
import jwt
from rest_framework.permissions import AllowAny
from django.contrib.auth.hashers import check_password

from datetime import datetime, timedelta, timezone
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from .models import (Obra,Treballador, Empresa, Contrasenya, Permis, PermisTreballador,
    LogDeSessio, Configuracio, Verificacio, DocumentObra, Tasca, TascaTreballador,
    Incidencia, Solucio, Recurs, SolRecurs, ResponsableObra)
from .serializer import (ObraSerializer,TreballadorSerializer, EmpresaSerializer, ContrasenyaSerializer,
    PermisSerializer, PermisTreballadorSerializer, LogDeSessioSerializer,
    ConfiguracioSerializer, VerificacioSerializer, DocumentObraSerializer,
    TascaSerializer, TascaTreballadorSerializer, IncidenciaSerializer, SolucioSerializer,
    RecursSerializer, SolRecursSerializer, ResponsableObraSerializer)
from django.http import Http404
from django.conf import settings
from django.shortcuts import get_object_or_404



#Gestiona llistes d'objectes del model d'Obres en aquest cas
class ObraList(APIView):
    def get(self, request, format=None):
        obres = Obra.objects.all()
        serializer = ObraSerializer(obres, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
        serializer = ObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    
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

    def get(self, request, pk):
        # Comprovar que l'obra existeix o retornar 404
        obra = get_object_or_404(Obra, pk=pk)

        # Serialitzar l'obra
        obra_data = ObraSerializer(obra).data

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
            responsable = ResponsableObra.objects.get(id_obra=obra)
            obra_data['responsable'] = ResponsableObraSerializer(responsable).data
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
    


class RecursosList(APIView):

    def get(self, request,format=None):
        recursos = Recurs.objects.all()
        serializer = RecursSerializer(recursos, many=True)
        return Response(serializer.data)
    
    def post(self, request, format=None):
        serializer = RecursSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
     
    def delete(self, request, format=None):
        recursos = Recurs.objects.all()
        recursos.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
     
    def put(self, request, format=None):
        recursos = Recurs.objects.all()
        serializer = RecursSerializer(recursos, data=request.data, many=True)
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
                'treballador': treballador_data,
                'comentari': tasca_treballador.comentari
            }
        except TascaTreballador.DoesNotExist:
            tasca_data['treballador_assignat'] = None

        return Response(tasca_data, status=status.HTTP_200_OK)


class TreballadorList(APIView):
    def get(self, request, format=None):
        persones = Treballador.objects.all()
        serializer = TreballadorSerializer(persones, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = TreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class EmpresaList(APIView):
    def get(self, request, format=None):
        empreses = Empresa.objects.all()
        serializer = EmpresaSerializer(empreses, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = EmpresaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ContrasenyaList(APIView):
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

class PermisTreballadorList(APIView):
    def get(self, request, format=None):
        permisos = PermisTreballador.objects.all()
        serializer = PermisTreballadorSerializer(permisos, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = PermisTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# ─────────────────────────────────────────────────────────────
# Login d’usuari/empresa
# ─────────────────────────────────────────────────────────────
class LoginView(APIView):
    """
    Endpoint públic de ‘login’.
    Accepta un **identificador** (email d’empresa o DNI/NIE de treballador)
    i una **contrasenya**.  Retorna un JWT si tot és correcte.
    """

    authentication_classes = []          # endpoint sense autenticació prèvia
    permission_classes     = [AllowAny]  # és públic

    # ───────────────────────────────────────────────
    # GET: només informatiu
    # ───────────────────────────────────────────────
    def get(self, request, *args, **kwargs):
        return Response(
            {"detail": "No es permet GET en aquest endpoint"},
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

    # ───────────────────────────────────────────────
    # POST: autenticació
    # ───────────────────────────────────────────────
    def post(self, request, *args, **kwargs):
        ident    = request.data.get("identificador")
        password = request.data.get("password")

        if not ident or not password:
            return Response(
                {"detail": "Cal ‘identificador’ i ‘password’"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ──────────────────────────
        # 1. Localitzar subjecte
        # ──────────────────────────
        subject_type = None          # "treballador" | "empresa"
        subject_obj  = None

        try:
            if "@" in ident:         # --> empresa per email
                subject_obj  = Empresa.objects.get(email=ident)
                subject_type = "empresa"
            else:                    # --> treballador per DNI/NIE
                subject_obj  = Treballador.objects.get(
                    dni_nie_passaport=ident
                )
                subject_type = "treballador"

        except (Empresa.DoesNotExist, Treballador.DoesNotExist):
            return Response(
                {"detail": "No existeix l'usuari o empresa"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ──────────────────────────
        # 2. Contrasenya vigent
        # ──────────────────────────
        if subject_type == "empresa":
            pwd_obj = (
                Contrasenya.objects
                .filter(id_empresa=subject_obj)
                .order_by("-data_creacio")
                .first()
            )
        else:  # treballador
            pwd_obj = (
                Contrasenya.objects
                .filter(id_treballador=subject_obj)
                .order_by("-data_creacio")
                .first()
            )

        if not pwd_obj:
            return Response(
                {"detail": "Contrasenya no trobada"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        if not check_password(password, pwd_obj.clau):
            return Response(
                {"detail": "Contrasenya incorrecta"},
                status=status.HTTP_401_UNAUTHORIZED
            )

        # ──────────────────────────
        # 3. Generar i tornar JWT
        # ──────────────────────────
        token = generar_token_jwt(
            subject_type=subject_type,
            subject_id   =subject_obj.id
        )

        return Response({"token": token}, status=status.HTTP_200_OK)
    

    # Opcionalment, podries afegir un GET per validar el token…
    # def get(self, request, format=None):
    #     return Response({'detail': 'OK'})  # només si ho necessites


class LogDeSessioList(APIView):
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


class ResponsableObraList(APIView):
    def get(self, request, format=None):
        responsables = ResponsableObra.objects.all()
        serializer = ResponsableObraSerializer(responsables, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = ResponsableObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# -------------------- DOCUMENT_OBRA DETAIL --------------------
class DocumentObraDetail(APIView):
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


# ---------- 1) Llista de Treballador (ja tens) + Detail opcional per usuari ----------

class TreballadorDetail(APIView):
    """
    API endpoint que retorna tots els detalls d'una persona concreta.
    Inclou:
      - Dades bàsiques de la persona (Treballador)
      - Dades bàsiques de l'Usuari associat
      - Configuració
      - Permisos
      - Logs de sessió
      - Tasques on participa
      - Obres on és responsable
    """

    def get(self, request, pk, format=None):
        # ──────────────────────────────────────────────
        # 1) Persona principal (404 si no existeix)
        # ──────────────────────────────────────────────
        persona = get_object_or_404(Treballador, pk=pk)

        persona_data = {
            'id': persona.pk,
            'nom': persona.nom,
            'cognoms': persona.cognoms,
            'nickname': persona.nickname,
            'rol': persona.rol,
            'estat': persona.estat,
        }

        # ──────────────────────────────────────────────
        # 2) Usuari vinculat (OneToOne)
        # ──────────────────────────────────────────────
        usuari = persona.usuari
        persona_data['usuari'] = {
            'id': usuari.id,
            'tipus': usuari.tipus,
            'telefon': usuari.telefon,
            'data_creacio': usuari.data_creacio,
            # Només si has afegit 'nickname' al model Usuari
        }

        # ──────────────────────────────────────────────
        # 3) Configuració (pot no existir)
        # ──────────────────────────────────────────────
        try:
            c = Configuracio.objects.get(id_usuari=usuari)
            persona_data['configuracio'] = {
                'idioma': c.idioma,
                'acceptacio_terms': c.acceptacio_terms,
                'imatge_perfil': c.imatge_perfil,
            }
        except Configuracio.DoesNotExist:
            persona_data['configuracio'] = None

        # ──────────────────────────────────────────────
        # 4) Permisos assignats
        # ──────────────────────────────────────────────
        permisos = PermisTreballador.objects.filter(id_usuari=usuari)
        persona_data['permisos'] = [
            {
                'id': p.id,
                'id_permis': p.id_permis_id,
                'lectura': p.lectura,
                'escriptura': p.escriptura,
                'edicio': p.edicio,
                'data_creacio': p.data_creacio,
                'data_modif': p.data_modif,
            }
            for p in permisos
        ]

        # ──────────────────────────────────────────────
        # 5) Logs de sessió
        # ──────────────────────────────────────────────
        logs = LogDeSessio.objects.filter(id_usuari=usuari)
        persona_data['logs_sessio'] = [
            {
                'id': l.id,
                'data_inici': l.data_inici,
                'hora_inici': l.hora_inici,
            }
            for l in logs
        ]

        # ──────────────────────────────────────────────
        # 6) Tasques on és treballador
        # ──────────────────────────────────────────────
        tasques_treb = TascaTreballador.objects.filter(id_treballador=usuari)
        persona_data['tasques'] = [
            {
                'id_tasca': t.id_tasca_id,
                'comentari': t.comentari,
                # informació bàsica de la tasca
                'descripcio': t.id_tasca.descripcio,
                'data_inici': t.id_tasca.data_inici,
                'data_fi': t.id_tasca.data_fi,
                'prioritat': t.id_tasca.prioritat,
            }
            for t in tasques_treb
        ]

        # ──────────────────────────────────────────────
        # 7) Obres on és responsable
        # ──────────────────────────────────────────────
        responsabilitats = ResponsableObra.objects.filter(id_treballador=usuari)
        persona_data['obres_responsable'] = [
            {
                'id_obra': r.id_obra_id,
                'nom_obra': r.id_obra.nom,
                'data_inici_resp': r.data_inici,
                'data_fi_resp': r.data_fi,
                'estat_obra': r.id_obra.estat,
            }
            for r in responsabilitats
        ]

        return Response(persona_data, status=status.HTTP_200_OK)

    # -----------------------------------------------------------------
    # PUT i DELETE per coherència amb la resta dels teus …Detail
    # -----------------------------------------------------------------
    def delete(self, request, pk, format=None):
        persona = get_object_or_404(Treballador, pk=pk)
        persona.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def put(self, request, pk, format=None):
        """
        Només actualitza els camps d'Treballador (nom, cognoms, rol, estat…).
        Si vols modificar l'Usuari o altres taules, fes-ho en endpoints
        específics.
        """
        persona = get_object_or_404(Treballador, pk=pk)
        allowed_fields = {'nom', 'cognoms', 'rol', 'estat'}
        for field in allowed_fields:
            if field in request.data:
                setattr(persona, field, request.data[field])
        persona.save()
        # Retornem la nova representació
        return self.get(request, pk)


# ---------- 2) Permisos d'usuari: llista amb filtres + DETAIL amb PUT ----------
class PermisTreballadorList(APIView):
    def get(self, request, format=None):
        qs = PermisTreballador.objects.all()
        id_usuari = request.query_params.get('id_usuari')
        id_permis = request.query_params.get('id_permis')
        if id_usuari:
            qs = qs.filter(id_usuari_id=id_usuari)
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

class TreballadorDetail(APIView):
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
class UsuariTasquesAssignadesView(APIView):
    """Retorna les tasques detallades assignades a un usuari.
    GET /api/usuaris/<usuari_id>/tasques/
    """
    def get(self, request, usuari_id, format=None):
        # ids de tasques assignades
        tasca_ids = TascaTreballador.objects.filter(id_treballador_id=usuari_id).values_list('id_tasca_id', flat=True)
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
class UsuariObresParticipadesView(APIView):
    """Retorna la llista d'obres on l'usuari ha participat (tasques o responsable)."""
    def get(self, request, usuari_id, format=None):
        ids_tasques = TascaTreballador.objects.filter(id_treballador_id=usuari_id).values_list('id_tasca_id', flat=True)
        obra_ids_tasques = Tasca.objects.filter(id__in=list(ids_tasques)).values_list('id_obra_id', flat=True)
        obra_ids_resp = ResponsableObra.objects.filter(id_treballador_id=usuari_id).values_list('id_obra_id', flat=True)
        ids = set(list(obra_ids_tasques) + list(obra_ids_resp))
        obres = Obra.objects.filter(id__in=list(ids))
        return Response(ObraSerializer(obres, many=True).data, status=status.HTTP_200_OK)
