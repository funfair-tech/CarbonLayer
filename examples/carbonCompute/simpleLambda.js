import * as crypto from 'crypto';

const computeHash = (inputString) => {
  const hash = crypto.createHash('sha256');
  hash.update(inputString);
  return hash.digest('hex');
};

export const handler = async (event) => {
  try {
    const startTime = Date.now();
    const region = process.env.AWS_REGION;
    const origin = event.headers['Origin'];
    const currentDate = new Date().toDateString();
    const hash = computeHash(currentDate);
    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`Request Origin: ${origin}, Hash of the current date "${currentDate}": ${hash}`);

    return {
      statusCode: 200,
      body: JSON.stringify({ name: "Offchain Compute Handler", origin: origin, region: region, duration: `${duration} ms`, result: hash }),
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal Server Error' }),
    };
  }
};

