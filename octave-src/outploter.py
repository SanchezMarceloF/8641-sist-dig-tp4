# graficador simple a partir de un archivo 
# de coordenadas en 2D
import re
import matplotlib.pyplot as plt
from sys import argv

datos = open("test_files/output.txt")

x = []
y = []

for linea in datos:
	x.append(int(re.findall("\d+", linea)[0]))
	y.append(320 - int(re.findall("\d+", linea)[1]))
	
fig, ax = plt.subplots()
ax.scatter(x, y, marker=".", s=2)
plt.show()
