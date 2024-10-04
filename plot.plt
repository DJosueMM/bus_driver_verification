# Nombre del archivo con datos
set datafile separator ','

# Configurar la imagen de salida
set terminal png size 1280,729
set output 'histograma.png'

# Configurar etiquetas y título
set title "Histograma de Latencia"
set xlabel "Latencia"
set ylabel "Frecuencia"

# Configurar el estilo para crear un histograma
set style data histogram
set style fill solid 0.5 border -1

# Configurar el ancho de los bins para el histograma
ancho_bin = 500
bin(x,ancho) = ancho * floor(x / ancho) + ancho / 2.0


# Crear el histograma
plot '/mnt/vol_NFS_rh003/Est_Verif_II2024/MEDINILA_R/Proyecto1/bus_driver_verification/src/sim/' using (bin($5,ancho)):(1:0) smooth freq with boxes lc rgb "blue" title "Latencia"