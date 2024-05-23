
import { Queue, Job } from 'bullmq';
import { Cluster } from 'ioredis';
import { REDIS_QUEUE_HOST, REDIS_QUEUE_PORT } from './config.js';

// Add your own configuration here
const redisConfiguration = {
  prefix: '{dataSchedule}',
  connection: new Cluster([{
    host: REDIS_QUEUE_HOST,
    port: REDIS_QUEUE_PORT,
  }]),
}

// const DEFAULT_REMOVE_CONFIG = {
// 	removeOnComplete: {
// 		age: 3600,
// 	},
// 	removeOnFail: {
// 		age: 24 * 3600,
// 	},
// };



const myQueue = new Queue('dataSchedule', redisConfiguration);

export async function dataSchedule(data, noise, delay) {
  return await myQueue.add('data', { data, noise },
    {
      attempts: 5,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
      removeOnComplete: {
        age: 3600, // keep up to 1 hour
        count: 5, // keep up to 1000 jobs
      },
      removeOnFail: {
        age: 24 * 3600, // keep up to 24 hours
      },
      delay: delay 
    },
  );
}

// emailSchedule("foo@bar.com", "Hello World!", 5000); // The email will be available for consumption after 5 seconds. 