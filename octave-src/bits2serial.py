import serial
import time

# ser = serial.Serial('/dev/ttyUSB0')  # open serial port linux
ser = serial.Serial('COM5')  # open serial port windows
ser.baudrate = 19200
ser.bytesize = 8
ser.stopbits = 1
parity = 'N'
print(ser)


with open('../test_files/coordenadas_ptofijo-16.txt') as infile:
#	with open('../test_files/coord_linea_ptofijo-16.txt') as infile:
    for line in infile:
        print(f'line\t\t: {line}, type : {type(line)}')
        # Initialize a binary string
        input_string=int(line[0:48], 2)
        print(f'input_string\t: {input_string}, type : {type(input_string)}')
        #Convert these bits to bytes
        input_array = input_string.to_bytes(6, "big")
        print(f'input_array\t: {input_array}, type : {type(input_array)}')
        ser.write(input_array)

time.sleep(2)
ser.close() 
