export const REDIS_QUEUE_HOST = process.env.REDIS_QUEUE_HOST || 'localhost';
export const REDIS_QUEUE_PORT = process.env.REDIS_QUEUE_PORT
	? parseInt(process.env.REDIS_QUEUE_PORT)
	: 6479;
export const JOB_RUN_TIME_SECS = process.env.JOB_RUN_TIME_SECS 
	? parseInt(process.env.JOB_RUN_TIME_SECS)
	: 60;