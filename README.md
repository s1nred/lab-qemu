# lab.sh

Script sencillo para iniciar una maquina virtual en QEMU/libvirt usando `virsh`.

## Requisitos

- `virsh`
- permisos para ejecutar `sudo virsh`

## Uso

```bash
./lab.sh <nombre-vm>
```

Ejemplo:

```bash
./lab.sh kali-linux
```

## Ejecutarlo como `lab`

Si quieres usar el script desde cualquier parte del sistema, crea un enlace simbolico en un directorio incluido en tu `PATH`:

```bash
chmod +x lab.sh
sudo ln -s "$(pwd)/lab.sh" /usr/local/bin/lab
```

Luego podras ejecutarlo asi:

```bash
lab kali-linux
```

Para comprobar que quedo disponible:

```bash
which lab
```

## Que hace

- comprueba si la VM ya esta en ejecucion
- si no lo esta, intenta iniciarla
