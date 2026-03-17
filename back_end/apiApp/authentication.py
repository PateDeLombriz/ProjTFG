import jwt

from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.conf import settings

from .models import Empresa, Treballador


class JWTSubjectAuthentication(BaseAuthentication):
    """
    Autenticació pròpia basada en el JWT que ja genera el teu login.

    Aquesta classe:
    - llegeix l'header Authorization
    - comprova que tingui format 'Bearer <token>'
    - descodifica el token amb la SECRET_KEY del projecte
    - extreu el subjecte autenticat:
        * sub   -> id real del subjecte
        * tipus -> 'empresa' o 'treballador'
    - carrega l'objecte real de base de dades
    - retorna aquest objecte perquè quedi disponible a request.user
    - també deixa dades extra dins request.auth
    """

    def authenticate(self, request):
        """
        Aquest mètode s'executa automàticament quan una vista protegida
        rep una petició.

        Si no hi ha header Authorization, DRF considerarà que no hi ha
        usuari autenticat.
        """

        auth_header = request.headers.get("Authorization")

        # Si no s'envia cap Authorization, no autenticam.
        # No llançam error aquí perquè així DRF pot gestionar-ho
        # amb els permisos de la vista.
        if not auth_header:
            return None

        # Esperam exactament el format:
        # Authorization: Bearer <token>
        parts = auth_header.split()

        if len(parts) != 2 or parts[0].lower() != "bearer":
            raise exceptions.AuthenticationFailed(
                "Format d'autorització invàlid. Usa 'Bearer <token>'."
            )

        token = parts[1]

        try:
            # Descodificam el token amb la mateixa clau i algoritme
            # amb què el generes al login.
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=["HS256"],
            )
        except jwt.ExpiredSignatureError:
            raise exceptions.AuthenticationFailed("El token ha caducat.")
        except jwt.InvalidTokenError:
            raise exceptions.AuthenticationFailed("Token invàlid.")

        # Llegim els camps mínims que el teu login ja posa al JWT:
        # sub i tipus
        subject_id = payload.get("sub")
        subject_type = payload.get("tipus")

        if not subject_id or not subject_type:
            raise exceptions.AuthenticationFailed(
                "El token no conté la informació mínima requerida."
            )

        # Segons el tipus, cercam a la taula correcta
        if subject_type == "empresa":
            try:
                subject_obj = Empresa.objects.get(pk=subject_id)
            except Empresa.DoesNotExist:
                raise exceptions.AuthenticationFailed("L'empresa del token no existeix.")

        elif subject_type == "treballador":
            try:
                subject_obj = Treballador.objects.get(pk=subject_id)
            except Treballador.DoesNotExist:
                raise exceptions.AuthenticationFailed("El treballador del token no existeix.")

        else:
            raise exceptions.AuthenticationFailed("Tipus de subjecte desconegut.")

        # Guardam informació extra a request per facilitar les vistes futures.
        # DRF posarà:
        # - request.user = subject_obj
        # - request.auth = auth_info
        auth_info = {
            "token_payload": payload,
            "subject_id": subject_id,
            "tipus": subject_type,
        }

        return (subject_obj, auth_info)