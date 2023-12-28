function archivo_ptofijo(file, ROW, COL, N_ROWS, DECIM)
% file: ruta a archivo 
% ROW: numero de fila para comenzar a leer desde archivo
% COL: numero de fila para comenzar a leer desde archivo
% N_ROWS: numero de filas a leer del archivo
% DECIM: factor de decimación

	close all
	%clear all
	clc

	%datos = dlmread('../files/coordenadas.txt', '\t', 5, 0);
	datos = dlmread(file, '\t', ROW, COL);

	N = 16;   %longitud del numero
	M = 12;   %numero de decimales
	%N_ROWS = 11946;

	for i = 1:N_ROWS/DECIM
	for j=0 : 2
	  datos_ptofijo(i , (j*N+1):((j+1)*N)) = decimal_a_ptofijo(N, M, datos(i*DECIM, j+1));
	  datos_decimados(i, j+1) = datos(i*DECIM, j+1);
	endfor
	endfor
	% agregado del fin de archivo
	datos_ptofijo(N_ROWS/DECIM+1, 1:N*3) = dec2bin((2^(N*3))-1);
	
	% plot(datos_decimados(:,2), datos_decimados(:,3),".")
	
	% salida en punto fijo
	datos_ptofijo
	% salida en decimal
	% for i=1 : N_ROWS+1 
		% for j=0 : 2
			% result = bin2dec(num2str(datos_ptofijo(i , (j*N+1):((j+1)*N))));
			% printf("%i\t",result); 
		% endfor
		% printf("\n");
	% endfor

	% guarda en archivo
	filename =  file(1:length(file)-4);
	printf("output file: ");
  
	if (DECIM > 0)
		output = [filename "_ptofijoDEC" num2str(DECIM) "-16.txt"]
	else
		output = [filename "_ptofijo-16.txt"]
	endif
		
	dlmwrite(output,   datos_ptofijo, "delimiter", "");

endfunction
