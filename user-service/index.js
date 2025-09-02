import Fastify from 'fastify';
const app = Fastify();

app.get('/', async () => ({ ok: true }));

const port = process.env.PORT || 3000;
app.listen({ port, host: '0.0.0.0' })
  .then(() => {
    console.log(`🚀 User service is running on http://0.0.0.0:${port}`);
  })
  .catch(err => {
    app.log.error(err);
    process.exit(1);
  });
