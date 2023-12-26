% #!/bin/octave-cli
% #!/mingw64/bin/octave-cli
% file: ruta a archivo 
% graficador simple a partir de un archivo 
% de coordenadas en 2D

	close all
	clc

	datos = dlmread("test_files/output.txt", ' ', 0, 0);

	plot(datos(:,1), 320-datos(:,2),".");
