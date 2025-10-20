#!/usr/bin/env bash
set -euo pipefail
LC_ALL=C

#No soy desarrollador ni programador, así que estoy empezando de cero; si tu estás igual que yo, esto te puede ayudar. La información donde encontrar las estadísticas de tu PC están en una carpeta llamada /proc/stat. Así que hay que crear una función que saque toda la info de ahí. La información que tira son unas columnas de números. Esos números son HZ o ticks, en un segundo suelen haber 100 HZ y eso nos dice cuanto ha trabajado el servidor.
#Para tener claro como sacar el uso de CPU, tenemos que tomar dos samples de datos de /proc/stat (el que lleva desde que inició y el que lleva desde que inició + 1 segundo, esto para saber que hace en 1s). En cada uno de esos samples, aparecerá cuanto trabajó y cuanto estuvo en descanso (idle). La idea es restar lo que hizo 1s después con lo que llevaba desde el inicio, para saber qué hizo en ese segundo, incluyendo trabajo y descanso.
#Al tener la diferencia de los dos samples, le restaremos el tiempo idle, y así tendremos cuanto trabajo tuvo en ese segundo.

leer_cpu{
	#Con esto tomamos los primeros 8 datos que son los más importantes. user es para 
	read -r _ user nice system idle iowait irq softirq steal _ _ < /proc/stat
	#total=suma de todo
	total=$((user + nice + system + idle + iowait + irq + softirq + steal))
	#idletotal= tiempo sin trabajo real de la CPU
	idle_total=$((idle + iowait))
}


#sacamos los dos samples
read_cpu_snapshot
t1=$total
idle1=$idle_total

sleep 1

read_cpu_snapshot
t2=$total
idle2=$idle_total

#Sacamos las diferencias entre los samples
ds=$(( t2 - t1 )) #ticks totales transcurridos
didle=$(( idle2 - idle1 )) #ticks en descanso transcurrido

#Sacamos el porcentaje de uso = 1 - (idle/total)
usage=$(awk -v ds="$ds" -v di="$didle" 'BEGIN {
if (ds <= 0) { print "N/A"; exit }
	printf("%.2f", (1- di/ds) * 100)
}')

echo "Total CPU usage: $usage%"


