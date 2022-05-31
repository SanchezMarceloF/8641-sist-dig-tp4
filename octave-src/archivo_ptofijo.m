close all
clear all
clc

datos = dlmread('coordenadas.txt', '\t', 5, 0); 

%res0 = valores_medios (datos(1:end,3), datos(1:end,4), datos(1:end,2));
M = 13;   %longitud del numero
N = 11;   %numero de decimales

for i=1 : 11946
  for j=0 : 2
    datos_ptofijo(i , (j*M+1+j):((j+1)*M)+j) = decimal_a_ptofijo(M, N, datos(i, j+1));
  endfor
endfor
 
dlmwrite('coordenadas_ptofijo.txt', datos_ptofijo);