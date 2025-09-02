import Fastify from 'fastify'

const fastify = Fastify({
  logger: true
})

const PORT = process.env.PORT || 3000
const VERSION = process.env.VERSION || '1.0.0'
const SERVICE_NAME = 'payment-service'

// Health check endpoint
fastify.get('/', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    message: `Hello from ${SERVICE_NAME} v${VERSION}!`
  }
})

// Payment endpoints
fastify.get('/payments', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    payments: [
      { id: 1, amount: 100, status: 'completed' },
      { id: 2, amount: 250, status: 'pending' }
    ]
  }
})

fastify.post('/payments', async (request, reply) => {
  const payment = request.body
  return {
    service: SERVICE_NAME,
    version: VERSION,
    message: 'Payment created successfully',
    payment: {
      id: Math.floor(Math.random() * 1000),
      ...payment,
      status: 'pending'
    }
  }
})

// Version-specific endpoint
fastify.get('/version', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    buildDate: new Date().toISOString(),
    features: VERSION === '1.0.0' ? ['basic-payments'] : ['basic-payments', 'advanced-analytics']
  }
})

const start = async () => {
  try {
    await fastify.listen({ port: PORT, host: '0.0.0.0' })
    console.log(`${SERVICE_NAME} v${VERSION} is running on port ${PORT}`)
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}

start()