pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
 */
Singleton {
	property double memoryTotal: 1
	property double memoryFree: 1
	property double memoryUsed: memoryTotal - memoryFree
    property double memoryUsedPercentage: memoryUsed / memoryTotal
    property double swapTotal: 1
	property double swapFree: 1
	property double swapUsed: swapTotal - swapFree
    property double swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property double cpuUsage: 0
    property var previousCpuStats

    property double gpuUsage: 0
    property double gpuMemUsage: 0

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileGpuUsage.reload()
            fileGpuMemUsagePercent.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            // Get GPU usage
            const gpuUsageStat = fileGpuUsage.text()
            gpuUsage = Number(gpuUsageStat/100)
            
            // Get GPU mem usage
            const gpuMemUsageStat = fileGpuMemUsagePercent.text()
            gpuMemUsage = Number(gpuMemUsageStat/100)

            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileGpuUsage; path: "/sys/class/drm/card1/device/gpu_busy_percent" }
    FileView { id: fileGpuMemUsagePercent; path: "/sys/class/drm/card1/device/mem_busy_percent" }
}
