function ret = decimal_a_ptofijo (N, M, x)
%convierte un numero entre 0 y 1 en pto fijo con bit de signo y:

 %N longitud total del numero
 %M numero de decimales
 %x decimal a convertir
  
  if (x<0)
    y = x*(2^M)+2^(N);
  else  
    y = x*(2^M);
  endif

  ret = dec2bin(floor(y),N);
 
endfunction