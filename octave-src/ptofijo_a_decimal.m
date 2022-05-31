%clear all
%close all
%clc
%

function RET = ptofijo_a_decimal (N, M, VAL)

  %N longitud total del numero
  %M numero de decimales
  %Vector con binarios en pto_fijo
  
  sum = 0;
  numero = VAL
  for i = 1 : N
    sum = sum + VAL(i)*(2**(-i+(N-M)));
  endfor
   
   RET = sum;
 
endfunction
%x = [0, 0,0,1,1,1,1,1,1,1,1,1,1,1];
%x(3)
%ptofijo_a_decimal(3, 11, x)