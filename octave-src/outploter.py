# graficador simple a partir de un archivo 
# de coordenadas en 2D
import re
import matplotlib.pyplot as plt
from sys import argv

datos = open("test_files/output.txt")

x = []
y = []

for linea in datos:
	x_aux = int(re.findall("\d+", linea)[0])
	y_aux = 320 - int(re.findall("\d+", linea)[1])
	if (x_aux < 340 and y_aux < 340):
		x.append(x_aux)
		y.append(y_aux)
	
fig, ax = plt.subplots()
ax.scatter(x, y, marker=".", s=2)
plt.show()
