# Envío aprobado con Himalaya 2.1

Leer este procedimiento antes de enviar o reintentar un envío. No sustituye
la aprobación explícita del mensaje concreto por el usuario.

## Preparación

Crear un RFC 5322 temporal con permisos `0600`, usando un serializador MIME
para Unicode y adjuntos. Conservar el contenido aprobado. Validar las
direcciones y cabeceras, exactamente un From, un Subject no vacío, al menos
un To y un cuerpo no vacío; mantener los límites del entorno anterior de
25 destinatarios totales y 10 MiB por mensaje. Rechazar cabeceras duplicadas
ambiguas, defectos MIME y NUL. No añadir destinatarios ni adjuntos no aprobados.

Incluir Date y un Message-ID único y conservar ese ID durante toda la
operación: sirve para comprobar resultados y evitar reenvíos duplicados.
Para respuestas, conservar In-Reply-To y References del mensaje original.

Separar el sobre SMTP de las cabeceras MIME: pasar **todos y solo** los To,
CC y BCC aprobados como destinatarios del sobre, y quitar Bcc/Resent-Bcc del
RFC transmitido. `smtp send` transmite el RFC proporcionado; no confiar en que
elimine cabeceras privadas. Los BCC siguen figurando en la aprobación y en
los argumentos `--rcpt-to`, nunca en las cabeceras visibles al destinatario.

## Enviar una sola vez

Ejemplo de forma del comando; usar las direcciones y el archivo aprobados:

```bash
himalaya --json smtp send \
  --mail-from remitente@example.com \
  --rcpt-to destinatario@example.com \
  < /tmp/respuesta-aprobada.eml
```

Repetir `--rcpt-to` por cada destinatario aprobado. Mostrar el mensaje para
aprobación antes de ejecutar, no imprimir la contraseña ni activar logs de
protocolo. El código de salida de SMTP confirma aceptación del servidor,
no entrega final al destinatario.

No usar `message send --save sent` ni `message add --send` en este flujo:
en 2.1 guardan la copia **antes** de enviar, por lo que una entrada en Sent
no demostraría que SMTP haya aceptado el mensaje.

## Verificar y conservar la copia

Buscar el Message-ID en Sent sin leer cuerpos ajenos:

```bash
himalaya --json imap search --mailbox 'Sent Messages' --text '<MESSAGE-ID>'
```

Confirmar el Message-ID exacto en las cabeceras de los UID encontrados con
`imap fetch --envelope`. La búsqueda de texto puede devolver coincidencias
adicionales; no basta por sí sola para identificar la copia.

Después de éxito SMTP, si iCloud ya guardó la copia, no duplicarla. Si no
aparece tras una comprobación posterior breve, guardarla explícitamente:

```bash
himalaya --json message add --mailbox sent --flag seen < /tmp/respuesta-aprobada.eml
```

Verificar esa copia, sus destinatarios visibles, asunto y Message-ID, y
eliminar el temporal cuando la operación esté resuelta.

Si SMTP devuelve un error ambiguo, comprobar Sent y **no reenviar
automáticamente**: la ausencia de una copia tampoco demuestra fallo de envío.
Informar de la incertidumbre y pedir una decisión antes de un nuevo intento.
Si SMTP fue aceptado pero falla guardar la copia, resolver solo el guardado;
nunca repetir SMTP. No presentar un envío de prueba como autorizado por una
petición de configuración o migración.
