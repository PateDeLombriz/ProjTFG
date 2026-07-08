"""
DEBUG DB ENVIRONMENT:
ENGINE: django.db.backends.postgresql
NAME: obraAgil
USER: dbuser
PASSWORD: dbpassword
HOST: db
PORT: 5432
"""
# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.conf import settings
from django.db import models
from django.utils import timezone
from django.db.models import Q
from django.contrib.auth.models import AbstractUser

#Per questions d'autentificacio de sessio es necessari crear aquest usuari
#No s'emplearà per la loginca de negoci
class Usuari(AbstractUser):
    TIPUS = (
        ('treballador', 'Treballador'),
        ('empresa', 'Empresa'),
    )
    tipus = models.CharField(max_length=20, choices=TIPUS, default=None, null=False)
    loginField=models.CharField(max_length=150, unique=True,db_column="login_field") #Aquest camp es el que s'utilitza per autenticar a l'usuari, pot ser el username o el email, segons el que es decideixi. Es necessari per a que funcioni simplejwt

    USERNAME_FIELD = 'loginField' #Indica a Django que aquest es el camp que s'utilitza per autenticar a l'usuari, en lloc del username per defecte
    #Aquesta contraitn obliga a que tan sols un dels 2 camps de FK sigui no null, es a dir, que un usuari sigui o treballador o empresa, pero no els dos alhora.
    class Meta:
        managed = True
        db_table = 'usuari'
#
#class DjangoAdminLog(models.Model):
#    action_time = models.DateTimeField()
#    object_id = models.TextField(blank=True, null=True)
#    object_repr = models.CharField(max_length=200)
#    action_flag = models.SmallIntegerField()
#    change_message = models.TextField()
#    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
#    user = models.ForeignKey(Usuari, models.DO_NOTHING)
#
#    class Meta:
#        managed = True
#        db_table = 'django_admin_log'
#
#
#class DjangoContentType(models.Model):
#    app_label = models.CharField(max_length=100)
#    model = models.CharField(max_length=100)
#
#    class Meta:
#        managed = True
#        db_table = 'django_content_type'
#        unique_together = (('app_label', 'model'),)
#
#
#class DjangoMigrations(models.Model):
#    id = models.BigAutoField(primary_key=True)
#    app = models.CharField(max_length=255)
#    name = models.CharField(max_length=255)
#    applied = models.DateTimeField()
#
#    class Meta:
#        managed = True
#        db_table = 'django_migrations'
#
#
#class DjangoSession(models.Model):
#    session_key = models.CharField(primary_key=True, max_length=40)
#    session_data = models.TextField()
#    expire_date = models.DateTimeField()
#
#    class Meta:
#        managed = True
#        db_table = 'django_session'

class Ubicacio(models.Model):
    id_ubicacio = models.AutoField(db_column='id_ubicacio', primary_key=True)
    adreca = models.CharField(max_length=150, blank=True, null=True, db_column='adreça')
    ciutat = models.CharField(max_length=50, blank=True, null=True)
    codi_postal = models.CharField(max_length=10, blank=True, null=True)
    provincia = models.CharField(max_length=50, blank=True, null=True)
    pais = models.CharField(max_length=50, default='Espanya', db_column='país')
    latitud = models.DecimalField(max_digits=10, decimal_places=7, blank=True, null=True)
    longitud = models.DecimalField(max_digits=11, decimal_places=7, blank=True, null=True)
    
    def __str__(self):
        parts = filter(None, [self.adreca, self.ciutat, self.provincia])
        return ', '.join(parts)

    class Meta:
        managed = True
        db_table = 'ubicacio'

class Obra(models.Model):
    id = models.AutoField(db_column='id', primary_key=True)  # Field name made lowercase.
    nom = models.CharField(db_column='nom', max_length=100)  # Field name made lowercase.
    ubicacio = models.ForeignKey(Ubicacio, on_delete=models.CASCADE, null=False, blank=False, db_column='ubicacio_id', db_index=True, related_name='obres')
    data_inici = models.DateField(db_column='data_inici')  # Field name made lowercase.
    data_prev_fi = models.DateField(db_column='data_prev_fi')  # Field name made lowercase.
    data_fi = models.DateField(db_column='data_fi', blank=True, null=True)
    pressupost = models.BigIntegerField(db_column='pressupost')  # Field name made lowercase.
    descripcio = models.TextField(db_column='descripcio', blank=True, null=True)  # Field name made lowercase.
    estat = models.CharField(db_column='estat', max_length=50)  # Field name made lowercase.
    
    
    class Meta:
        #Indica que Django gestionarà/no gestionarà la creación, modificación o eliminación de aquesta taula.
        # si makemigration i migrate tambe deixen de funcionar
        managed = True  
        db_table = 'obra'


class Empresa(models.Model):

    ESTAT_EMPRESA = [
        ('activa', 'Activa'),
        ('inactiva', 'Inactiva'),
        ('suspesa', 'Suspesa'),
    ]
    # CANVIA/AFEGEIX el camp PK:
    id = models.AutoField(db_column='id_empresa', primary_key=True)
    nom_empresa = models.CharField(max_length=100)
    cif = models.CharField(max_length=20, unique=True)  
    ubicacio = models.ForeignKey(Ubicacio, on_delete=models.SET_NULL, null=True, blank=True, db_column='ubicacio_id', db_index=True, related_name='empreses')
    telefon = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(max_length=100, blank=True, null=True)
    web = models.URLField(max_length=100, blank=True, null=True)
    sector = models.CharField(max_length=50, blank=True, null=True)
    data_alta = models.DateField(auto_now_add=True)
    estat = models.CharField(max_length=20, choices=ESTAT_EMPRESA, default='activa')
    persona_contacte = models.CharField(max_length=100, blank=True, null=True)
    comentaris = models.TextField(blank=True, null=True)

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='empresa',
        )
    def __str__(self):
        return self.nom_empresa
    
    class Meta:
        managed = True
        db_table = 'empresa'

    
class ObraEmpresa(models.Model):
    id = models.AutoField(primary_key=True)
    id_empresa = models.ForeignKey(
        'Empresa',
        on_delete=models.CASCADE,
        db_column='id_empresa',
        related_name='relacions_obra'
    )
    id_obra = models.ForeignKey(
        'Obra',
        on_delete=models.CASCADE,
        db_column='id_obra',
        related_name='relacions_empresa'
    )
    data_i = models.DateTimeField()
    data_f = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'obra_empresa'

class Treballador(models.Model):
    id = models.AutoField(db_column='id', primary_key=True)
    nom = models.CharField(max_length=50)
    cognoms = models.CharField(max_length=100)
    #id_empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, db_column='id_empresa', blank=False, null=False)    
    nickname = models.CharField(max_length=100, blank=True, null=True)
    dni_nie_passaport = models.CharField(max_length=20, unique=True)
    data_naixement = models.DateField(blank=True, null=True)
    telefon = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(max_length=100, blank=True, null=True)
    foto = models.ImageField(upload_to='fotos_treballadors/', blank=True, null=True)#La imatge queda gardada dins un fitxer delno dins la BD
    comentaris = models.TextField(blank=True, null=True)
    #Necessari per a que funcioni simplejwt, ja que aquest necessita un usuari per autenticar, i en aquest cas el nostre usuari es el treballador, per tant el FK a Usuari es necessari per a que funcioni simplejwt
    user =models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='treballador',)


    def __str__(self):
        return f"{self.nom} {self.cognoms}"
    
    class Meta:
        managed  = True          #  Django no l’ha de crear
        db_table = 'treballador'  #  nom real a PostgreSQL
    
class ContracteTreballador(models.Model):
    ESTAT_TREBALLADOR_CHOICES = [
        ('actiu', 'Actiu'),
        ('baixa', 'Baixa'),
        ('acomiadat', 'Acomiadat'),
    ]

    id = models.AutoField(primary_key=True)
    id_treballador = models.ForeignKey(Treballador, on_delete=models.RESTRICT,null=False, db_column='id_treballador')
    id_empresa = models.ForeignKey(Empresa, on_delete=models.RESTRICT, null=False, db_column='id_empresa')  # ⚠ si mantens NOT NULL a SQL, canvia a CASCADE o treu NOT NULL a SQL
    data_contracte = models.DateField(blank=True, null=True)
    data_fi = models.DateField(blank=True, null=True)
    salari = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    carrec = models.CharField(max_length=50, blank=True, null=True)
    categoria_professional = models.CharField(max_length=50, blank=True, null=True)
    nss = models.CharField(max_length=20, blank=True, null=True)
    formacions = models.TextField(blank=True, null=True)
    estat = models.CharField(max_length=20, choices=ESTAT_TREBALLADOR_CHOICES, default='actiu')

    class Meta:
        managed = True
        db_table = 'contracte_treballador'
        unique_together = (('id_treballador', 'data_contracte'),)


class Configuracio(models.Model):
    id = models.AutoField(primary_key=True)
    id_empresa = models.ForeignKey(Empresa, models.CASCADE, db_column='id_empresa', blank=True, null=True)
    id_treballador = models.ForeignKey(Treballador, models.CASCADE, db_column='id_treballador', blank=True, null=True)
    idioma = models.CharField(max_length=10, blank=True, null=True, default='ca')
    acceptacio_terms = models.BooleanField(default=False)
    imatge_perfil = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'configuracio'
        constraints = [
            models.CheckConstraint(
                name='chk_cfg_subjecte',
                check=(Q(id_treballador__isnull=False) ^ Q(id_empresa__isnull=False))
            ),
            models.UniqueConstraint(
                name='ux_cfg_treballador_one',
                fields=['id_treballador'],
                condition=Q(id_treballador__isnull=False),
            ),
            models.UniqueConstraint(
                name='ux_cfg_empresa_one',
                fields=['id_empresa'],
                condition=Q(id_empresa__isnull=False),
            ),
        ]

class Contrasenya(models.Model):
    id = models.AutoField(db_column='id', primary_key=True)
    id_treballador = models.ForeignKey(Treballador, models.CASCADE, db_column='id_treballador', blank=True, null=True)
    id_empresa = models.ForeignKey(Empresa, models.CASCADE, db_column='id_empresa', blank=True, null=True)
    clau = models.CharField(max_length=255)
    data_creacio = models.DateTimeField(default=timezone.now)
    data_reemplas = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'contrasenya'
        constraints = [
            models.CheckConstraint(
                name='chk_un_fk',
                check=(
                    (Q(id_treballador__isnull=False) & Q(id_empresa__isnull=True)) |
                    (Q(id_treballador__isnull=True) & Q(id_empresa__isnull=False))
                )
            )
        ]
        indexes = [
            models.Index(
                name='idx_pwd_e_vigent',
                fields=['id_empresa'],
                condition=Q(data_reemplas__isnull=True),
            ),
            models.Index(
                name='idx_pwd_t_vigent',
                fields=['id_treballador'],
                condition=Q(data_reemplas__isnull=True),
            ),
        ]


    """
    Organitza els documents per obra.

    Exemple:
    media/documents_obra/obra_12/contracte.pdf
    """
def document_obra_upload_path(instance, filename):
    
    obra_id = instance.id_obra_id or 'sense_obra'
    return f'documents_obra/obra_{obra_id}/{filename}'


class DocumentObra(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, related_name= 'documents', db_column='id_obra')
    id_creador = models.IntegerField( blank=False, null=False)  # Assuming this is a username or similar identifier
    path_doc = models.FileField(upload_to=document_obra_upload_path, db_column='path_doc',max_length=255, null=False)  # Path to the file in the server
    format = models.CharField(max_length=40)
    mida = models.DecimalField(max_digits=6, decimal_places=2)  # Assuming size in MB
    comentari = models.TextField(blank=True, null=True)
    data_pujada = models.DateTimeField(auto_now_add=True)
    tipus = models.CharField(max_length=40)
    #Ubicacio del fitxer potser sigui necesssari
    class Meta:
        managed = True
        db_table = 'document_obra'

    def __str__(self):
        return f'Document {self.id} - Obra {self.id_obra_id} - {self.path_doc.name}'

class Incidencia(models.Model):
    id = models.AutoField(primary_key=True) 
    id_obra = models.ForeignKey('Obra', models.CASCADE, related_name='incidencies', db_column='id_obra')
    id_tasca = models.ForeignKey('Tasca', models.SET_NULL, db_column='id_tasca', blank=True, null=True)
    descripcio = models.TextField()
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)
    criticitat = models.IntegerField()
    prioritat = models.IntegerField()
    categoria = models.IntegerField() #canviar categoria a CharField si es volen categories textuals
    estat = models.CharField(max_length=40)

    class Meta:
        managed = True
        db_table = 'incidencia'


class LogDeSessio(models.Model):
    id = models.AutoField(primary_key=True)
    id_treballador = models.ForeignKey('Treballador', models.SET_NULL, db_column='id_treballador', blank=True, null=True)
    id_empresa = models.ForeignKey('Empresa', models.SET_NULL, db_column='id_empresa', blank=True, null=True)
    data_inici = models.DateField()
    hora_inici = models.TimeField()

    class Meta:
        managed = True
        db_table = 'log_de_sessio'
        constraints = [
            models.CheckConstraint(
                name='chk_log_subjecte',
                check=(Q(id_treballador__isnull=False) ^ Q(id_empresa__isnull=False))
            )
        ]

class Permis(models.Model):
    id = models.AutoField(primary_key=True) 
    clau_funcional = models.CharField(unique=True, max_length=100)
    descripcio = models.CharField(max_length=255)

    class Meta:
        managed = True
        db_table = 'permis'


class PermisTreballador(models.Model):
    id = models.AutoField(primary_key=True) 
    id_treballador = models.ForeignKey(Treballador, models.CASCADE, db_column='id_treballador')
    id_permis = models.ForeignKey(Permis, models.RESTRICT, db_column='id_permis')
    lectura = models.BooleanField(default= False)
    escriptura = models.BooleanField(default= False)
    edicio = models.BooleanField(default= False)
    data_creacio = models.DateTimeField(default=timezone.now)
    data_modif = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'permis_treballador'


class Recurs(models.Model):
    id = models.AutoField(primary_key=True) 
    nom = models.CharField(max_length=120)
    unitats_mesura = models.CharField(max_length=40)
    quantitat_stock = models.DecimalField(max_digits=8, decimal_places=2)
    tipus_recurs = models.CharField(max_length=60)

    class Meta:
        managed = True
        db_table = 'recurs'


class ResponsableObra(models.Model):
    id = models.AutoField(primary_key=True)
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, db_column='id_obra')
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='id_treballador')
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'responsable_obra'


#Solicitud de recurs per a una obra, pot ser per a una tasca concreta o no, i pot ser per a una incidencia concreta o no. Pot tenir un comentari i una data de necessitat, i opcionalment una data d'entrega i un proveïdor associat.
class SolRecurs(models.Model):

    ESTAT_SOL_RECURS = [
        ('pendent', 'Pendent'),
        ('aprovada', 'Aprovada'),
        ('rebutjada', 'Rebutjada'),
    ]

    id = models.AutoField(primary_key=True)
    id_empresa = models.ForeignKey(
        Empresa,
        on_delete=models.CASCADE,
        db_column='id_empresa',
        related_name='sol_necessitats',
    )
    id_obra = models.ForeignKey(Obra, models.DO_NOTHING, db_column='id_obra')
    id_recurs = models.ForeignKey(Recurs, models.DO_NOTHING, db_column='id_recurs')
    quantitat = models.IntegerField()
    data_necessitat = models.DateField()
    comentari = models.TextField(blank=True, null=True)
    data_entrega = models.DateField(blank=True, null=True)
    data_creacio = models.DateTimeField()
    proveidor = models.CharField(max_length=120, blank=True, null=True)
    id_treballador =models.ForeignKey(Treballador, models.DO_NOTHING, null= True, blank=True, db_column='id_treballador')
    estat=models.CharField(max_length=40, choices=ESTAT_SOL_RECURS, default='pendent')
    
    class Meta:
        managed = True
        db_table = 'sol_recurs'


class Solucio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_incidencia = models.ForeignKey(Incidencia, models.CASCADE, db_column='id_incidencia')
    id_tasca = models.ForeignKey('Tasca', models.DO_NOTHING, db_column='id_tasca', blank=True, null=True)
    descripcio = models.TextField()
    cost_monetari = models.BigIntegerField()
    eficacia = models.IntegerField()
    cost_temporal = models.IntegerField()
    impacte = models.IntegerField()

    class Meta:
        managed = True
        db_table = 'solucio'



class Tasca(models.Model):
    ESTAT_TASCA = [
        ('en_curs', 'En curs'),
        ('pendent_revisio', 'Pendent de revisió'),
        ('cancelada', 'Cancel·lada'),
        ('aprovada', 'Aprovada'),
        ('finalitzada', 'Finalitzada'),
    ]

    id = models.AutoField(primary_key=True)
    id_obra = models.ForeignKey(Obra, models.CASCADE, related_name='tasques', db_column='id_obra')
    id_tasca_pare = models.ForeignKey('self', models.SET_NULL, db_column='id_tasca_pare', blank=True, null=True)
    descripcio = models.TextField()
    data_inici = models.DateField()
    data_fi = models.DateField(blank=True, null=True)
    prioritat = models.IntegerField()
    visibilitat_tasca = models.BooleanField(default=True)
    estat = models.CharField(
        max_length=40,
        choices=ESTAT_TASCA,
        default='pendent_revisio',
    )

    class Meta:
        managed = True
        db_table = 'tasca'


class TascaTreballador(models.Model):
    id = models.AutoField(primary_key=True)
    id_tasca = models.ForeignKey(Tasca, models.CASCADE, db_column='id_tasca')
    id_treballador = models.ForeignKey(Treballador, models.DO_NOTHING, db_column='id_treballador')
    comentari = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'tasca_treballador'
        unique_together = (('id_tasca', 'id_treballador'),)


class RegistreHorari(models.Model):
    id = models.AutoField(primary_key=True)
    id_treballador = models.ForeignKey(
        'Treballador',
        on_delete=models.CASCADE,
        db_column='id_treballador',
    )
    id_obra = models.ForeignKey(
        'Obra',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='id_obra',
    )
    data_entrada = models.DateTimeField()
    data_sortida = models.DateTimeField(null=True, blank=True)

    class Meta:
        managed = True
        db_table = 'registre_horari'


class Verificacio(models.Model):
    id = models.AutoField(primary_key=True) 
    id_empresa = models.ForeignKey(Empresa, models.CASCADE, db_column='id_empresa')
    estat_ver = models.CharField(max_length=40)
    data_ver = models.DateField(blank=True, null=True)
    token_verificacio = models.CharField(max_length=120)
    data_token = models.DateTimeField()

    class Meta:
        managed = True
        db_table = 'verificacio'



class Notificacio(models.Model):
    TIPUS_CHOICES = [
        ('nova_tasca', 'Nova tasca'),
        ('tasca_actualitzada', 'Tasca actualitzada'),
        ('tasca_cancelada', 'Tasca cancel·lada'),
        ('tasca_finalitzada', 'Tasca finalitzada'),
        ('tasca_validada', 'Tasca validada'),
        ('tasca_rebutjada', 'Tasca rebutjada'),

        ('sol_recurs_creada', 'Sol·licitud de recurs creada'),
        ('sol_recurs_assignada', 'Sol·licitud de recurs assignada'),
        ('sol_recurs_aprovada', 'Sol·licitud de recurs aprovada'),
        ('sol_recurs_rebutjada', 'Sol·licitud de recurs rebutjada'),
        ('recurs_entrega_propera', 'Entrega de recurs propera'),

        ('nova_incidencia', 'Nova incidència'),
        ('incidencia_actualitzada', 'Incidència actualitzada'),
        ('incidencia_tancada', 'Incidència tancada'),

        ('nova_obra_assignada', 'Nova obra assignada'),
        ('responsable_obra_assignat', 'Responsable d’obra assignat'),
        ('document_pujat', 'Document pujat'),

        ('sortida_pendent', 'Sortida pendent'),
        ('contracte_finalitza_properament', 'Contracte finalitza properament'),
    ]

    id              = models.AutoField(primary_key=True)
    id_treballador  = models.ForeignKey(
        'Treballador', on_delete=models.CASCADE,
        null=True, blank=True, db_column='id_treballador',
        related_name='notificacions',
    )
    id_empresa      = models.ForeignKey(
        'Empresa', on_delete=models.CASCADE,
        null=True, blank=True, db_column='id_empresa',
        related_name='notificacions',
    )
    tipus           = models.CharField(max_length=40, choices=TIPUS_CHOICES)
    titol           = models.CharField(max_length=120)
    missatge        = models.TextField(blank=True, default='')
    llegida         = models.BooleanField(default=False)
    data_creacio    = models.DateTimeField(auto_now_add=True)
    # Referència genèrica a l'entitat que ha generat la notificació
    entitat_id      = models.IntegerField(null=True, blank=True)
    entitat_tipus   = models.CharField(max_length=40, null=True, blank=True)

    class Meta:
        managed = True
        db_table = 'notificacio'
        ordering = ['-data_creacio']
        constraints = [
            models.CheckConstraint(
                name='chk_notif_subjecte',
                check=(
                    Q(id_treballador__isnull=False, id_empresa__isnull=True) |
                    Q(id_treballador__isnull=True,  id_empresa__isnull=False)
                ),
            )
        ]