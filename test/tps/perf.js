const fs = require('fs')
const { performance } = require('perf_hooks')

class BlockchainPerformanceAnalyzer {
    constructor(web3, contractInstance) {
        this.web3 = web3
        this.contractInstance = contractInstance
    }

    async measureTransactionTime(transaction, metadata = {}) {
        const startTime = performance.now()

        try {
            const txResponse = await transaction
            const txReceipt = txResponse['receipt']

            // console.log(txResponse)

            const endTime = performance.now()
            const processingTime = endTime - startTime

            return {
                ...metadata,
                processingTime,
                blockNumber: txReceipt['blockNumber'],
                gasUsed: txReceipt['gasUsed'].toString(),
                status: txReceipt['status'] === true ? 'Success' : 'Failed'
            }
        } catch (error) {
            return {
                ...metadata,
                processingTime: null,
                error: error.message
            }
        }
    }

    async runPerformanceTest(testFunction, iterations = 10) {
        const results = []
        for (let i = 0; i < iterations; i++) {
            const result = await this.measureTransactionTime(
                testFunction(),
                { iteration: i }
            )
            results.push({ ...result, iteration: i })
        }

        return results
    }

    generatePerformanceReport(results) {
        const successResults = results.filter(r => r.status === 'Success')

        const report = {
            totalTests: results.length,
            successfulTests: successResults.length,
            avgProcessingTime: successResults.reduce((sum, r) => sum + r.processingTime, 0) / successResults.length,
            minProcessingTime: Math.min(...successResults.map(r => r.processingTime)),
            maxProcessingTime: Math.max(...successResults.map(r => r.processingTime)),
            results
        }

        // Save report to file
        fs.writeFileSync(`${__dirname}/performance_report.json`, JSON.stringify(report, null, 2))

        return report
    }
}

module.exports = BlockchainPerformanceAnalyzer