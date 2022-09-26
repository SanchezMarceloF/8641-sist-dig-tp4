close all
clear all
clc

datos = dlmread('../files/coordenadas.txt', '\t', 5, 0); 

N = 13;   %longitud del numero
M = 12;   %numero de decimales
N_ROWS = 11946;

for i=1 : N_ROWS 
  for j=0 : 2
    datos_ptofijo(i , (j*N+1):((j+1)*N)) = decimal_a_ptofijo(N, M, datos(i, j+1));
  endfor
endfor

%datos_ptofijo
dlmwrite('../files/coordenadas_ptofijo.txt', datos_ptofijo, "delimiter", "");%"newline", "");
