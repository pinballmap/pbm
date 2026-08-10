<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | [日本語](./README_ja.md) | **Español**
<!-- hy-mt2-i18n:end -->

[![codecov](https://codecov.io/gh/pinballmap/pbm/branch/master/graph/badge.svg?token=Kgt4ffi0RK)](https://codecov.io/gh/pinballmap/pbm)

Licencia de código: [![Licencia: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

La licencia [GPL v3](LICENSE) se aplica al _código_ de este repositorio.

Licencia de los datos: [![Licencia: CC BY-SA 4.0](https://img.shields.io/badge/License-CC_BY--SA_4.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

Los _datos_ no se incluyen en este repositorio. En su lugar, se accede a ellos a través de la API pública. Estos datos están sujetos a una licencia [CC BY-SA](LICENSE-CC-BY-SA) (y no a GPL v3). Entre otras cosas, esta licencia exige hacer mención a su fuente al utilizarlos.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/P5P411XZAM)


¡Que disfrutes mucho jugando a pinball, amigo!

Este repositorio es la base de código de [pinballmap.com](https://pinballmap.com). El código de la aplicación móvil [Pinball Map se encuentra aquí](https://github.com/pinballmap/pbm-react). Si tienes algún problema con la aplicación, por favor utiliza ese repositorio.

## Documentación de la API

Disponible aquí: [http://pinballmap.com/api/v1/docs](http://pinballmap.com/api/v1/docs)

## Configuración del entorno de desarrollo

**Nota:** Si encuentras problemas, puedes contactarnos rápidamente [en Discord](https://discord.gg/zK6xjyYHJf).

### 1. Haz un fork en Github. Luego:
* `git clone https://github.com/{you}/pbm.git`
* `git remote add upstream git://github.com/pinballmap/pbm.git`

### 2. Instalar Ruby

* La [versión correcta de Ruby se puede encontrar aquí](https://github.com/pinballmap/pbm/blob/master/.ruby-version)

### 3. Instalar dependencias
* `gem install bundler`
* `bundle install`

#### Mac

* `brew update`

### 4. Instalar PostgreSQL

#### Linux

* Instalar el paquete postgresql

#### Mac

* Descargue [Postgres App](http://postgresapp.com/)
* `brew install postgresql`

### 5. Configuración de PostgreSQL

* `initdb /usr/local/var/postgres -E utf8`
* `createuser --interactive`
* `CREATEDB pbm_dev`
* `cp config/database.yml.example config/database.yml` para crear su archivo database.yml destinado al desarrollo
* `bin/rake db:create ; RAILS_ENV=test bin/rake db:create`
* `bin/rake db:migrate ; RAILS_ENV=test bin/rake db:migrate`

### 6. Descargar la base de datos de MaxMind
* Vaya a https://www.maxmind.com y cree una cuenta.
* En el menú de navegación, bajo “GeoIP / GeoLite”, haga clic en “Descargar archivos”.
* Busque “GeoLite City” y seleccione “Descargar GZIP”.
* Descomprímalo; aparecerá un archivo llamado GeoLite2-City.mmdb.
* Coloque ese archivo en la carpeta del proyecto, en la ubicación ‘tmp/GeoLite2-City.mmdb’.

### 7. Ejecutar el servidor de desarrollo
* `bin/rails s`

### 8. Ejecutar las pruebas
* `bundle exec rspec`

### 9. Ejecutar el servidor de depuración
* Iniciar el servidor: `bin/debug`
* Instalar las herramientas de línea de comandos de VSCode a través de la paleta de comandos. Desde el menú superior de VSCode: `View | Command Palette` y luego buscar: `Shell Command: Install 'code' command in path`
* Vincularse mediante el depurador de VSCode y establecer puntos de interrupción

### 10. Obtener un respaldo de la base de datos

Si el sitio se carga correctamente, será una versión vacía de pinballmap.com. Se puede obtener un respaldo de la base de datos desde [este repositorio](https://github.com/pinballmap/pbm-db-dump).

* `psql -U username -d pbm_dev < pbm_db_scrubbed.sql`
* `bin/rails create_developer_account` # crea un usuario: `example@example.com` con la contraseña `example`


## Configuración de Docker

_Aviso_: Ninguno de nosotros ha utilizado Docker desde que se configuró originalmente este proyecto. Por el momento no podemos garantizar la validez de los pasos que se indican a continuación. Si desea actualizar las instrucciones, hágalo por favor.

### Requisitos previos
* Docker >= v1.12.0+
* Docker-Compose (viene incluido con Docker para Mac; se debe instalar por separado en Linux)
* _Opcional_: [direnv](http://direnv.net/) o alguna otra forma de cargar variables de entorno para sobrescribir los puertos predeterminados en caso de conflicto

### Uso
#### Totalmente contenerizado
* Ejecute `docker-compose up -d` para iniciar los contenedores
* Acceda a `localhost:$PORT` (puede especificarse o usar el valor predeterminado `3000`)
* Detenga los contenedores con `docker-compose down`
  * Por defecto, la base de datos mantendrá su estado como un [volumen Docker](https://docs.docker.com/storage/volumes/). Si desea comenzar de cero, ejecute `docker-compose down -v` para eliminar el volumen. La próxima vez que ejecute este archivo docker-compose, las órdenes `db:create` y `db:migrate` volverán a poblado la base de datos.

#### Solo Postgres
Si solo desea ejecutar PostgreSQL en un contenedor y utilizar su sistema de archivos local para ejecutar Rails, puede usar el archivo de configuración de Docker-Compose exclusivo para Postgres.
* Ejecute `docker-compose -f docker-compose.postgres.yml up -d`
* Si es la primera vez que lo ejecuta, realice `bin/rake db:create db:migrate` para llenar el contenedor de PostgreSQL.
* Detenga los contenedores con `docker-compose -f docker-compose.postgres.yml down`
  * Por defecto, la base de datos mantendrá su estado como un [docker volume](https://docs.docker.com/storage/volumes/). Si desea comenzar de nuevo, ejecute `docker-compose -f docker-compose.postgres.yml down -v` para eliminar el volumen.
