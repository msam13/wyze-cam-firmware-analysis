#! /bin/sh

YELLOW_LED_PIN=38
BLUE_LED_PIN=39

LED_ON=0
LED_OFF=1

echo "# run $0 ..."

while [ 1 ]; do
	echo $LED_ON > "/sys/class/gpio/gpio$YELLOW_LED_PIN/value"
	echo $LED_ON > "/sys/class/gpio/gpio$BLUE_LED_PIN/value"
	sleep 1.6
	echo $LED_OFF > "/sys/class/gpio/gpio$YELLOW_LED_PIN/value"
	echo $LED_OFF > "/sys/class/gpio/gpio$BLUE_LED_PIN/value"
	sleep 0.14
done

echo "# stop $0 ..."
