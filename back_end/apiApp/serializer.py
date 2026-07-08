
#El serializer s’encarrega de les dades:
#
#definir quins camps entren o surten
#validar els valors
#transformar dades
#crear o actualitzar objectes si toca
from django.db import transaction
from django.utils import timezone
import secrets
from pathlib import Path
from rest_framework import serializers
from django.contrib.auth.hashers import check_password,make_password
from .models import (Notificacio, Usuari, Empresa, Contrasenya, Verificacio, Obra, ObraEmpresa, Treballador, Empresa, Contrasenya,
    Permis, PermisTreballador, LogDeSessio, Configuracio, Ubicacio, Usuari, Verificacio,
    DocumentObra, Tasca, TascaTreballador, Incidencia, Solucio, Recurs, SolRecurs, ResponsableObra, ResponsableObra,ContracteTreballador,RegistreHorari
)
from .authentication.helpers import _is_contracte_vigent
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.exceptions import AuthenticationFailed
#Aquesta classee ara com ara tan sols prepara l'informacio per ser
# resnderitzada a json, pot ser canvii.

class ObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Obra
        fields = '__all__'  # Serializes all fields of the Obra model

class ObraRefSerializer(serializers.ModelSerializer):
    """Minimal Obra reference for nested responses"""
    class Meta:
        model = Obra
        fields = ['id', 'nom']

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = '__all__'

class TreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Treballador
        fields = '__all__'
class ContrasenyaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Contrasenya
        fields = '__all__'

class UbicacioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ubicacio
        fields = '__all__'

class PermisSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permis
        fields = '__all__'

class PermisTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = PermisTreballador
        fields = '__all__'

class PermisInfoSerializer(serializers.ModelSerializer):
    """Serialitza Permis amb clau_funcional i descripcio (llegit per AppCapabilities)."""
    class Meta:
        model = Permis
        fields = ['id', 'clau_funcional', 'descripcio']


class PermisTreballadorDetailSerializer(serializers.ModelSerializer):
    """
    Serialitza PermisTreballador amb el Permis anidat com `permis_info`.
    Estructura de sortida per a cada element:
    {
      "id": 1,
      "lectura": true,
      "escriptura": false,
      "edicio": false,
      "permis_info": { "id": 2, "clau_funcional": "tasques.completar", "descripcio": "..." }
    }
    """
    permis_info = PermisInfoSerializer(source='id_permis', read_only=True)

    class Meta:
        model = PermisTreballador
        fields = ['id', 'lectura', 'escriptura', 'edicio', 'permis_info']


class LogDeSessioSerializer(serializers.ModelSerializer):
    class Meta:
        model = LogDeSessio
        fields = '__all__'

class ConfiguracioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Configuracio
        fields = '__all__'

class VerificacioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Verificacio
        fields = '__all__'

class DocumentObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = DocumentObra
        fields = '__all__'

class DocumentObraUploadSerializer(serializers.ModelSerializer):
    MAX_FILE_SIZE_MB = 10

    ALLOWED_EXTENSIONS = {
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx',
        'xls',
        'xlsx',
    }

    class Meta:
        model = DocumentObra
        fields = [
            'id',
            'id_obra',
            'id_creador',
            'path_doc',
            'format',
            'mida',
            'comentari',
            'data_pujada',
            'tipus',
        ]
        read_only_fields = [
            'id',
            'id_creador',
            'format',
            'mida',
            'data_pujada',
        ]

    def validate_path_doc(self, uploaded_file):
        if uploaded_file is None:
            raise serializers.ValidationError(
                "Has d'adjuntar un fitxer."
            )

        size_mb = uploaded_file.size / (1024 * 1024)

        if size_mb > self.MAX_FILE_SIZE_MB:
            raise serializers.ValidationError(
                f"El fitxer supera el límit de {self.MAX_FILE_SIZE_MB} MB."
            )

        extension = Path(uploaded_file.name).suffix.lower().replace('.', '')

        if not extension:
            raise serializers.ValidationError(
                "El fitxer ha de tenir extensió."
            )

        if extension not in self.ALLOWED_EXTENSIONS:
            allowed = ', '.join(sorted(self.ALLOWED_EXTENSIONS))
            raise serializers.ValidationError(
                f"Format no permès. Formats admesos: {allowed}."
            )

        return uploaded_file

    def validate_tipus(self, value):
        value = (value or '').strip()

        if not value:
            raise serializers.ValidationError(
                "Has d'indicar el tipus de document."
            )

        if len(value) > 40:
            raise serializers.ValidationError(
                "El tipus no pot superar els 40 caràcters."
            )

        return value

class ContracteTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContracteTreballador
        fields = '__all__'  # Assuming you want to serialize all fields of the Contracte model      

class TascaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tasca
        fields = '__all__'

class TascaTreballadorSerializer(serializers.ModelSerializer):
    class Meta:
        model = TascaTreballador
        fields = '__all__'

class IncidenciaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Incidencia
        fields = '__all__'

class SolucioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Solucio
        fields = '__all__'

class RecursSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recurs
        fields = '__all__'

class RecursRefSerializer(serializers.ModelSerializer):
    """Minimal Recurs reference for nested responses"""
    class Meta:
        model = Recurs
        fields = ['id', 'nom', 'unitats_mesura', 'tipus_recurs']

class SolRecursSerializer(serializers.ModelSerializer):
    obra = ObraRefSerializer(source='id_obra', read_only=True)
    recurs = RecursRefSerializer(source='id_recurs', read_only=True)

    class Meta:
        model = SolRecurs
        fields = [
            'id',
            'id_obra',
            'obra',
            'id_empresa',
            'id_recurs',
            'recurs',
            'quantitat',
            'data_necessitat',
            'comentari',
            'data_entrega',
            'data_creacio',
            'proveidor',
            'id_treballador',
            'estat',
        ]
        read_only_fields = [
            'id',
            'id_empresa',
            'obra',
            'recurs',
        ]
        
class ResponsableObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = ResponsableObra
        fields = '__all__'

class ObraEmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ObraEmpresa
        fields = '__all__'

class RegistreHorariSerializer(serializers.ModelSerializer):
    class Meta:
        model = RegistreHorari
        fields = '__all__'
        read_only_fields = ['id']



class EmpresaRegisterSerializer(serializers.Serializer):
    nom_empresa = serializers.CharField(max_length=100)
    cif = serializers.CharField(max_length=20)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True, min_length=8)
    telefon = serializers.CharField(max_length=20, required=False, allow_blank=True, allow_null=True)
    persona_contacte = serializers.CharField(max_length=100, required=False, allow_blank=True, allow_null=True)
    sector = serializers.CharField(max_length=50, required=False, allow_blank=True, allow_null=True)

    def validate_email(self, value):
        email = value.strip().lower()
        if Usuari.objects.filter(loginField=email).exists():
            raise serializers.ValidationError("Ja existeix un usuari amb aquest correu.")
        return email

    def validate_cif(self, value):
        cif = value.strip().upper()
        if Empresa.objects.filter(cif=cif).exists():
            raise serializers.ValidationError("Ja existeix una empresa amb aquest CIF.")
        return cif

    def validate(self, attrs):
        if attrs["password"] != attrs["password_confirm"]:
            raise serializers.ValidationError({
                "password_confirm": "Les contrasenyes no coincideixen."
            })
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        password = validated_data.pop("password")
        validated_data.pop("password_confirm")

        email = validated_data["email"]
        token = secrets.token_urlsafe(32)
        now = timezone.now()

        user = Usuari.objects.create(
            username=email,
            loginField=email,
            email=email,
            tipus="empresa",
            is_active=True,
            password=make_password(password),
        )

        empresa = Empresa.objects.create(
            user=user,
            nom_empresa=validated_data["nom_empresa"],
            cif=validated_data["cif"],
            email=email,
            telefon=validated_data.get("telefon"),
            persona_contacte=validated_data.get("persona_contacte"),
            sector=validated_data.get("sector"),
            estat="activa",
        )

        Contrasenya.objects.create(
            id_empresa=empresa,
            clau=make_password(password),
            data_creacio=now,
        )

        Verificacio.objects.create(
            id_empresa=empresa,
            estat_ver="pendent",
            token_verificacio=token,
            data_token=now,
        )

        return {
            "empresa_id": empresa.id,
            "email": empresa.email,
            "requires_verification": True,
            "message": "Compte creat correctament. Revisa el correu de verificació.",
        }


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = "loginField"

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        token["tipus"] = user.tipus

        if user.tipus == "empresa":
            if not hasattr(user, "empresa"):
                raise AuthenticationFailed("L'usuari empresa no té perfil Empresa associat.")
            token["subject_id"] = user.empresa.id

        elif user.tipus == "treballador":
            if not hasattr(user, "treballador"):
                raise AuthenticationFailed("L'usuari treballador no té perfil Treballador associat.")
            token["subject_id"] = user.treballador.pk

        else:
            raise AuthenticationFailed("Tipus d'usuari no vàlid.")

        return token

    def validate(self, attrs):
        login_value = attrs.get("loginField")
        raw_password = attrs.get("password")

        if not login_value or not raw_password:
            raise AuthenticationFailed("Has d'indicar loginField i password.")

        try:
            user = Usuari.objects.get(loginField=login_value)
        except Usuari.DoesNotExist:
            raise AuthenticationFailed("Credencials incorrectes.")

        if not user.is_active:
            raise AuthenticationFailed("Aquest usuari està inactiu.")

        if user.tipus == "empresa":
            if not hasattr(user, "empresa"):
                raise AuthenticationFailed("L'usuari empresa no té perfil Empresa associat.")
            empresa = user.empresa

            pwd_obj = (
                Contrasenya.objects
                .filter(id_empresa=empresa, data_reemplas__isnull=True)
                .order_by("-data_creacio")
                .first()
            ) or (
                Contrasenya.objects
                .filter(id_empresa=empresa)
                .order_by("-data_creacio")
                .first()
            )

            if hasattr(empresa, "estat") and empresa.estat in ["inactiva", "suspesa"]:
                raise AuthenticationFailed("L'empresa no està activa.")

            subject_id = empresa.id

        elif user.tipus == "treballador":
            if not hasattr(user, "treballador"):
                raise AuthenticationFailed("L'usuari treballador no té perfil Treballador associat.")
            treballador = user.treballador

            pwd_obj = (
                Contrasenya.objects
                .filter(id_treballador=treballador, data_reemplas__isnull=True)
                .order_by("-data_creacio")
                .first()
            ) or (
                Contrasenya.objects
                .filter(id_treballador=treballador)
                .order_by("-data_creacio")
                .first()
            )

            contracte = (
                ContracteTreballador.objects
                .filter(id_treballador=treballador)
                .order_by("-data_contracte")
                .first()
            )

            if not _is_contracte_vigent(contracte):
                raise AuthenticationFailed("El treballador no té un contracte vigent.")

            subject_id = treballador.pk

        else:
            raise AuthenticationFailed("Tipus d'usuari no reconegut.")

        if not pwd_obj:
            raise AuthenticationFailed("Credencials incorrectes.")

        if not check_password(raw_password, pwd_obj.clau):
            raise AuthenticationFailed("Credencials incorrectes.")

        refresh = self.get_token(user)

        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
            "tipus": user.tipus,
            "subject_id": subject_id,
        }
    
class NotificacioSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Notificacio
        fields = [
            'id', 'tipus', 'titol', 'missatge',
            'llegida', 'data_creacio',
            'entitat_id', 'entitat_tipus',
        ]
        read_only_fields = ['id', 'tipus', 'titol', 'missatge', 'data_creacio',
                            'entitat_id', 'entitat_tipus']
