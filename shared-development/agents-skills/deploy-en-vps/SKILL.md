---
name: deploy-en-vps
description: Desplegar, publicar, actualizar, verificar o hacer rollback de aplicaciones y workers en el VPS N2C mediante CI/CD autónomo en cada repositorio, GitHub Actions, GHCR privado y Kamal rootless. Usar cuando el usuario mencione deploy, producción, VPS, N2C, servidor, Kamal o una release que debe ponerse en producción.
---

# Deploy en VPS con Kamal

## Contrato ordinario

Cada producto es dueño de su despliegue:

1. Un push a `main` ejecuta la CI existente.
2. Si pasa, el propio repositorio ejecuta `kamal deploy --version "$GITHUB_SHA"`.
3. La imagen se publica en el registry privado del repositorio.
4. Kamal activa esa versión y el workflow ejecuta un smoke corto.

`server-platform` fue retirado y eliminado. No buscarlo, recrearlo ni usarlo
como bootstrap, inventario, fuente de configuración o autoridad de despliegue.
Cada producto mantiene su release y cualquier operación global del host parte
de la configuración realmente instalada y deja un artefacto verificado dentro
del alcance autorizado; no se sincroniza con un repositorio central implícito.
Las imágenes activas de Umami y ntfy pueden conservar provenance OCI/SLSA
histórico con ese nombre: es metadato inmutable de build, no una dependencia ni
permiso para manipular el almacén Docker. El pilot y la clave SSH heredados de
aquella etapa fueron retirados el 2026-08-27.

## Mantenerlo corto

- Un workflow por producto.
- Reutilizar la CI que ya existe; no repetir tests en el job de deploy.
- Un job de deploy con `needs` sobre los gates existentes.
- Concurrency solo por servicio, con `cancel-in-progress: false`.
- Un script opcional únicamente cuando encapsule una diferencia real del servicio.
- Sin polling, cron de reconciliación, tags de coordinación, ramas de estado,
  registry local, reverse tunnels ni locks transversales.
- No introducir un repositorio reusable central en el camino de producción.

## Credenciales

Usar Actions Secrets o el environment `production` del propio repositorio:

- `KAMAL_HOST`
- `KAMAL_SSH_PRIVATE_KEY`
- `KAMAL_SSH_KNOWN_HOSTS`

Se admite temporalmente la misma identidad SSH restringida en varios repositorios.
No imprimir valores ni guardarlos en Git o artifacts. Usar `GITHUB_TOKEN` con
`packages: write` para publicar la imagen privada del repositorio en GHCR.

## Workflow mínimo

El job de deploy debe:

1. Comprobar que corre en un push a `main` y depende de la CI verde.
2. Hacer checkout del SHA exacto.
3. Instalar la versión fijada de Kamal.
4. Materializar SSH en `$RUNNER_TEMP` con modo `0600`.
5. Exponer el token del registry solo al proceso de Kamal.
6. Ejecutar `kamal deploy --version "$GITHUB_SHA"` con la configuración del producto.
7. Ejecutar un healthcheck o smoke breve y saneado.
8. Borrar las credenciales temporales en `always()`.

No volver a ejecutar lint, tests, build web o auditorías en el job de deploy si ya
son gates de CI. El build de imagen que ejecuta Kamal forma parte del despliegue.

## Seguridad y runtime

- Mantener Docker rootless y el usuario remoto restringido `kamal`.
- No usar root, `kamal setup`, rsync, PM2, Compose o `docker run` como segundo
  mecanismo ordinario.
- Conservar envs productivos en los archivos canónicos `0600` del host cuando ya
  estén allí.
- Aplicaciones web: usar el healthcheck y el cambio de tráfico de Kamal.
- Workers: conservar un solo scheduler y comprobar que queda activo después del
  despliegue.
- Migraciones destructivas o incompatibles se tratan como una operación separada.

## Fallos y rollback

- Si CI falla, no se ejecuta el deploy.
- Si Kamal falla antes de cambiar tráfico, la release anterior permanece activa.
- Si el smoke posterior falla, ejecutar `kamal rollback <version-anterior>` y
  volver a comprobar el smoke.
- Mantener al menos una release anterior disponible.
- Un fallo de un producto no debe bloquear los despliegues de los demás.

## Cierre

Informar únicamente:

- repositorio y SHA;
- run de GitHub Actions;
- CI verde;
- release activa y smoke;
- timer/worker singleton cuando aplique;
- rollback disponible o ejecutado.

No declarar éxito si el SHA esperado no está activo o el smoke no pasa.
