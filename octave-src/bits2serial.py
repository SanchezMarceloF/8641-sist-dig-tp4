import serial

ser = serial.Serial('/dev/ttyUSB0')  # open serial port
ser.baudrate = 19200
ser.bytesize = 8
ser.stopbits = 1
parity = 'N'
print(ser)


with open('../test_files/coordenadas_ptofijo-16.txt') as infile:
    for line in infile:
        print(f'line\t\t\t: {line[0:48]}, type : {type(line)}')
        # Initialize a binary string
        input_string=int(line[0:48], 2);
        #Convert these bits to bytes
        input_array = input_string.to_bytes(6, "big")
        print(f'input_array\t\t\t: {input_array}, type : {type(input_array)}')
        ser.write(input_array)
        
ser.close() 
