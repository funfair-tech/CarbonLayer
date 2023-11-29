import * as GPU from 'gpu.js';

export const handler = async (event) => {
    const startTime = Date.now();

    // Simulate GPU-like rendering with gpu.js
    const gpu = new GPU();
    const renderKernel = gpu.createKernel(function() {
        // Simulate a GPU-intensive task
        let value = 0;
        for (let i = 0; i < 100000; i++) {
            value += Math.sin(i) * Math.cos(i);
        }
        return value;
    }).setOutput([1]);

    const result = renderKernel();

    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`Duration: ${duration} ms`);
    console.log(`GPU Simulation Result: ${result[0]}`);

    const response = {
        statusCode: 200,
        body: JSON.stringify({
            message: 'GPU rendering simulation completed!',
            duration: duration,
            result: result[0],
        }),
    };
    return response;
};