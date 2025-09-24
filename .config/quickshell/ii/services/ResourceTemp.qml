pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource temp service with CPU temp and GPU temp.
 */
Singleton {
    property string cpuEdgeTemp: ""
    property string gpuEdgeTemp: ""

    Timer {
        interval: 1
        running: true 
        repeat: true
        onTriggered: {
            // Get CPU temp via sensors
            cpuTempProcess.running = true
            
            // Get GPU temp via file
            fileGpuEdgeTemp.reload()
            gpuEdgeTemp = (Number(fileGpuEdgeTemp.text())/1000).toFixed(1) + "°C"

            interval = Config.options?.resources?.updateInterval ?? 3000
        }
    }

    Process {
        id: cpuTempProcess
        running: false
        command: ["sh", "-c", "sensors k10temp-pci-00c3 | grep 'Tccd1' | awk '{print $2}' | sed 's/+//g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                cpuEdgeTemp = this.text.trim()
                running = false
            }
        }
    }

    FileView { 
        id: fileGpuEdgeTemp
        path: "/sys/class/drm/card0/device/hwmon/hwmon3/temp1_input" 
    }
}