from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apiApp.models import ContracteTreballador, Notificacio
from apiApp.authentication.helpers import crear_notificacio_empresa, crear_notificacio_treballador


class Command(BaseCommand):
    help = 'Crea notificacions per contractes que finalitzen properament.'

    def handle(self, *args, **kwargs):
        avui = timezone.now().date()
        limit = avui + timedelta(days=15)

        contractes = (
            ContracteTreballador.objects
            .filter(
                estat='actiu',
                data_fi__isnull=False,
                data_fi__gte=avui,
                data_fi__lte=limit,
            )
            .select_related('id_treballador', 'id_empresa')
        )

        creades = 0

        for c in contractes:
            existeix = Notificacio.objects.filter(
                tipus='contracte_finalitza_properament',
                entitat_tipus='contracte_treballador',
                entitat_id=c.id,
            ).exists()

            if existeix:
                continue

            crear_notificacio_empresa(
                c.id_empresa,
                'contracte_finalitza_properament',
                'Contracte proper a finalitzar',
                f'El contracte de {c.id_treballador.nom} {c.id_treballador.cognoms} finalitza el {c.data_fi}.',
                c.id,
                'contracte_treballador',
            )

            crear_notificacio_treballador(
                c.id_treballador,
                'contracte_finalitza_properament',
                'Contracte proper a finalitzar',
                f'El teu contracte finalitza el {c.data_fi}.',
                c.id,
                'contracte_treballador',
            )

            creades += 2

        self.stdout.write(
            self.style.SUCCESS(f'Notificacions creades: {creades}')
        )