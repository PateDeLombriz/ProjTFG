from datetime import datetime
from rest_framework.permissions import IsAdminUser
from rest_framework import status
from django.db.models import Q
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializer import MyTokenObtainPairSerializer
from django.utils import timezone
from datetime import datetime,date
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import permissions
from rest_framework.exceptions import PermissionDenied
from rest_framework_simplejwt.authentication import JWTAuthentication
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
from .authentication.helpers import (
    _assert_empresa_can_access_document_obra,
    _assert_empresa_can_access_incidencia,
    _assert_empresa_can_access_sol_recurs,
    _assert_empresa_can_access_tasca,
    _assert_empresa_can_access_ubicacio,
    _get_auth_context,
    _assert_empresa_can_access_empresa,
    _assert_empresa_can_access_treballador,
    _assert_empresa_can_access_obra,
    _assert_empresa_can_access_permis_usuari,
    _assert_empresa_can_access_tasca_treballador,
    _assert_empresa_can_access_recurs,
    _assert_empresa_can_access_solucio,
    _assert_can_access_contracte,
    _assert_empresa_can_access_configuracio,
    _assert_empresa_can_access_verificacio,
    _is_contracte_vigent,
    _assert_query_obra_in_context,
    _assert_query_treballador_in_context,
    _empresa_accessible_obra_ids,
    _empresa_accessible_treballador_ids,
    

)
class LoginView(TokenObtainPairView):
    authentication_classes = []
    permission_classes = []
    serializer_class = MyTokenObtainPairSerializer

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
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        _assert_empresa_can_access_obra(request, pk)
        
        obra = get_object_or_404(Obra, pk=pk)

        obra_data = ObraSerializer(obra).data

        if obra.ubicacio is not None:
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

        incidencies = Incidencia.objects.filter(id_obra=obra)
        obra_data['incidencies'] = IncidenciaSerializer(incidencies, many=True).data

        tasques = Tasca.objects.filter(id_obra=obra)
        obra_data['tasques'] = TascaSerializer(tasques, many=True).data

        documents = DocumentObra.objects.filter(id_obra=obra)
        obra_data['documents'] = DocumentObraSerializer(documents, many=True).data

        sol_recursos = SolRecurs.objects.filter(id_obra=obra)
        obra_data['sol_recursos'] = SolRecursSerializer(sol_recursos, many=True).data

        responsable = ResponsableObra.objects.filter(id_obra=obra)
        obra_data['responsable'] = ResponsableObraSerializer(responsable, many=True).data

        return Response(obra_data, status=status.HTTP_200_OK)

    def put(self, request, pk):
        _assert_empresa_can_access_obra(request, pk)

        obra = get_object_or_404(Obra, pk=pk)
        serializer = ObraSerializer(obra, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        _assert_empresa_can_access_obra(request, pk)

        obra = get_object_or_404(Obra, pk=pk)
        obra.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ObresListEmpresa(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden consultar aquestes obres.")

        if subject_id != pk:
            raise PermissionDenied("No pots consultar les obres d'una altra empresa.")

        obres = ObraEmpresa.objects.filter(id_empresa_id=pk).select_related(
            "id_obra",
            "id_obra__ubicacio",
        )

        serializer = ObraEmpresaSerializer(obres, many=True)
        data = serializer.data

        for i, relacio in enumerate(obres):
            obra = relacio.id_obra

            if obra is None:
                data[i]["obra_info"] = None
                continue

            data[i]["obra_info"] = {
                "id": obra.id,
                "nom": obra.nom,
                "descripcio": obra.descripcio,
                "estat": obra.estat,
                "ubicacio_info": {
                    "id_ubicacio": obra.ubicacio.id_ubicacio,
                    "adreca": obra.ubicacio.adreca,
                    "ciutat": obra.ubicacio.ciutat,
                } if obra.ubicacio else None,
            }

        return Response(data, status=status.HTTP_200_OK)

    def post(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type != "empresa":
            raise PermissionDenied("Només les empreses poden crear obres.")

        if subject_id != pk:
            raise PermissionDenied("No pots crear obres per una altra empresa.")

        payload = request.data.copy()
        payload["id_empresa"] = pk

        serializer = ObraEmpresaSerializer(data=payload)
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

        deleted, _ = ObraEmpresa.objects.filter(id_empresa_id=pk).delete()
        return Response({"deleted": deleted}, status=status.HTTP_200_OK)
    

class UbicacioDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        _assert_empresa_can_access_ubicacio(request, ubicacio)

        serializer = UbicacioSerializer(ubicacio)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        _assert_empresa_can_access_ubicacio(request, ubicacio)

        serializer = UbicacioSerializer(ubicacio, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        ubicacio = get_object_or_404(Ubicacio, pk=pk)
        _assert_empresa_can_access_ubicacio(request, ubicacio)

        ubicacio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

        
# -------------------- DOCUMENT_OBRA DETAIL --------------------
class DocumentObraDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        _assert_empresa_can_access_document_obra(request, doc)

        serializer = DocumentObraSerializer(doc)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        _assert_empresa_can_access_document_obra(request, doc)

        serializer = DocumentObraSerializer(doc, data=request.data, partial=False)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        doc = get_object_or_404(DocumentObra, pk=pk)
        _assert_empresa_can_access_document_obra(request, doc)

        doc.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
# Opcional: pujada de fitxer BINARI amb multipart/form-data


class ContracteTreballadorDetail(APIView):
    """
    Endpoint per gestionar un contracte concret.
    - GET: obté un contracte i informació extra
    - PUT: reemplaça totes les dades del contracte
    - PATCH: actualitza parcialment
    - DELETE: elimina el contracte
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self, pk):
        return get_object_or_404(ContracteTreballador, pk=pk)

    def get(self, request, pk, format=None):
        obj = self.get_object(pk)
        _assert_can_access_contracte(request, obj)

        data = ContracteTreballadorSerializer(obj).data

        avui = timezone.now().date()
        data['vigent_avui'] = (
            (obj.data_contracte is None or obj.data_contracte <= avui) and
            (obj.data_fi is None or obj.data_fi >= avui) and
            _is_contracte_vigent(obj)
        )

        if obj.id_treballador_id:
            data['treballador'] = {'id': obj.id_treballador_id}
        if obj.id_empresa_id:
            data['empresa_info'] = {'id': obj.id_empresa_id}

        return Response(data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        obj = self.get_object(pk)
        _assert_can_access_contracte(request, obj)

        serializer = ContracteTreballadorSerializer(obj, data=request.data, partial=False)
        if serializer.is_valid():
            try:
                instance = serializer.save()
                return Response(ContracteTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        obj = self.get_object(pk)
        _assert_can_access_contracte(request, obj)

        serializer = ContracteTreballadorSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            try:
                instance = serializer.save()
                return Response(ContracteTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
            except Exception as e:
                return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        obj = self.get_object(pk)
        _assert_can_access_contracte(request, obj)

        obj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class IncidenciaDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        incidencia = get_object_or_404(Incidencia, pk=pk)
        _assert_empresa_can_access_incidencia(request, incidencia)

        incidencia_data = IncidenciaSerializer(incidencia).data

        if incidencia.id_obra:
            obra_data = ObraSerializer(incidencia.id_obra).data
            incidencia_data['obra'] = obra_data

        if incidencia.id_tasca:
            tasca_data = TascaSerializer(incidencia.id_tasca).data
            incidencia_data['tasca'] = tasca_data

        solucions = Solucio.objects.filter(id_incidencia=incidencia)
        solucions_data = SolucioSerializer(solucions, many=True).data
        incidencia_data['solucions'] = solucions_data

        return Response(incidencia_data, status=status.HTTP_200_OK)


class TasquesDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        tasca = get_object_or_404(Tasca, pk=pk)
        _assert_empresa_can_access_tasca(request, tasca)

        tasca_data = TascaSerializer(tasca).data

        if tasca.id_obra:
            obra_data = ObraSerializer(tasca.id_obra).data
            tasca_data['obra'] = obra_data

        if tasca.id_tasca_pare:
            tasca_pare_data = TascaSerializer(tasca.id_tasca_pare).data
            tasca_data['tasca_pare'] = tasca_pare_data

        incidencies = Incidencia.objects.filter(id_tasca=tasca)
        tasca_data['incidencies'] = IncidenciaSerializer(incidencies, many=True).data

        solucions = Solucio.objects.filter(id_tasca=tasca)
        tasca_data['solucions'] = SolucioSerializer(solucions, many=True).data

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

# -------------------- SOL_RECurs DETAIL --------------------
class SolRecursDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        sol_recurs = get_object_or_404(SolRecurs, pk=pk)
        _assert_empresa_can_access_sol_recurs(request, sol_recurs)

        serializer = SolRecursSerializer(sol_recurs)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, pk, format=None):
        sol_recurs = get_object_or_404(SolRecurs, pk=pk)
        _assert_empresa_can_access_sol_recurs(request, sol_recurs)

        serializer = SolRecursSerializer(sol_recurs, data=request.data, partial=False)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        sol_recurs = get_object_or_404(SolRecurs, pk=pk)
        _assert_empresa_can_access_sol_recurs(request, sol_recurs)

        sol_recurs.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class TreballadorDetail(APIView):
    """
    Retorna informació completa d'un treballador:
      - dades bàsiques
      - ubicació
      - contractes i empreses
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        _assert_empresa_can_access_treballador(request, pk)

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
        _assert_empresa_can_access_treballador(request, pk)

        treballador = get_object_or_404(Treballador, pk=pk)
        serializer = TreballadorSerializer(treballador, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        _assert_empresa_can_access_treballador(request, pk)

        treballador = get_object_or_404(Treballador, pk=pk)
        treballador.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class EmpresaDetail(APIView):
    """
    Retorna informació completa d'una empresa:
      - dades bàsiques
      - ubicació
      - treballadors contractats
      - obres relacionades
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        _assert_empresa_can_access_empresa(request, pk)

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
        _assert_empresa_can_access_empresa(request, pk)

        empresa = get_object_or_404(Empresa, pk=pk)
        serializer = EmpresaSerializer(empresa, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        _assert_empresa_can_access_empresa(request, pk)

        empresa = get_object_or_404(Empresa, pk=pk)
        empresa.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    

class TreballadorContracteVigentView(APIView):
    """
    Endpoint específic per obtenir el contracte vigent d'un treballador avui.
    GET /api/treballadors/<id_treballador>/contracte_vigent/
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, id_treballador, format=None):
        _assert_empresa_can_access_treballador(request, id_treballador)

        avui = timezone.now().date()
        obj = (
            ContracteTreballador.objects
            .filter(id_treballador_id=id_treballador, data_contracte__lte=avui)
            .filter(Q(data_fi__isnull=True) | Q(data_fi__gte=avui))
            .order_by('-data_contracte')
            .first()
        )
        if not obj:
            return Response({'detail': 'Sense contracte vigent'}, status=status.HTTP_404_NOT_FOUND)

        return Response(ContracteTreballadorSerializer(obj).data, status=status.HTTP_200_OK)


class PermisUsuariDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        _assert_empresa_can_access_permis_usuari(request, obj)

        return Response(PermisTreballadorSerializer(obj).data)

    def put(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        _assert_empresa_can_access_permis_usuari(request, obj)

        serializer = PermisTreballadorSerializer(obj, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save(data_modif=timezone.now())
            return Response(PermisTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        _assert_empresa_can_access_permis_usuari(request, obj)

        serializer = PermisTreballadorSerializer(obj, data=request.data, partial=True)
        if serializer.is_valid():
            instance = serializer.save(data_modif=timezone.now())
            return Response(PermisTreballadorSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        obj = get_object_or_404(PermisTreballador, pk=pk)
        _assert_empresa_can_access_permis_usuari(request, obj)

        obj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    

class TascaTreballadorDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        _assert_empresa_can_access_tasca_treballador(request, assignacio)

        serializer = TascaTreballadorSerializer(assignacio)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        _assert_empresa_can_access_tasca_treballador(request, assignacio)

        serializer = TascaTreballadorSerializer(assignacio, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        assignacio = get_object_or_404(TascaTreballador, pk=pk)
        _assert_empresa_can_access_tasca_treballador(request, assignacio)

        assignacio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    
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
      subject_type = request.auth["tipus"]
      subject_id = request.auth["subject_id"]
      user = request.user

      empresa_activa = self.getEmpresaSubj(
          subject_obj=user,
          subject_type=subject_type,
      )

      resposta = {
          "tipus": subject_type,
          "subject_id": subject_id,
          "id_empresa": empresa_activa.id if empresa_activa else None,
      }

      if subject_type == "empresa":
          empresa = user.empresa
          resposta["subjecte"] = {
              "id": empresa.id,
              "nom_empresa": empresa.nom_empresa,
          }

      elif subject_type == "treballador":
          treballador = user.treballador
          resposta["subjecte"] = {
              "id": treballador.pk,
              "nom": treballador.nom,
              "cognoms": treballador.cognoms,
              "nickname": treballador.nickname,
          }

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
        print(f"Resolent empresa per subjecte_type={subject_type}, subject_obj={subject_obj}")

        # Cas 1: ha entrat una empresa
        if subject_type == "empresa":
            return subject_obj

        # Cas 2: ha entrat un treballador
        if subject_type == "treballador":
            avui = date.today()
            idTreballador = Treballador.objects.filter(nickname=subject_obj).first()
            contracte = (
                ContracteTreballador.objects
                .select_related("id_empresa")
                .filter(
                    id_treballador=idTreballador,
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
    
class TreballadorProfileView(APIView):
    """
    Perfil d'un treballador.
    - Treballador autenticat: només pot veure el seu propi perfil.
    - Empresa autenticada: pot veure el perfil d'un treballador del seu context.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        subject_type = request.auth["tipus"]
        subject_id = int(request.auth["subject_id"])

        if subject_type == "treballador":
            if subject_id != pk:
                raise PermissionDenied("No pots accedir al perfil d'un altre treballador.")
        elif subject_type == "empresa":
            _assert_empresa_can_access_treballador(request, pk)
        else:
            raise PermissionDenied("Tipus de subjecte no autoritzat.")

        treballador = get_object_or_404(Treballador, pk=pk)
        avui = timezone.now().date()

        contracte = (
            ContracteTreballador.objects
            .select_related("id_empresa")
            .filter(
                id_treballador=treballador,
                estat="actiu",
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

        tasques_count = (
            TascaTreballador.objects
            .filter(id_treballador=treballador)
            .values("id_tasca_id")
            .distinct()
            .count()
        )

        obra_ids_tasques = list(
            Tasca.objects
            .filter(
                id__in=TascaTreballador.objects.filter(
                    id_treballador=treballador
                ).values_list("id_tasca_id", flat=True)
            )
            .values_list("id_obra_id", flat=True)
            .distinct()
        )

        obra_ids_responsable = list(
            ResponsableObra.objects
            .filter(id_treballador=treballador)
            .values_list("id_obra_id", flat=True)
            .distinct()
        )

        obres_count = len(set(obra_ids_tasques + obra_ids_responsable))

        cfg = (
            Configuracio.objects
            .filter(id_treballador=treballador)
            .first()
        )

        foto_url = None
        if treballador.foto:
            foto_url = request.build_absolute_uri(treballador.foto.url)
        elif cfg and cfg.imatge_perfil:
            foto_url = cfg.imatge_perfil

        data = {
            "id": treballador.id,
            "nom": treballador.nom,
            "cognoms": treballador.cognoms,
            "nickname": treballador.nickname,
            "telefon": treballador.telefon,
            "email": treballador.email,
            "foto": foto_url,
            "empresa_actual": (
                {
                    "id": contracte.id_empresa.id,
                    "nom_empresa": contracte.id_empresa.nom_empresa,
                }
                if contracte and contracte.id_empresa else None
            ),
            "carrec_actual": contracte.carrec if contracte else None,
            "estat_contracte": contracte.estat if contracte else None,
            "tasques_count": tasques_count,
            "obres_count": obres_count,
        }

        return Response(data, status=status.HTTP_200_OK)

        
class RecursDetail(APIView):
    """
    API View que retorna els detalls d'un recurs concret,
    però només amb les sol·licituds d'obres del context de l'empresa autenticada.
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        recurs = get_object_or_404(Recurs, pk=pk)
        _assert_empresa_can_access_recurs(request, recurs)

        empresa_id = int(request.auth["subject_id"])
        obra_ids = ObraEmpresa.objects.filter(
            id_empresa_id=empresa_id
        ).values_list('id_obra_id', flat=True)

        recurs_data = RecursSerializer(recurs).data

        sol_entrades = SolRecurs.objects.filter(
            id_recurs=recurs,
            id_obra_id__in=obra_ids
        )

        sol_entrades_data = SolRecursSerializer(sol_entrades, many=True).data

        for i, sol in enumerate(sol_entrades):
            if sol.id_obra:
                sol_entrades_data[i]['obra'] = ObraSerializer(sol.id_obra).data

        recurs_data['sollicituds'] = sol_entrades_data

        return Response(recurs_data, status=status.HTTP_200_OK)
    
class TreballladorTasquesAssignadesView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """
    Retorna les tasques detallades assignades a un treballador del context de l'empresa.
    GET /api/treballadors/<treballador_id>/tasques/
    """
    def get(self, request, treballador_id, format=None):
        _assert_empresa_can_access_treballador(request, treballador_id)

        tasca_ids = TascaTreballador.objects.filter(
            id_treballador_id=treballador_id
        ).values_list('id_tasca_id', flat=True)

        tasques = Tasca.objects.filter(id__in=list(tasca_ids))

        data = []
        for t in tasques:
            t_data = TascaSerializer(t).data

            if t.id_obra_id:
                t_data['obra'] = ObraSerializer(t.id_obra).data

            inc_qs = Incidencia.objects.filter(id_tasca=t)
            t_data['incidencies'] = IncidenciaSerializer(inc_qs, many=True).data

            sol_qs = Solucio.objects.filter(id_tasca=t)
            t_data['solucions'] = SolucioSerializer(sol_qs, many=True).data

            data.append(t_data)

        return Response(data, status=status.HTTP_200_OK)
    
class TreballadorObresParticipadesView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """
    Retorna la llista d'obres on el treballador ha participat.
    """
    def get(self, request, treballador_id, format=None):
        _assert_empresa_can_access_treballador(request, treballador_id)

        ids_tasques = TascaTreballador.objects.filter(
            id_treballador_id=treballador_id
        ).values_list('id_tasca_id', flat=True)

        obra_ids_tasques = Tasca.objects.filter(
            id__in=list(ids_tasques)
        ).values_list('id_obra_id', flat=True)

        obra_ids_resp = ResponsableObra.objects.filter(
            id_treballador_id=treballador_id
        ).values_list('id_obra_id', flat=True)

        ids = set(list(obra_ids_tasques) + list(obra_ids_resp))
        obres = Obra.objects.filter(id__in=list(ids))

        return Response(ObraSerializer(obres, many=True).data, status=status.HTTP_200_OK)
    
class TascaTreballadorBulkDeleteView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]
    """
    Elimina totes les assignacions d'una tasca.
    URL: /api/tasca_treballador/<id_tasca>/bulk_delete/
    """
    def delete(self, request, id_tasca, format=None):
        _assert_empresa_can_access_tasca_treballador(
            request,
            get_object_or_404(Tasca, pk=id_tasca).id
        )

        deleted, _ = TascaTreballador.objects.filter(id_tasca_id=id_tasca).delete()
        return Response({'deleted': deleted}, status=status.HTTP_204_NO_CONTENT)
    
class SolucioBulkDeleteView(APIView):
    """
    Elimina totes les solucions d'una incidència.
    URL: /api/solucions/<id_incidencia>/bulk_delete/
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, id_incidencia, format=None):
        incidencia = get_object_or_404(Incidencia, pk=id_incidencia)
        _assert_empresa_can_access_incidencia(request, incidencia)

        deleted, _ = Solucio.objects.filter(id_incidencia_id=id_incidencia).delete()
        return Response({'deleted': deleted}, status=status.HTTP_204_NO_CONTENT)
    



class DocumentObraList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = DocumentObra.objects.filter(id_obra_id__in=obra_ids)

        id_obra = request.query_params.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        serializer = DocumentObraSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        serializer = DocumentObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DocumentObraList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = DocumentObra.objects.filter(id_obra_id__in=obra_ids)

        id_obra = request.query_params.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        serializer = DocumentObraSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        serializer = DocumentObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class TascaList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = Tasca.objects.filter(id_obra_id__in=obra_ids)

        id_obra = request.query_params.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        serializer = TascaSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        serializer = TascaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class IncidenciaList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = Incidencia.objects.filter(id_obra_id__in=obra_ids)

        id_obra = request.query_params.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        serializer = IncidenciaSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        serializer = IncidenciaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SolRecursList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = SolRecurs.objects.filter(id_obra_id__in=obra_ids)

        id_obra = request.query_params.get('id_obra')
        id_recurs = request.query_params.get('id_recurs')

        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        if id_recurs:
            qs = qs.filter(id_recurs_id=id_recurs)

        serializer = SolRecursSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        serializer = SolRecursSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class PermisUsuariList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        treballador_ids = _empresa_accessible_treballador_ids(empresa_id)

        qs = PermisTreballador.objects.filter(id_treballador_id__in=treballador_ids)

        id_treballador = request.query_params.get('id_treballador')
        id_permis = request.query_params.get('id_permis')

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)
            qs = qs.filter(id_treballador_id=id_treballador)

        if id_permis:
            qs = qs.filter(id_permis_id=id_permis)

        serializer = PermisTreballadorSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        id_treballador = request.data.get('id_treballador')
        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)

        serializer = PermisTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(data_creacio=timezone.now())
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class TascaTreballadorList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = TascaTreballador.objects.filter(id_tasca__id_obra_id__in=obra_ids)

        id_tasca = request.query_params.get('id_tasca')
        id_treballador = request.query_params.get('id_treballador')

        if id_tasca:
            tasca = get_object_or_404(Tasca, pk=id_tasca)
            _assert_empresa_can_access_tasca(request, tasca)
            qs = qs.filter(id_tasca_id=id_tasca)

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)
            qs = qs.filter(id_treballador_id=id_treballador)

        return Response(TascaTreballadorSerializer(qs, many=True).data)

    def post(self, request, format=None):
        id_tasca = request.data.get('id_tasca')
        id_treballador = request.data.get('id_treballador')

        if id_tasca:
            tasca = get_object_or_404(Tasca, pk=id_tasca)
            _assert_empresa_can_access_tasca(request, tasca)

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)

        serializer = TascaTreballadorSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ResponsableObraList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = ResponsableObra.objects.filter(id_obra_id__in=obra_ids)

        id_treballador = request.query_params.get('id_treballador')
        id_obra = request.query_params.get('id_obra')
        actiu = request.query_params.get('actiu')

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)
            qs = qs.filter(id_treballador_id=id_treballador)

        if id_obra:
            _assert_query_obra_in_context(request, id_obra)
            qs = qs.filter(id_obra_id=id_obra)

        if actiu == '1':
            qs = qs.filter(data_fi__isnull=True)

        return Response(ResponsableObraSerializer(qs, many=True).data)

    def post(self, request, format=None):
        id_obra = request.data.get('id_obra')
        id_treballador = request.data.get('id_treballador')

        if id_obra:
            _assert_query_obra_in_context(request, id_obra)

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)

        serializer = ResponsableObraSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class RecursList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        recurs_ids = SolRecurs.objects.filter(
            id_obra_id__in=obra_ids
        ).values_list('id_recurs_id', flat=True).distinct()

        recursos = Recurs.objects.filter(id__in=recurs_ids)
        serializer = RecursSerializer(recursos, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = RecursSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class SolucioList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        obra_ids = _empresa_accessible_obra_ids(empresa_id)

        qs = Solucio.objects.filter(
            Q(id_incidencia__id_obra_id__in=obra_ids) |
            Q(id_tasca__id_obra_id__in=obra_ids)
        ).distinct()

        id_incidencia = request.query_params.get('id_incidencia')
        id_tasca = request.query_params.get('id_tasca')

        if id_incidencia:
            incidencia = get_object_or_404(Incidencia, pk=id_incidencia)
            _assert_empresa_can_access_incidencia(request, incidencia)
            qs = qs.filter(id_incidencia_id=id_incidencia)

        if id_tasca:
            tasca = get_object_or_404(Tasca, pk=id_tasca)
            _assert_empresa_can_access_tasca(request, tasca)
            qs = qs.filter(id_tasca_id=id_tasca)

        return Response(SolucioSerializer(qs, many=True).data)

    def post(self, request, format=None):
        id_incidencia = request.data.get('id_incidencia')
        id_tasca = request.data.get('id_tasca')

        if id_incidencia:
            incidencia = get_object_or_404(Incidencia, pk=id_incidencia)
            _assert_empresa_can_access_incidencia(request, incidencia)

        if id_tasca:
            tasca = get_object_or_404(Tasca, pk=id_tasca)
            _assert_empresa_can_access_tasca(request, tasca)

        serializer = SolucioSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class SolucioDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        solucio = get_object_or_404(Solucio, pk=pk)
        _assert_empresa_can_access_solucio(request, solucio)

        solucio_data = SolucioSerializer(solucio).data

        if solucio.id_incidencia:
            incidencia = solucio.id_incidencia
            solucio_data['incidencia'] = {
                'id': incidencia.id,
                'descripcio': incidencia.descripcio,
                'data_inici': incidencia.data_inici,
                'data_fi': incidencia.data_fi,
                'criticitat': incidencia.criticitat,
                'prioritat': incidencia.prioritat,
                'categoria': incidencia.categoria,
            }

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

    def put(self, request, pk, format=None):
        solucio = get_object_or_404(Solucio, pk=pk)
        _assert_empresa_can_access_solucio(request, solucio)

        serializer = SolucioSerializer(solucio, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(SolucioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        solucio = get_object_or_404(Solucio, pk=pk)
        _assert_empresa_can_access_solucio(request, solucio)

        solucio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class ConfiguracioList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        treballador_ids = _empresa_accessible_treballador_ids(empresa_id)

        qs = Configuracio.objects.filter(
            Q(id_empresa_id=empresa_id) |
            Q(id_treballador_id__in=treballador_ids)
        )

        id_empresa = request.query_params.get('id_empresa')
        id_treballador = request.query_params.get('id_treballador')

        if id_empresa:
            _assert_empresa_can_access_empresa(request, int(id_empresa))
            qs = qs.filter(id_empresa_id=id_empresa)

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)
            qs = qs.filter(id_treballador_id=id_treballador)

        return Response(ConfiguracioSerializer(qs, many=True).data)

    def post(self, request, format=None):
        id_empresa = request.data.get('id_empresa')
        id_treballador = request.data.get('id_treballador')

        if id_empresa:
            _assert_empresa_can_access_empresa(request, int(id_empresa))
        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)

        serializer = ConfiguracioSerializer(data=request.data)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ConfiguracioList(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, format=None):
        empresa_id = int(request.auth["subject_id"])
        treballador_ids = _empresa_accessible_treballador_ids(empresa_id)

        qs = Configuracio.objects.filter(
            Q(id_empresa_id=empresa_id) |
            Q(id_treballador_id__in=treballador_ids)
        )

        id_empresa = request.query_params.get('id_empresa')
        id_treballador = request.query_params.get('id_treballador')

        if id_empresa:
            _assert_empresa_can_access_empresa(request, int(id_empresa))
            qs = qs.filter(id_empresa_id=id_empresa)

        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)
            qs = qs.filter(id_treballador_id=id_treballador)

        return Response(ConfiguracioSerializer(qs, many=True).data)

    def post(self, request, format=None):
        id_empresa = request.data.get('id_empresa')
        id_treballador = request.data.get('id_treballador')

        if id_empresa:
            _assert_empresa_can_access_empresa(request, int(id_empresa))
        if id_treballador:
            _assert_query_treballador_in_context(request, id_treballador)

        serializer = ConfiguracioSerializer(data=request.data)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
class ConfiguracioDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        return Response(ConfiguracioSerializer(cfg).data)

    def put(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        serializer = ConfiguracioSerializer(cfg, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        serializer = ConfiguracioSerializer(cfg, data=request.data, partial=True)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        cfg.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
class ConfiguracioDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        return Response(ConfiguracioSerializer(cfg).data)

    def put(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        serializer = ConfiguracioSerializer(cfg, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        serializer = ConfiguracioSerializer(cfg, data=request.data, partial=True)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ConfiguracioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        cfg = get_object_or_404(Configuracio, pk=pk)
        _assert_empresa_can_access_configuracio(request, cfg)

        cfg.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    

class VerificacioDetail(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk, format=None):
        verificacio = get_object_or_404(Verificacio, pk=pk)
        _assert_empresa_can_access_verificacio(request, verificacio)

        return Response(VerificacioSerializer(verificacio).data)

    def put(self, request, pk, format=None):
        verificacio = get_object_or_404(Verificacio, pk=pk)
        _assert_empresa_can_access_verificacio(request, verificacio)

        serializer = VerificacioSerializer(verificacio, data=request.data, partial=False)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(VerificacioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk, format=None):
        verificacio = get_object_or_404(Verificacio, pk=pk)
        _assert_empresa_can_access_verificacio(request, verificacio)

        serializer = VerificacioSerializer(verificacio, data=request.data, partial=True)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(VerificacioSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        verificacio = get_object_or_404(Verificacio, pk=pk)
        _assert_empresa_can_access_verificacio(request, verificacio)

        verificacio.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
#class EmpresaList(APIView):
#    authentication_classes = [JWTAuthentication]
#    permission_classes = [permissions.IsAuthenticated]
#
#    def get(self, request, format=None):
#        empresa_id = int(request.auth["subject_id"])
#
#        qs = Empresa.objects.filter(id=empresa_id)
#
#        estat = request.query_params.get('estat')
#        sector = request.query_params.get('sector')
#        q = request.query_params.get('q')
#
#        if estat:
#            qs = qs.filter(estat=estat)
#        if sector:
#            qs = qs.filter(sector=sector)
#        if q:
#            qs = qs.filter(
#                Q(nom_empresa__icontains=q) |
#                Q(cif__icontains=q) |
#                Q(email__icontains=q)
#            )
#
#        return Response(EmpresaSerializer(qs, many=True).data)
#
#    def post(self, request, format=None):
#        serializer = EmpresaSerializer(data=request.data)
#        if serializer.is_valid():
#            empresa = serializer.save()
#            return Response(EmpresaSerializer(empresa).data, status=status.HTTP_201_CREATED)
#        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#    
#class TreballadorList(APIView):
#    authentication_classes = [JWTAuthentication]
#    permission_classes = [permissions.IsAuthenticated]
#
#    def get(self, request, format=None):
#        empresa_id = int(request.auth["subject_id"])
#        treballador_ids = _empresa_accessible_treballador_ids(empresa_id)
#
#        qs = Treballador.objects.filter(id__in=treballador_ids)
#
#        q = request.query_params.get('q')
#        if q:
#            qs = qs.filter(
#                Q(nom__icontains=q) |
#                Q(cognoms__icontains=q) |
#                Q(nickname__icontains=q) |
#                Q(email__icontains=q)
#            )
#
#        return Response(TreballadorSerializer(qs, many=True).data)
#
#    def post(self, request, format=None):
#        serializer = TreballadorSerializer(data=request.data)
#        if serializer.is_valid():
#            serializer.save()
#            return Response(serializer.data, status=status.HTTP_201_CREATED)
#        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#    
#class TasquesList(APIView):
#    authentication_classes = [JWTAuthentication]
#    permission_classes = [permissions.IsAuthenticated]
#
#    def get(self, request, format=None):
#        empresa_id = int(request.auth["subject_id"])
#        obra_ids = _empresa_accessible_obra_ids(empresa_id)
#
#        qs = Tasca.objects.filter(id_obra_id__in=obra_ids)
#
#        id_obra = request.query_params.get('id_obra')
#        if id_obra:
#            _assert_query_obra_in_context(request, id_obra)
#            qs = qs.filter(id_obra_id=id_obra)
#
#        return Response(TascaSerializer(qs, many=True).data)
#
#    def post(self, request, format=None):
#        id_obra = request.data.get('id_obra')
#        if id_obra:
#            _assert_query_obra_in_context(request, id_obra)
#
#        serializer = TascaSerializer(data=request.data)
#        if serializer.is_valid():
#            serializer.save()
#            return Response(serializer.data, status=status.HTTP_201_CREATED)
#        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
#
#    def delete(self, request, format=None):
#        return Response(
#            {'detail': 'No es permet esborrat massiu de tasques.'},
#            status=status.HTTP_405_METHOD_NOT_ALLOWED
#        )
#
#    def put(self, request, format=None):
#        return Response(
#            {'detail': 'No es permet actualització massiva de tasques.'},
#            status=status.HTTP_405_METHOD_NOT_ALLOWED
#        )