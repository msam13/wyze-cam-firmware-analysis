#! /bin/sh

appNameMain=iCamera
appNameLight=assis

SPKER_POWER_OFF=0
SPKER_POWER_PIN=63

YELLOW_LED_PIN=38
BLUE_LED_PIN=39

LED_ON=0
LED_OFF=1

echo "[$0] start!"

appPidMain=`pgrep -f $appNameMain`
while [ $? -eq 0 ]; do
	sleep 2
	pgrep -f $appNameMain > /dev/null
done

#echo "[$0] turn off speaker power!"
#echo $SPKER_POWER_OFF > "/sys/class/gpio/gpio$SPKER_POWER_PIN/value"

echo "[$0] send sig to $appNameLight!"
appPidLight=`pgrep -f $appNameLight`
kill -SIGUSR1 $appPidLight

echo "[$0] shine the led!"
while [ 1 ]; do
#	echo $LED_ON  > "/sys/class/gpio/gpio$YELLOW_LED_PIN/value"
#	echo $LED_ON  > "/sys/class/gpio/gpio$BLUE_LED_PIN/value"
#	sleep 0.08
#	echo $LED_OFF > "/sys/class/gpio/gpio$YELLOW_LED_PIN/value"
#	echo $LED_OFF > "/sys/class/gpio/gpio$BLUE_LED_PIN/value"
#	sleep 0.08
	sleep 1
done

echo "[$0] exit!"
