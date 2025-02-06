#!/bin/bash

# Load configuration
source /etc/fan-control.conf

# Locate hwmon path for the nct6799 sensor
HWMON_PATH=$(grep -l "nct6799" /sys/class/hwmon/hwmon*/name | sed 's|/name||' | head -n 1)
if [ -z "$HWMON_PATH" ]; then
    echo "$(date) - Error: Cannot find nct6799 sensor" >&2
    exit 1
fi

# Enable manual PWM control
for i in 3 4 5 6 7; do
    echo 1 > "$HWMON_PATH/pwm${i}_enable"
done

# Extract CPU temperature correctly (CPUTIN)
CPU_TEMP=$(sensors | grep "CPUTIN" | sed -E 's/.*\+([0-9]+(\.[0-9])?)°C.*/\1/')
if [[ -z "$CPU_TEMP" ]]; then
    CPU_TEMP=40  # Fallback default
    echo "$(date) - Warning: CPU temperature sensor missing, using default: 40°C" >> /var/log/fan-control.log
fi

# Determine fan speed based on temperature
if [[ "$Override" -eq 1 ]]; then
    PWM_CASE="$ManualSpeed"
elif [ "${CPU_TEMP%.*}" -gt 50 ]; then
    PWM_CASE=150  # Increase fan speed at high temps
elif [ "${CPU_TEMP%.*}" -gt 40 ]; then
    PWM_CASE=100  # Moderate cooling for mid-range temps
else
    PWM_CASE=85   # Quiet mode at lower temps
fi

# Apply fan speeds
for i in 3 4 5 6; do
    echo $PWM_CASE > "$HWMON_PATH/pwm${i}"
done

# AIO Pump should always run at full speed
echo 150 > "$HWMON_PATH/pwm7"

# Log results correctly
echo "$(date) - CPU Temp: ${CPU_TEMP}°C | Case Fans: $PWM_CASE PWM | AIO Pump: 150 PWM" >> /var/log/fan-control.log
