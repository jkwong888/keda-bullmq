import { Queue, Worker } from 'bullmq';
import { Cluster } from 'ioredis';
import { JOB_RUN_TIME_SECS, REDIS_QUEUE_HOST, REDIS_QUEUE_PORT } from './config.js';
import { createLogger, transports, format } from 'winston';

const logger = createLogger({
  level: 'info',
  format: format.combine(
    format.timestamp({
      format: 'YYYY-MM-DD hh:mm:ss.SSS A', // 2022-01-25 03:23:10.350 PM
    }), 
    format.json(),
  ),
  transports: [new transports.Console()],
});

const redisConfiguration =  new Cluster([{
      host: REDIS_QUEUE_HOST,
      port: REDIS_QUEUE_PORT,
}]);

const workerConfiguration = {
  prefix: '{dataSchedule}',
  connection: redisConfiguration,
  autorun: false, // don't start immediately
  concurrency: 1, // only one run job at once in this worker
  removeOnComplete: { count: 5 },
  removeOnFail: {count: 5 },
}

async function addNoise(job) {
  logger.info(`processing job: ${job.id}, job data: ${JSON.stringify(job.data)} -- sleep for ${JOB_RUN_TIME_SECS} seconds`)
  await new Promise(r => setTimeout(r, JOB_RUN_TIME_SECS * 1000));
  const { data, noise } = job.data;
  logger.info(`adding ${noise} to ${data}.`);
  await job.updateData({realworlddata: data + noise}) ;
}

const worker = new Worker(
  'dataSchedule', 
  addNoise, 
  workerConfiguration,
);

logger.info("Worker started!");

worker.on('active', (job) => {
  logger.info(`Worker is active -- job ${job.id}`);
})

worker.on('completed', async job => {
  logger.info(`${job.id} has completed!`);
  worker.close();
});

worker.on('error',  err => {
  logger.error(`error: ${err}`);
});

worker.on('failed', async (job, err) => {
  logger.error(`${job.id} has failed with ${err.message}`);
  worker.close();
});

worker.on('closed', () => {
  // process exit
  process.exit(0);
})

worker.run();

// graceful shutdown on SIGTERM - wait for running jobs to complete
process.on('SIGTERM', async () => { 
  logger.info(`Received SIGTERM, waiting for job to complete before close`);
  await worker.close(); 
  process.exit(0);
});