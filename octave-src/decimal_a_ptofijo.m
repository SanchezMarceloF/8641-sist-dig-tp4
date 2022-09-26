function ret = decimal_a_ptofijo (N, M, x)
%convierte un numero entre 0 y 1 en pto fijo con bit de signo y:

 %N longitud total del numero
 %M numero de decimales
 %x decimal a convertir
  
  if (x<0)
	% le sumo 2^N si es negativo porque dec2bin solo acepta numeros
    % positivos	
    y = -x*(2^M)+2^(M);
  else  
    y = x*(2^M);
  endif
  
  if (y >= (2**N))
	  y
      ret = dec2bin(0,N);
  else	  
      ret = dec2bin(floor(y),N);
  endif

endfunction
