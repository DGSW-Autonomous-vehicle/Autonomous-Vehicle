# This veENBion uses new-style automatic setup/destroy/mapping
# Need to change /etc/webiopi

# Imports
import webiopi
import RPi.GPIO as GPIO
import time
from PCA9685 import PCA9685

# -------------------------------------------------- #
# Constants definition                               #
# -------------------------------------------------- #

# Left motor GPIOs
IN1=13 # H-Bridge 1
IN2=12 # H-Bridge 2
ENA=6 # H-Bridge 1,2EN

# Right motor GPIOs
IN3=21 # H-Bridge 3
IN4=20 # H-Bridge 4
ENB=26 # H-Bridge 3,4EN

# motor PWM value
PA = 50
PB = 50

# Servo channel
Servo1_channel=1
Servo2_channel=0
    
# Setup GPIOs
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(ENA, GPIO.OUT)
GPIO.setup(IN1, GPIO.OUT)
GPIO.setup(IN2, GPIO.OUT)
    
GPIO.setup(ENB, GPIO.OUT)
GPIO.setup(IN3, GPIO.OUT)
GPIO.setup(IN4, GPIO.OUT)

# set software PWM 
PWMA  = GPIO.PWM(ENA,500)
PWMA.start(PA)
PWMB  = GPIO.PWM(ENB,500)
PWMB.start(PB)

#set PCA9685 
pwm = PCA9685(0x40)
pwm.setPWMFreq(50)
pwm.setServoPulse(Servo1_channel,1500)
pwm.setServoPulse(Servo2_channel,1500)

# -------------------------------------------------- #
# Macro definition part                              #
# -------------------------------------------------- #
@webiopi.macro
def set_speed(speed):
	PA = float(speed)
	PB = float(speed)
	PWMA.ChangeDutyCycle(PA)
	PWMB.ChangeDutyCycle(PB)

@webiopi.macro
def set_servo1(pulse):
	"Sets the Servo Pulse"
	print(pulse)
	pwm.setServoPulse(Servo1_channel,3000 - float(pulse))

@webiopi.macro
def set_servo2(pulse):
	"Sets the Servo Pulse"
	print(pulse)
	pwm.setServoPulse(Servo2_channel,3000 - float(pulse))


@webiopi.macro
def go_forward():
	PWMA.ChangeDutyCycle(PA)
	PWMB.ChangeDutyCycle(PB)
	GPIO.output(IN1, GPIO.HIGH)
	GPIO.output(IN2, GPIO.LOW)
	GPIO.output(IN3, GPIO.HIGH)
	GPIO.output(IN4, GPIO.LOW)

@webiopi.macro
def go_backward():
	PWMA.ChangeDutyCycle(PA)
	PWMB.ChangeDutyCycle(PB)
	GPIO.output(IN1, GPIO.LOW)
	GPIO.output(IN2, GPIO.HIGH)
	GPIO.output(IN3, GPIO.LOW)
	GPIO.output(IN4, GPIO.HIGH)

@webiopi.macro
def turn_left():
	PWMA.ChangeDutyCycle(25)
	PWMB.ChangeDutyCycle(25)
	GPIO.output(IN1, GPIO.LOW)
	GPIO.output(IN2, GPIO.HIGH)
	GPIO.output(IN3, GPIO.HIGH)
	GPIO.output(IN4, GPIO.LOW)
	
@webiopi.macro
def turn_right():
	PWMA.ChangeDutyCycle(25)
	PWMB.ChangeDutyCycle(25)
	GPIO.output(IN1, GPIO.HIGH)
	GPIO.output(IN2, GPIO.LOW)
	GPIO.output(IN3, GPIO.LOW)
	GPIO.output(IN4, GPIO.HIGH)

@webiopi.macro
def stop():
	PWMA.ChangeDutyCycle(0)
	PWMB.ChangeDutyCycle(0)
	GPIO.output(IN1, GPIO.LOW)
	GPIO.output(IN2, GPIO.LOW)
	GPIO.output(IN3, GPIO.LOW)
	GPIO.output(IN4, GPIO.LOW)
    
# Called by WebIOPi at script loading
def setup():
	# Setup GPIOs
	GPIO.setup(IN1, GPIO.OUT)
	GPIO.setup(IN2, GPIO.OUT)
	GPIO.setup(IN3, GPIO.OUT)
	GPIO.setup(IN4, GPIO.OUT)


# Called by WebIOPi at server shutdown
def destroy():
	# Reset GPIO functions

	GPIO.setup(IN1, GPIO.IN)
	GPIO.setup(IN2, GPIO.IN)
	GPIO.setup(IN3, GPIO.IN)
	GPIO.setup(IN4, GPIO.IN)
	GPIO.setup(ENA, GPIO.IN)
	GPIO.setup(ENB, GPIO.IN)
    
