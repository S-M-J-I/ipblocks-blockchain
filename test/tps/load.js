const fs = require('fs')
const BlockchainPerformanceAnalyzer = require('./perf')

class ConcurrentBlockchainPerformanceAnalyzer {
    constructor(web3Instances, contractInstances) {
        this.web3Instances = web3Instances
        this.contractInstances = contractInstances
        this.account = "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1"
    }

    async runConcurrentTests(testFunction, config) {
        const {
            numClients,
            iterationsPerClient,
            concurrencyMode
        } = config

        let baseNonce = BigInt(await this.web3Instances[0].eth.getTransactionCount(this.account))

        const allResults = []

        if (concurrencyMode === 'parallel') {
            const clientPromises = this.web3Instances.map(async (web3, clientIndex) => {
                return new Promise(async (resolve, reject) => {
                    try {
                        const performanceAnalyzer = new BlockchainPerformanceAnalyzer(
                            web3,
                            this.contractInstances
                        )

                        const clientResults = []
                        for (let i = 0; i < iterationsPerClient; i++) {
                            const nonce = baseNonce + BigInt(clientIndex * iterationsPerClient) + BigInt(i)

                            try {
                                const result = await performanceAnalyzer.measureTransactionTime(
                                    testFunction({
                                        from: this.account,
                                        nonce: Number(nonce)
                                    }),
                                    { iteration: i }
                                )

                                clientResults.push({
                                    ...result,
                                    clientId: clientIndex
                                })
                            } catch (iterationError) {
                                console.error(`Error in client ${clientIndex}, iteration ${i}:`, iterationError)
                                clientResults.push({
                                    error: iterationError.message,
                                    clientId: clientIndex,
                                    iteration: i
                                })
                            }
                        }

                        resolve(clientResults)
                    } catch (error) {
                        console.error(`Comprehensive error for client ${clientIndex}:`, error)
                        reject(error)
                    }
                })
            })

            try {
                const resultsByClient = await Promise.all(clientPromises)
                allResults.push(...resultsByClient.flat())
            } catch (error) {
                console.error('Fatal error in concurrent tests:', error)
                throw error
            }
        }

        return this.analyzeConcurrentResults(allResults)
    }

    analyzeConcurrentResults(results) {
        const clientGroups = results.reduce((acc, result) => {
            if (!acc[result.clientId]) {
                acc[result.clientId] = []
            }
            acc[result.clientId].push(result)
            return acc
        }, {})

        const summaryReport = {
            totalClients: Object.keys(clientGroups).length,
            totalTests: results.length,
            perClientSummary: Object.entries(clientGroups).map(([clientId, clientResults]) => ({
                clientId: Number(clientId),
                totalTests: clientResults.length,
                avgProcessingTime: clientResults.reduce((sum, r) => sum + r.processingTime, 0) / clientResults.length,
                minProcessingTime: Math.min(...clientResults.map(r => r.processingTime)),
                maxProcessingTime: Math.max(...clientResults.map(r => r.processingTime)),
            })),
        }

        summaryReport['overallAvgProcessingTime'] = summaryReport.perClientSummary.reduce((sum, item) => sum + item.avgProcessingTime, 0) / summaryReport.perClientSummary.length

        return summaryReport
    }

    generatePerformanceReport(results) {

        const report = {
            totalClients: results.totalClients,
            totalClientIterations: results.perClientSummary[0].totalTests,
            avgProcessingTime: results.overallAvgProcessingTime,
            minProcessingTime: Math.min(...results.perClientSummary.map(r => r.minProcessingTime)),
            maxProcessingTime: Math.max(...results.perClientSummary.map(r => r.maxProcessingTime)),
            results
        }

        // Save report to file
        fs.writeFileSync(`${__dirname}/performance_report_clients.json`, JSON.stringify(report, null, 2))

        return report
    }
}

module.exports = ConcurrentBlockchainPerformanceAnalyzer