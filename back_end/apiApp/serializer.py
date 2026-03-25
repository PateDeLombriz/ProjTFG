from rest_framework import serializers
from django.contrib.auth.hashers import check_password
from .models import (Obra, ObraEmpresa, Treballador, Empresa, Contrasenya,
 Permis, PermisTreballador, LogDeSessio, Configuracio, Ubicacio, Usuari, Verificacio,
    DocumentObra, Tasca, TascaTreballador, Incidencia, Solucio,
    Recurs, SolRecurs, ResponsableObra,   
    ResponsableObra,ContracteTreballador
)
from .authentication.helpers import _is_contracte_vigent
#Aquesta classee ara com ara tan sols prepara l'informacio per ser
# resnderitzada a json, pot ser canvii.

class ObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Obra
        fields = '__all__'  # Serializes all fields of the Obra model

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

class SolRecursSerializer(serializers.ModelSerializer):
    class Meta:
        model = SolRecurs
        fields = '__all__'

class ResponsableObraSerializer(serializers.ModelSerializer):
    class Meta:
        model = ResponsableObra
        fields = '__all__'

class ObraEmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ObraEmpresa
        fields = '__all__'


from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.exceptions import AuthenticationFailed

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