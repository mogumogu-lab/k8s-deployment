import Fastify from 'fastify';

const app = Fastify({
  logger: true
});

const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || '1.0.0';
const SERVICE_NAME = 'user-service';

// Health check endpoint
app.get('/', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    message: `Hello from ${SERVICE_NAME} v${VERSION}!`
  };
});

// User endpoints
app.get('/users', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    users: [
      { id: 1, name: 'Alice', email: 'alice@example.com' },
      { id: 2, name: 'Bob', email: 'bob@example.com' },
      { id: 3, name: 'Charlie', email: 'charlie@example.com' }
    ]
  };
});

app.get('/users/:id', async (request, reply) => {
  const { id } = request.params;
  return {
    service: SERVICE_NAME,
    version: VERSION,
    user: {
      id: parseInt(id),
      name: `User ${id}`,
      email: `user${id}@example.com`,
      profile: VERSION === '2.0.0' ? { premium: true, tier: 'gold' } : { premium: false }
    }
  };
});

// Version-specific endpoint
app.get('/version', async (request, reply) => {
  return {
    service: SERVICE_NAME,
    version: VERSION,
    buildDate: new Date().toISOString(),
    features: VERSION === '1.0.0' ? ['basic-users'] : ['basic-users', 'user-profiles', 'premium-features']
  };
});

// Stats endpoint (v2 only feature simulation)
app.get('/stats', async (request, reply) => {
  if (VERSION === '1.0.0') {
    return {
      service: SERVICE_NAME,
      version: VERSION,
      error: 'Stats feature not available in v1.0.0'
    };
  }
  
  return {
    service: SERVICE_NAME,
    version: VERSION,
    stats: {
      totalUsers: 1250,
      activeUsers: 890,
      premiumUsers: 234,
      timestamp: new Date().toISOString()
    }
  };
});

app.listen({ port: PORT, host: '0.0.0.0' })
  .then(() => {
    console.log(`🚀 ${SERVICE_NAME} v${VERSION} is running on http://0.0.0.0:${PORT}`);
  })
  .catch(err => {
    app.log.error(err);
    process.exit(1);
  });
