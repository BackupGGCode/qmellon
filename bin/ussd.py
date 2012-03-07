#! /usr/bin/env python3
#coding: utf8
import time, io, sys

class Modem:
	p = None
	def __init__(self, dev='/dev/ttyACM0'):
		self.open(dev)

	def open(self, dev):
		#self.close()
		self.p = io.open(dev, 'w+b', 0)

	def write(self, s):
		self.p.write(str.encode(s) + b'\r\n')
		time.sleep(0.1)

	def close(self):
		self.p.close()

	def ussd(self, code):
		self.write('AT+CPBS="SM"')
		self.write('AT+CPMS="SM","SM",""')
		self.write('AT+ZSNT=0,0,2')
		self.write('AT+CUSD=1,' + code + ',15')

		for ln in self.p:
			if ln.startswith(b'+CUSD'):
				msg = ln[10:ln.rfind(b'"')].decode('ascii')
				return bytes.fromhex(msg).decode('utf-16-be')

	def query(self, code=sys.argv[1]):
		return self.ussd(code)

modem = Modem()
print(modem.query())