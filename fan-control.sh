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

# Get CPU temperature
CPU_TEMP=$(sensors | grep "CPUTIN" | awk '{print $2}' | tr -d '+°C')
if [[ -z "$CPU_TEMP" ]] || [[ ! "$CPU_TEMP" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    CPU_TEMP=40
    echo "$(date) - Warning: Invalid temperature reading, using fallback" >> /var/log/fan-control.log
fi

# Determine fan speed based on temperature
if [[ "$Override" -eq 1 ]]; then
    PWM_CASE="$ManualSpeed"
elif [ "${CPU_TEMP%.*}" -gt 50 ]; then
    PWM_CASE=150  # High temp: faster fans
elif [ "${CPU_TEMP%.*}" -gt 40 ]; then
    PWM_CASE=85  # Medium temp: moderate speed
else
    PWM_CASE=55   # Low temp: quiet operation
fi

# Apply fan speeds
for i in 3 4 5 6; do
    echo $PWM_CASE > "$HWMON_PATH/pwm${i}"
done

# Keep AIO pump at consistent speed
echo 150 > "$HWMON_PATH/pwm7"

# Log status
echo "$(date) - CPU Temp: ${CPU_TEMP}°C | Case Fans: $PWM_CASE PWM | AIO Pump: 150 PWM" >> /var/log/fan-control.log
