from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from apiApp.models import SolRecurs, Notificacio
from back_end.apiApp.authentication.helpers import crear_notificacio_empresa, empreses_obra, empreses_obra

class Command(BaseCommand):
    def handle(self, *args, **kwargs):
        avui = timezone.now().date()
        limit = avui + timedelta(days=2)

        qs = SolRecurs.objects.filter(
            data_entrega__isnull=False,
            data_entrega__gte=avui,
            data_entrega__lte=limit,
        ).select_related('id_recurs', 'id_obra')

        for sol in qs:
            existeix = Notificacio.objects.filter(
                tipus='recurs_entrega_propera',
                entitat_tipus='sol_recurs',
                entitat_id=sol.id,
            ).exists()

            if existeix:
                continue

            for empresa in empreses_obra(sol.id_obra):
                crear_notificacio_empresa(
                    empresa,
                    'recurs_entrega_propera',
                    'Entrega de recurs propera',
                    f'L’entrega de {sol.id_recurs.nom} està prevista per {sol.data_entrega}.',
                    sol.id,
                    'sol_recurs',
                )


    