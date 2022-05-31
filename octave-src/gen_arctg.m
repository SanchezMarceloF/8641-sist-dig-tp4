clear all
close all
clc

%N = 5;
%M = 8;
%VAL = 26.565;


function RET = ptofijo_a_bin(N, M, VAL)
  %esta funcion convierte el numero flotante VAL en punto fijo.
  %con N digitos enteros y M digitos decimales.
  %retorna RET en binario
 
  x = floor(VAL); %entero
  y = VAL - x; %decimal
  
  res_int = dec2bin(x, N); 
  decimal = 0;

  for i = 1:M
    dif = y - (2^(-i));
    if (dif >= 0)
      decimal = bitor(decimal,bitshift(1,M-i,M));
      dec2bin(decimal,M);
      y = dif;
      j = i;
    endif
  endfor
  
  dec_sup = decimal+1;
  
  if((dec_sup-y)<(y-decimal))
    decimal=dec_sup;
  endif
  
  res_int;  
  res_dec = dec2bin(decimal,M);
  
  RET = dec2bin( bitor(bitshift(x,M,M+N),decimal),  M+N);
endfunction

for i = 0:15
  x1 = atan(2^(-i))*180/pi;
  printf("paso %i => ",i); 
  x2 = ptofijo_a_bin(6, 8, x1)
endfor