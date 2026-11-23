# Auditoría pre-beta — Nova Hub Downloader v0.4

Fecha: 2026-10-06. Estado: solo se compiló `--debug`; sin instalador.

## Bloqueadores para beta

1. **Compilar y probar `--release`.** Todo lo probado hasta hoy es
   `--debug` (más lento, con asserts y símbolos). Nada sale sin un
   release verificado.
2. **Definir distribución.** El exe no corre solo: necesita sus DLLs y
   `data/` al lado. Beta = carpeta portable .zip completa o paquete
   MSIX. Hoy no existe ni uno ni otro.
3. **Icono y versión.** Sigue el icono Flutter por defecto y
   `pubspec.yaml` dice `0.1.0+1` mientras la app muestra v0.4.
   Cambiar icono y sincronizar versión.

## Importantes

4. **Sin tests ni CI.** `tool/` verifica a mano. Mínimo: `flutter test`
   del tagger ID3 y del parser YTM con fixtures.

## Menores

5. **Enriquecimiento en red lenta.** Con 15 filas se lanzan ~30
   procesos/solicitudes; el timeout de 30s puede dejar filas sin
   álbum. Aceptable, pero medirlo en condiciones reales.
6. **Docs de release.** Agregar sección de compilación release +
   contenido del .zip a distribuir.
